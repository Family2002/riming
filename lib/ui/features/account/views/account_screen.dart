import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? scheme.error : null,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _submit(bool register) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = ref.read(authControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    if (register) {
      final outcome = await auth.signUp(
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      final err = ref.read(authControllerProvider).asError;
      if (err != null) {
        _showMessage(_friendlyAuthError(err.error), error: true);
        return;
      }
      if (outcome == null) {
        _showMessage('注册失败，请稍后重试', error: true);
        return;
      }
      // Always give visible feedback after register.
      if (outcome.needsEmailConfirmation) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('请确认邮箱'),
            content: const Text(
              '注册成功。请到邮箱查收确认邮件，点击链接完成验证后再登录。',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('知道了'),
              ),
            ],
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('注册成功'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    await auth.signIn(email: _email.text, password: _password.text);
    if (!mounted) return;
    final err = ref.read(authControllerProvider).asError;
    if (err != null) {
      _showMessage(_friendlyAuthError(err.error), error: true);
    }
  }

  String _friendlyAuthError(Object error) {
    if (error is AuthException) {
      final code = error.code?.toLowerCase() ?? '';
      final message = error.message.toLowerCase();
      if (code == 'email_not_confirmed' ||
          message.contains('email not confirmed')) {
        return '请先到邮箱确认账号';
      }
      if (code == 'invalid_credentials' ||
          message.contains('invalid login credentials')) {
        return '邮箱或密码不正确';
      }
      if (code == 'user_already_exists' ||
          message.contains('user already registered') ||
          message.contains('already been registered')) {
        return '该邮箱已注册，请直接登录';
      }
      if (code == 'weak_password' || message.contains('password')) {
        if (message.contains('weak') || message.contains('at least')) {
          return '密码不符合要求，请使用更强的密码';
        }
      }
    }

    final text = error.toString().toLowerCase();
    if (text.contains('email_not_confirmed') ||
        text.contains('email not confirmed')) {
      return '请先到邮箱确认账号';
    }
    if (text.contains('invalid login credentials')) {
      return '邮箱或密码不正确';
    }
    if (text.contains('user already registered') ||
        text.contains('already been registered')) {
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
              child: Text(
                '尚未配置云同步',
                style: Theme.of(context).textTheme.titleMedium,
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
