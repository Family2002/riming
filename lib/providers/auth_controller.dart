import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';

/// Outcome of [AuthController.signUp] for UI feedback.
class SignUpOutcome {
  const SignUpOutcome({
    required this.needsEmailConfirmation,
    required this.signedIn,
  });

  /// True when Supabase created/queued the user but did not return a session
  /// (typical when "Confirm email" is enabled).
  final bool needsEmailConfirmation;

  /// True when signup also established a session (confirm email off).
  final bool signedIn;
}

/// Email + password auth (best fit for Android MVP — no deep-link magic links).
class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController() : super(const AsyncData(null));

  SupabaseClient get _client {
    if (!SupabaseConfig.isConfigured) {
      throw StateError('Supabase 未配置');
    }
    return Supabase.instance.client;
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  /// Returns [SignUpOutcome] on success; leaves [state] as error on failure.
  Future<SignUpOutcome?> signUp({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      state = const AsyncData(null);

      final user = response.user;
      final session = response.session;
      // Duplicate signup often returns a user with empty identities.
      final identities = user?.identities;
      if (user != null && identities != null && identities.isEmpty) {
        throw const AuthApiException(
          'User already registered',
          statusCode: '400',
          code: 'user_already_exists',
        );
      }

      final signedIn = session != null;
      return SignUpOutcome(
        needsEmailConfirmation: !signedIn,
        signedIn: signedIn,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _client.auth.signOut();
    });
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController();
});
