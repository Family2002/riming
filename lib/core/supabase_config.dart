/// Supabase URL + anon/publishable key from `--dart-define` (or
/// `--dart-define-from-file`).
///
/// Example:
/// ```bash
/// flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJ...
/// ```
/// Or: `flutter run --dart-define-from-file=supabase.env.json`
class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// True when both URL and key were provided at compile/run time.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
