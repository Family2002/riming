import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../../domain/models/activity.dart';
import '../repositories/activity_repository.dart';

/// Pull-then-push sync with last-write-wins on [Activity.updatedAt].
///
/// Ensures at most one ongoing (`end_at` null, not deleted) activity per user
/// locally before push (matches partial unique index on Supabase).
class ActivitySyncService {
  ActivitySyncService(this._repo);

  final ActivityRepository _repo;

  Future<SyncResult>? _inFlight;
  var _queued = false;

  /// Coalesces overlapping requests; runs pull → enforce one ongoing → push.
  Future<SyncResult> schedule() {
    if (!SupabaseConfig.isConfigured) {
      return Future.value(SyncResult.skipped('未配置 Supabase'));
    }
    if (Supabase.instance.client.auth.currentSession == null) {
      return Future.value(SyncResult.skipped('未登录'));
    }

    if (_inFlight != null) {
      _queued = true;
      return _inFlight!;
    }

    final runner = Completer<SyncResult>();
    _inFlight = runner.future;

    () async {
      try {
        SyncResult last = SyncResult.ok();
        do {
          _queued = false;
          last = await _syncOnce().timeout(
            const Duration(seconds: 60),
            onTimeout: () => SyncResult.failed('同步超时，请稍后重试'),
          );
        } while (_queued);
        if (!runner.isCompleted) runner.complete(last);
      } catch (e) {
        if (!runner.isCompleted) {
          runner.complete(SyncResult.failed(e.toString()));
        }
      } finally {
        _inFlight = null;
        // A caller may have set _queued after the loop exited but before
        // _inFlight was cleared; schedule a follow-up pass.
        if (_queued) {
          _queued = false;
          unawaited(schedule());
        }
      }
    }();

    return runner.future;
  }

  Future<SyncResult> _syncOnce() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      return SyncResult.skipped('未登录');
    }

    try {
      await _pull(client, user.id);
      await _repo.enforceSingleOngoing();
      await _push(client, user.id);
      return SyncResult.ok();
    } catch (e) {
      return SyncResult.failed(_friendlyError(e));
    }
  }

  static String _friendlyError(Object e) {
    final text = e.toString();
    if (text.contains('activities_one_ongoing_per_user') ||
        text.contains('duplicate key')) {
      return '同步冲突：存在多条进行中事项，请再试一次';
    }
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('ClientException')) {
      return '网络不可用，请检查连接后重试';
    }
    return text;
  }

  Future<void> _pull(SupabaseClient client, String userId) async {
    final response = await client.from('activities').select().eq('user_id', userId);
    final rows = _asMapList(response);

    final locals = await _repo.getAllIncludingDeleted();
    final localById = {for (final a in locals) a.id: a};

    for (final map in rows) {
      final remote = _fromRemote(map);
      final local = localById[remote.id];
      if (local == null || _remoteWins(remote, local)) {
        await _repo.upsertFromSync(remote);
      }
    }
  }

  Future<void> _push(SupabaseClient client, String userId) async {
    final locals = await _repo.getAllIncludingDeleted();
    if (locals.isEmpty) return;

    final response = await client
        .from('activities')
        .select('id, updated_at')
        .eq('user_id', userId);
    final remoteRows = _asMapList(response);

    final remoteUpdated = <String, DateTime>{};
    for (final map in remoteRows) {
      remoteUpdated[map['id'] as String] =
          DateTime.parse(map['updated_at'] as String).toUtc();
    }

    final payload = <Map<String, dynamic>>[];
    for (final local in locals) {
      final remoteAt = remoteUpdated[local.id];
      final localAt = local.updatedAt.toUtc();
      if (remoteAt != null && !localAt.isAfter(remoteAt)) {
        continue;
      }
      payload.add(_toRemote(local, userId));
    }

    if (payload.isEmpty) return;

    // Ended/deleted first, then ongoing — avoids unique-index violations mid-batch.
    payload.sort((a, b) {
      final aOngoing = a['end_at'] == null && a['deleted_at'] == null;
      final bOngoing = b['end_at'] == null && b['deleted_at'] == null;
      if (aOngoing == bOngoing) return 0;
      return aOngoing ? 1 : -1;
    });

    const chunk = 100;
    for (var i = 0; i < payload.length; i += chunk) {
      final end = (i + chunk < payload.length) ? i + chunk : payload.length;
      try {
        await client.from('activities').upsert(
              payload.sublist(i, end),
              onConflict: 'id',
            );
      } catch (e) {
        // Unique ongoing index: resolve locally and retry once.
        if (e.toString().contains('activities_one_ongoing_per_user') ||
            e.toString().contains('duplicate key')) {
          await _repo.enforceSingleOngoing();
          final retry = <Map<String, dynamic>>[];
          for (final local in await _repo.getAllIncludingDeleted()) {
            final remoteAt = remoteUpdated[local.id];
            if (remoteAt != null &&
                !local.updatedAt.toUtc().isAfter(remoteAt)) {
              continue;
            }
            retry.add(_toRemote(local, userId));
          }
          retry.sort((a, b) {
            final aOngoing = a['end_at'] == null && a['deleted_at'] == null;
            final bOngoing = b['end_at'] == null && b['deleted_at'] == null;
            if (aOngoing == bOngoing) return 0;
            return aOngoing ? 1 : -1;
          });
          if (retry.isNotEmpty) {
            await client.from('activities').upsert(retry, onConflict: 'id');
          }
          return;
        }
        rethrow;
      }
    }
  }

  static List<Map<String, dynamic>> _asMapList(dynamic response) {
    if (response is! List) return const [];
    return response
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
  }

  /// Compare using UTC instants to avoid local/UTC storage skew.
  static bool _remoteWins(Activity remote, Activity local) {
    final r = remote.updatedAt.toUtc();
    final l = local.updatedAt.toUtc();
    if (r.isAfter(l)) return true;
    if (r.isBefore(l)) return false;
    return _remotePreferredOnTie(remote, local);
  }

  static Activity _fromRemote(Map<String, dynamic> map) {
    // Persist as local wall times so UI clocks match DateTime.now()-created rows.
    // LWW compares still use toUtc() via [_remoteWins].
    return Activity(
      id: map['id'] as String,
      title: map['title'] as String,
      startAt: DateTime.parse(map['start_at'] as String).toLocal(),
      endAt: map['end_at'] == null
          ? null
          : DateTime.parse(map['end_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
      deletedAt: map['deleted_at'] == null
          ? null
          : DateTime.parse(map['deleted_at'] as String).toLocal(),
    );
  }

  static Map<String, dynamic> _toRemote(Activity a, String userId) {
    return {
      'id': a.id,
      'user_id': userId,
      'title': a.title,
      'start_at': a.startAt.toUtc().toIso8601String(),
      'end_at': a.endAt?.toUtc().toIso8601String(),
      'updated_at': a.updatedAt.toUtc().toIso8601String(),
      'deleted_at': a.deletedAt?.toUtc().toIso8601String(),
    };
  }

  static bool _remotePreferredOnTie(Activity remote, Activity local) {
    if (remote.deletedAt != null && local.deletedAt == null) return true;
    if (remote.endAt != null && local.endAt == null) return true;
    return false;
  }
}

class SyncResult {
  const SyncResult._({
    required this.ok,
    required this.skipped,
    this.message,
  });

  factory SyncResult.ok() => const SyncResult._(ok: true, skipped: false);
  factory SyncResult.skipped(String message) =>
      SyncResult._(ok: false, skipped: true, message: message);
  factory SyncResult.failed(String message) =>
      SyncResult._(ok: false, skipped: false, message: message);

  final bool ok;
  final bool skipped;
  final String? message;
}
