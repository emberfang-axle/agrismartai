class AppConfig {
  AppConfig._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://emkxowyophtggfrjqjum.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVta3hvd3lvcGh0Z2dmcmpxanVtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2NzYyOTYsImV4cCI6MjA5NzI1MjI5Nn0.C_ti01Xs8LyI-1qjmci9rSHsYHHGqaJQ1qq4GNkqYCQ',
  );

  static void validate() {
    if (supabaseUrl.isEmpty || !supabaseUrl.startsWith('https://')) {
      throw Exception('Invalid SUPABASE_URL');
    }
    if (supabaseAnonKey.startsWith('sb_publishable_')) {
      throw Exception(
        'Use JWT anon key (eyJ...) from Supabase Dashboard → Settings → API, not sb_publishable_*.',
      );
    }
  }
}
