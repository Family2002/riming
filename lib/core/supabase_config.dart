/// Cloud sync backend URL + publishable/anon key from `--dart-define`
/// (or `--dart-define-from-file`). See `.env.example` / `supabase.env.json.example`.
class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// True when both URL and key were provided at compile/run time.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
