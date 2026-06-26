/// Admin dashboard compile-time configuration.
class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );

  static bool get isSupabaseConfigured {
    final urlOk = supabaseUrl.contains('.supabase.co') &&
        !supabaseUrl.contains('YOUR_PROJECT') &&
        !supabaseUrl.contains('supabase.com/dashboard');
    final keyOk = supabaseAnonKey.isNotEmpty &&
        !supabaseAnonKey.contains('YOUR_SUPABASE') &&
        supabaseAnonKey.startsWith('eyJ');
    return urlOk && keyOk;
  }
}
