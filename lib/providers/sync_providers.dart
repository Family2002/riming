import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../data/repositories/activity_repository.dart';
import '../data/sync/activity_sync_service.dart';
import '../providers.dart';
import '../ui/core/theme/theme_preferences.dart';

const _lastSyncAtKey = 'sync_last_at_ms';
const _lastSyncMsgKey = 'sync_last_message';
const _lastSyncOkKey = 'sync_last_ok';
const _ownerUserIdKey = 'sync_owner_user_id';

enum SyncPhase { idle, syncing }

class SyncStatus {
  const SyncStatus({
    required this.phase,
    this.lastAt,
    this.lastOk,
    this.lastMessage,
  });

  final SyncPhase phase;
  final DateTime? lastAt;
  final bool? lastOk;
  final String? lastMessage;

  bool get isSyncing => phase == SyncPhase.syncing;

  SyncStatus copyWith({
    SyncPhase? phase,
    DateTime? lastAt,
    bool? lastOk,
    String? lastMessage,
    bool clearMessage = false,
  }) {
    return SyncStatus(
      phase: phase ?? this.phase,
      lastAt: lastAt ?? this.lastAt,
      lastOk: lastOk ?? this.lastOk,
      lastMessage: clearMessage ? null : (lastMessage ?? this.lastMessage),
    );
  }
}

final activitySyncServiceProvider = Provider<ActivitySyncService>((ref) {
  return ActivitySyncService(ref.watch(activityRepositoryProvider));
});

final authSessionProvider = StreamProvider<Session?>((ref) async* {
  if (!SupabaseConfig.isConfigured) {
    yield null;
    return;
  }
  final client = Supabase.instance.client;
  yield client.auth.currentSession;
  await for (final data in client.auth.onAuthStateChange) {
    yield data.session;
  }
});

final authUserProvider = Provider<User?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  final asyncSession = ref.watch(authSessionProvider);
  return asyncSession.valueOrNull?.user ??
      Supabase.instance.client.auth.currentUser;
});

class SyncController extends StateNotifier<SyncStatus> {
  SyncController(this._ref, SharedPreferences prefs) : super(_load(prefs)) {
    _prefs = prefs;
    _repo = _ref.read(activityRepositoryProvider);
    _repo.onLocalWrite = () {
      unawaited(syncAfterWrite());
    };
    _authSub = _ref.listen(authSessionProvider, (prev, next) {
      final prevUser = prev?.valueOrNull?.user.id;
      final nextUser = next.valueOrNull?.user.id;
      if (nextUser != null && nextUser != prevUser) {
        unawaited(syncNow(reason: 'auth'));
      }
    });
    if (_ref.read(authUserProvider) != null) {
      Future.microtask(() => syncNow(reason: 'cold_start'));
    }
  }

  final Ref _ref;
  late final SharedPreferences _prefs;
  late final ActivityRepository _repo;
  ProviderSubscription<AsyncValue<Session?>>? _authSub;
  Timer? _debounce;
  Future<void>? _gate;
  var _rerun = false;

  static SyncStatus _load(SharedPreferences prefs) {
    final ms = prefs.getInt(_lastSyncAtKey);
    return SyncStatus(
      phase: SyncPhase.idle,
      lastAt: ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms),
      lastOk: prefs.getBool(_lastSyncOkKey),
      lastMessage: prefs.getString(_lastSyncMsgKey),
    );
  }

  Future<void> syncAfterWrite() async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      unawaited(syncNow(reason: 'local_write'));
    });
  }

  Future<void> syncOnResume() => syncNow(reason: 'resume');

  /// Ensures local rows never push under the wrong auth user.
  ///
  /// - First claim (no owner): keep offline data and upload for this user.
  /// - Same owner: normal sync.
  /// - Different owner: wipe local DB then pull (prevents cross-account merge).
  Future<void> _prepareOwner(String userId) async {
    final owner = _prefs.getString(_ownerUserIdKey);
    if (owner == null) {
      await _prefs.setString(_ownerUserIdKey, userId);
      return;
    }
    if (owner == userId) return;

    await _repo.clearAllLocal();
    await _prefs.setString(_ownerUserIdKey, userId);
    _ref.invalidate(historyDaysProvider);
    state = state.copyWith(
      lastMessage: '已切换账号，本地记录已清空并重新同步',
    );
  }

  Future<void> syncNow({String reason = 'manual'}) async {
    // Serialize syncs; if one is in flight, request a follow-up pass
    // (covers login-during-sync / account switch).
    if (_gate != null) {
      _rerun = true;
      await _gate;
      return;
    }

    final done = Completer<void>();
    _gate = done.future;
    try {
      do {
        _rerun = false;
        await _runSync();
      } while (_rerun);
    } finally {
      done.complete();
      _gate = null;
    }
  }

  Future<void> _runSync() async {
    if (!SupabaseConfig.isConfigured) {
      state = state.copyWith(
        phase: SyncPhase.idle,
        lastOk: false,
        lastMessage: '未配置云同步（缺少 SUPABASE_URL / SUPABASE_ANON_KEY）',
        lastAt: DateTime.now(),
      );
      await _persist();
      return;
    }

    final user = _ref.read(authUserProvider) ??
        (SupabaseConfig.isConfigured
            ? Supabase.instance.client.auth.currentUser
            : null);
    if (user == null) {
      return;
    }

    state = state.copyWith(phase: SyncPhase.syncing, clearMessage: true);

    try {
      await _prepareOwner(user.id);
      final result = await _ref.read(activitySyncServiceProvider).schedule();

      final message = result.ok
          ? '同步成功'
          : (result.message ?? (result.skipped ? '已跳过' : '同步失败'));

      state = state.copyWith(
        phase: SyncPhase.idle,
        lastAt: DateTime.now(),
        lastOk: result.ok,
        lastMessage: message,
      );
    } catch (e) {
      state = state.copyWith(
        phase: SyncPhase.idle,
        lastAt: DateTime.now(),
        lastOk: false,
        lastMessage: '同步失败：$e',
      );
    }
    await _persist();
  }

  Future<void> _persist() async {
    final at = state.lastAt;
    if (at != null) {
      await _prefs.setInt(_lastSyncAtKey, at.millisecondsSinceEpoch);
    }
    if (state.lastOk != null) {
      await _prefs.setBool(_lastSyncOkKey, state.lastOk!);
    }
    if (state.lastMessage != null) {
      await _prefs.setString(_lastSyncMsgKey, state.lastMessage!);
    } else {
      await _prefs.remove(_lastSyncMsgKey);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _authSub?.close();
    _repo.onLocalWrite = null;
    super.dispose();
  }
}

final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncStatus>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SyncController(ref, prefs);
});

/// Syncs when the app returns to foreground (if signed in).
class SyncLifecycleBinding extends ConsumerStatefulWidget {
  const SyncLifecycleBinding({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SyncLifecycleBinding> createState() =>
      _SyncLifecycleBindingState();
}

class _SyncLifecycleBindingState extends ConsumerState<SyncLifecycleBinding>
    with WidgetsBindingObserver {
  var _sawPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncControllerProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Ignore the initial resume; only sync after a real background → foreground.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      _sawPaused = true;
      return;
    }
    if (state == AppLifecycleState.resumed && _sawPaused) {
      _sawPaused = false;
      unawaited(ref.read(syncControllerProvider.notifier).syncOnResume());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
