/// Supabase + API configuration for AgriSmartAI.
class AppConfig {
  AppConfig._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://emkxowyophtggfrjqjum.supabase.co',
  );

  /// Use the JWT anon key from Supabase Dashboard → Settings → API.
  /// Do NOT use sb_publishable_* keys here — supabase_flutter needs the JWT.
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVta3hvd3lvcGh0Z2dmcmpxanVtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2NzYyOTYsImV4cCI6MjA5NzI1MjI5Nn0.C_ti01Xs8LyI-1qjmci9rSHsYHHGqaJQ1qq4GNkqYCQ',
  );

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const deepSeekApiKey = String.fromEnvironment(
    'DEEPSEEK_API_KEY',
    defaultValue: '',
  );

  static const deepSeekApiUrl = 'https://api.deepseek.com/chat/completions';
  static const deepSeekModel = 'deepseek-chat';

  /// Throws with a clear message if config is invalid (prevents white screen).
  static void validate() {
    if (supabaseUrl.isEmpty || !supabaseUrl.startsWith('https://')) {
      throw Exception(
        'Invalid SUPABASE_URL: "$supabaseUrl". '
        'Set it in lib/core/config.dart or pass --dart-define=SUPABASE_URL=...',
      );
    }
    if (supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY is empty.');
    }
    if (supabaseAnonKey.startsWith('sb_publishable_')) {
      throw Exception(
        'Wrong key type: sb_publishable_* will NOT work.\n'
        'Go to Supabase Dashboard → Settings → API → copy the "anon public" JWT key '
        '(starts with eyJ...) and paste it in lib/core/config.dart.',
      );
    }
    if (!supabaseAnonKey.startsWith('eyJ')) {
      throw Exception(
        'SUPABASE_ANON_KEY must be the JWT anon key (starts with eyJ...). '
        'Get it from Supabase Dashboard → Settings → API.',
      );
    }
  }
}
