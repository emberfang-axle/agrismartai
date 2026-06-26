import 'package:http/http.dart' as http;

import '../utils/constants.dart';

/// Tracks whether the Python backend is reachable (cached to avoid spam).
class BackendAvailability {
  BackendAvailability._();

  static bool? _online;
  static DateTime? _checkedAt;
  static const _cacheFor = Duration(minutes: 2);

  /// Web demo without Python/backend — skip network calls entirely.
  static bool get forceOffline => AppConfig.forceOfflineDemo;

  static bool get isKnownOffline => forceOffline || _online == false;

  static Future<bool> isOnline({bool refresh = false}) async {
    if (forceOffline) {
      _online = false;
      return false;
    }

    if (!refresh &&
        _online != null &&
        _checkedAt != null &&
        DateTime.now().difference(_checkedAt!) < _cacheFor) {
      return _online!;
    }

    try {
      final r = await http
          .get(Uri.parse('${AppConfig.apiBaseUrl}/api/health'))
          .timeout(const Duration(seconds: 2));
      _online = r.statusCode == 200;
    } catch (_) {
      _online = false;
    }
    _checkedAt = DateTime.now();
    return _online!;
  }

  static void markOffline() {
    _online = false;
    _checkedAt = DateTime.now();
  }
}
