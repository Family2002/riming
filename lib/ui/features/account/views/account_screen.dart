import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/supabase_config.dart';
import '../../../../providers/auth_controller.dart';
import '../../../../providers/sync_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/riming_atmosphere.dart';
import '../../../core/widgets/riming_surface_card.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(bool register) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = ref.read(authControllerProvider.notifier);
    if (register) {
      await auth.signUp(email: _email.text, password: _password.text);
    } else {
      await auth.signIn(email: _email.text, password: _password.text);
    }
    if (!mounted) return;
    final err = ref.read(authControllerProvider).asError;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyAuthError(err.error))),
      );
    } else if (register) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('注册已提交。若开启了邮箱确认，请先查收邮件后再登录。'),
        ),
      );
    }
  }

  String _friendlyAuthError(Object error) {
    final text = error.toString();
    if (text.contains('Invalid login credentials')) {
      return '邮箱或密码不正确';
    }
    if (text.contains('Email not confirmed')) {
      return '请先确认邮箱后再登录';
    }
    if (text.contains('User already registered')) {
      return '该邮箱已注册，请直接登录';
    }
    return '操作失败：$error';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authUserProvider);
    final sync = ref.watch(syncControllerProvider);
    final authBusy = ref.watch(authControllerProvider).isLoading;
    final configured = SupabaseConfig.isConfigured;

    return GlassScaffold(
      background: const RimingAtmosphere(),
      backgroundColor: scheme.surface,
      extendBody: false,
      edgeFade: false,
      contentAwareBrightness: false,
      statusBarStyle: GlassStatusBarStyle.auto,
      appBar: GlassAppBar(
        title: Text('账号与同步', style: Theme.of(context).textTheme.titleLarge),
        leading: IconButton(
          tooltip: '返回',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(CupertinoIcons.back, color: scheme.onSurface),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          if (!configured) ...[
            RimingSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '尚未配置云同步',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '请在运行时传入 SUPABASE_URL 与 SUPABASE_ANON_KEY'
                    '（见 README / .env.example）。建议项目区域选东京。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text('账号', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          if (user != null)
            _SignedInCard(
              email: user.email ?? user.id,
              sync: sync,
              busy: authBusy || sync.isSyncing,
              onSync: () =>
                  ref.read(syncControllerProvider.notifier).syncNow(),
              onSignOut: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
            )
          else
            _SignInForm(
              formKey: _formKey,
              email: _email,
              password: _password,
              obscure: _obscure,
              busy: authBusy || !configured,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              onSignIn: () => _submit(false),
              onSignUp: () => _submit(true),
            ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '说明',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '使用邮箱 + 密码登录（适合 Android，无需配置深链）。'
            '登录后、回到前台、以及本地写入后会自动同步；冲突以更新时间较新的为准。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _SignedInCard extends StatelessWidget {
  const _SignedInCard({
    required this.email,
    required this.sync,
    required this.busy,
    required this.onSync,
    required this.onSignOut,
  });

  final String email;
  final SyncStatus sync;
  final bool busy;
  final VoidCallback onSync;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timeLabel = sync.lastAt == null
        ? '尚未同步'
        : DateFormat('M月d日 HH:mm', 'zh_CN').format(sync.lastAt!);
    final statusColor = sync.lastOk == null
        ? scheme.outline
        : (sync.lastOk! ? scheme.primary : scheme.error);

    return RimingSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.person_crop_circle, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  email,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '上次同步：$timeLabel',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (sync.lastMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              sync.lastMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusColor,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: busy ? null : onSync,
            icon: sync.isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(CupertinoIcons.arrow_2_circlepath),
            label: Text(sync.isSyncing ? '同步中…' : '立即同步'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: busy ? null : onSignOut,
            child: const Text('退出登录'),
          ),
        ],
      ),
    );
  }
}

class _SignInForm extends StatelessWidget {
  const _SignInForm({
    required this.formKey,
    required this.email,
    required this.password,
    required this.obscure,
    required this.busy,
    required this.onToggleObscure,
    required this.onSignIn,
    required this.onSignUp,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool obscure;
  final bool busy;
  final VoidCallback onToggleObscure;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    return RimingSurfaceCard(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: '邮箱',
                prefixIcon: Icon(CupertinoIcons.mail),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty || !t.contains('@')) return '请输入有效邮箱';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: password,
              obscureText: obscure,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: '密码',
                prefixIcon: const Icon(CupertinoIcons.lock),
                suffixIcon: IconButton(
                  onPressed: onToggleObscure,
                  icon: Icon(
                    obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                  ),
                ),
              ),
              validator: (v) {
                if ((v ?? '').length < 6) return '密码至少 6 位';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: busy ? null : onSignIn,
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('登录'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: busy ? null : onSignUp,
              child: const Text('注册'),
            ),
          ],
        ),
      ),
    );
  }
}
