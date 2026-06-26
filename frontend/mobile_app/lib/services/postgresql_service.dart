import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'backend_availability.dart';

/// PostgreSQL data access via Python backend (Flutter never connects to PG directly).
class PostgreSQLService {
  PostgreSQLService._();
  static final PostgreSQLService instance = PostgreSQLService._();

  static const _sessionKey = 'agrismart_user_session';

  final String baseUrl = AppConfig.apiBaseUrl;
  UserModel? _cachedUser;
  final List<ScanModel> _demoScans = [];

  bool get isOnline => _backendOk;
  bool _backendOk = false;

  /// Probe backend + PostgreSQL on startup.
  static Future<bool> checkConnection() async {
    if (BackendAvailability.forceOffline) {
      instance._backendOk = false;
      return false;
    }
    try {
      final svc = PostgreSQLService.instance;
      final r = await http
          .get(Uri.parse('${svc.baseUrl}/api/health'))
          .timeout(const Duration(seconds: 4));
      if (r.statusCode != 200) return false;
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      svc._backendOk = body['postgresql_enabled'] == true;
      return svc._backendOk || r.statusCode == 200;
    } catch (_) {
      BackendAvailability.markOffline();
      PostgreSQLService.instance._backendOk = false;
      return false;
    }
  }

  Future<void> init() async {
    await checkConnection();
    _cachedUser = await _loadSession();
  }

  Future<UserModel?> currentUser() async {
    if (_cachedUser != null) return _cachedUser;
    return _loadSession();
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    if (_backendOk) {
      try {
        final r = await http
            .post(
              Uri.parse('$baseUrl/api/auth/login'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'email': email, 'password': password}),
            )
            .timeout(const Duration(seconds: 8));
        if (r.statusCode == 200) {
          final user = UserModel.fromMap(
            jsonDecode(r.body) as Map<String, dynamic>,
          );
          await _saveSession(user);
          _cachedUser = user;
          return user;
        }
        final err = jsonDecode(r.body);
        throw Exception(err['detail']?.toString() ?? 'Invalid email or password.');
      } catch (e) {
        if (e is Exception) rethrow;
      }
    }

    // Offline demo fallback for capstone defense.
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
    final user = UserModel(
      id: 'demo-${email.hashCode}',
      fullName: email.split('@').first,
      email: email,
      barangay: 'New Bataan',
    );
    await _saveSession(user);
    _cachedUser = user;
    return user;
  }

  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String password,
    String barangay = 'New Bataan',
    String? phone,
  }) async {
    if (_backendOk) {
      final r = await http
          .post(
            Uri.parse('$baseUrl/api/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': fullName,
              'email': email,
              'password': password,
              'barangay': barangay,
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final user = UserModel.fromMap(
          jsonDecode(r.body) as Map<String, dynamic>,
        );
        await _saveSession(user);
        _cachedUser = user;
        return user;
      }
      final err = jsonDecode(r.body);
      throw Exception(err['detail']?.toString() ?? 'Registration failed.');
    }

    final user = UserModel(
      id: 'demo-${email.hashCode}',
      fullName: fullName,
      email: email,
      phone: phone,
      barangay: barangay,
    );
    await _saveSession(user);
    _cachedUser = user;
    return user;
  }

  Future<void> signOut() async {
    _cachedUser = null;
    _demoScans.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<void> updateProfile(UserModel user) async {
    _cachedUser = user;
    await _saveSession(user);
  }

  Future<ScanModel> saveScan({
    required UserModel user,
    required DetectionResult result,
    String? imagePath,
    List<int>? imageBytes,
    double? latitude,
    double? longitude,
  }) async {
    final local = ScanModel(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      userId: user.id,
      diseaseCode: result.diseaseCode,
      diseaseName: result.diseaseName,
      confidence: result.confidence,
      modelVersion: result.modelVersion,
      isRiceLeaf: result.isRiceLeaf,
      imagePath: imagePath,
      barangay: user.barangay,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
    );

    if (_backendOk && !user.id.startsWith('demo-')) {
      try {
        final r = await http
            .post(
              Uri.parse('$baseUrl/api/reports'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'user_id': user.id,
                'disease_code': result.diseaseCode,
                'disease_label': result.diseaseName,
                'confidence_score': result.confidence,
                'barangay': user.barangay,
                'location': latitude != null && longitude != null
                    ? '$latitude,$longitude'
                    : null,
              }),
            )
            .timeout(const Duration(seconds: 8));
        if (r.statusCode == 200) {
          final body = jsonDecode(r.body) as Map<String, dynamic>;
          return ScanModel.fromMap(body);
        }
      } catch (_) {}
    }

    _demoScans.insert(0, local);
    return local;
  }

  Future<List<ScanModel>> fetchScans(String userId) async {
    if (_backendOk && !userId.startsWith('demo-')) {
      try {
        final r = await http
            .get(Uri.parse('$baseUrl/api/reports?user_id=$userId'))
            .timeout(const Duration(seconds: 8));
        if (r.statusCode == 200) {
          final list = jsonDecode(r.body) as List<dynamic>;
          return list
              .map((e) => ScanModel.fromMap(e as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }
    return List.unmodifiable(_demoScans);
  }

  Future<void> deleteScan(String userId, String scanId) async {
    if (userId.startsWith('demo-') || scanId.startsWith('local-')) {
      _demoScans.removeWhere((s) => s.id == scanId);
      return;
    }
    if (_backendOk) {
      await http.delete(
        Uri.parse('$baseUrl/api/reports/$scanId?user_id=$userId'),
      );
    }
  }

  Future<void> clearAllScans(String userId) async {
    if (userId.startsWith('demo-')) {
      _demoScans.clear();
      return;
    }
    final scans = await fetchScans(userId);
    for (final s in scans) {
      await deleteScan(userId, s.id);
    }
  }

  Future<void> deleteAccount(String userId) async {
    await clearAllScans(userId);
    await signOut();
  }

  Future<void> resetPassword(String email) async {
    throw Exception('Contact DA New Bataan to reset your password.');
  }

  Future<void> saveEvaluation({
    required String userId,
    required int rating,
    String? comment,
    String? scanId,
  }) async {
    if (!_backendOk || userId.startsWith('demo-')) return;
    try {
      await http.post(
        Uri.parse('$baseUrl/api/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'rating': rating,
          'comment': comment,
        }),
      );
    } catch (_) {}
  }

  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(user.toMap()));
  }

  Future<UserModel?> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null) return null;
    try {
      return UserModel.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
