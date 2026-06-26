import 'package:flutter/foundation.dart';

/// Admin dashboard — talks to Python backend (PostgreSQL via REST).
class AppConfig {
  AppConfig._();

  static const String _apiFromEnv = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_apiFromEnv.isNotEmpty) return _apiFromEnv;
    if (kIsWeb) return 'http://localhost:8000';
    return 'http://10.0.2.2:8000';
  }
}
