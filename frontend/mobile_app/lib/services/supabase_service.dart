import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/scan_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// Supabase (Auth + DB + Storage) with offline demo fallback.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static bool _initialized = false;

  bool get isConfigured => AppConfig.isSupabaseConfigured;

  SupabaseClient? get _client =>
      isConfigured && _initialized ? Supabase.instance.client : null;

  UserModel? _demoUser;
  final List<ScanModel> _demoScans = [];

  /// Safe init — never blocks app startup indefinitely.
  static Future<void> init() async {
    if (!AppConfig.isSupabaseConfigured || _initialized) return;
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: AppConfig.supabaseAnonKey,
      ).timeout(const Duration(seconds: 3));
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  /// Lightweight connectivity probe for splash screen.
  static Future<bool> checkConnection() async {
    if (!AppConfig.isSupabaseConfigured) return true;
    try {
      await init();
      if (!_initialized) return false;
      await Supabase.instance.client
          .from('diseases')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 4));
      return true;
    } catch (_) {
      return false;
    }
  }

  UserModel _demoSignIn(String email) {
    _demoUser = UserModel(
      id: 'demo-${email.hashCode}',
      fullName: email.split('@').first,
      email: email,
    );
    return _demoUser!;
  }

  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String password,
    String barangay = 'New Bataan',
    String? phone,
  }) async {
    // Supabase not configured → offline demo mode only.
    if (!_initialized) {
      _demoUser = UserModel(
        id: 'demo-${email.hashCode}',
        fullName: fullName,
        email: email,
        phone: phone,
        barangay: barangay,
      );
      return _demoUser!;
    }

    final res = await _client!.auth
        .signUp(
          email: email,
          password: password,
          data: {'full_name': fullName, 'role': 'farmer'},
        )
        .timeout(const Duration(seconds: 8));
    final user = res.user;
    if (user == null) {
      throw const AuthException('Sign up failed. Please try again.');
    }
    await _client!.from('profiles').upsert({
      'id': user.id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'barangay': barangay,
      'role': 'farmer',
    }).timeout(const Duration(seconds: 6));
    await _logActivity(user.id, 'user_registered');
    return _profileFor(user.id, fallbackName: fullName, email: email);
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    // Supabase not configured → offline demo mode only.
    if (!_initialized) {
      return _demoSignIn(email);
    }

    final res = await _client!.auth
        .signInWithPassword(email: email, password: password)
        .timeout(const Duration(seconds: 6));
    final user = res.user;
    if (user == null) {
      throw const AuthException('Invalid email or password.');
    }
    await _logActivity(user.id, 'user_login');
    return _profileFor(user.id, email: email);
  }

  Future<void> _logActivity(String userId, String action,
      {String? entityType, Map<String, dynamic>? metadata}) async {
    if (!_initialized) return;
    try {
      await _client!.from('activity_logs').insert({
        'user_id': userId,
        'action': action,
        if (entityType != null) 'entity_type': entityType,
        if (metadata != null) 'metadata': metadata,
      }).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<void> signOut() async {
    if (!_initialized) {
      _demoUser = null;
      _demoScans.clear();
      return;
    }
    await _client!.auth.signOut();
  }

  Future<UserModel?> currentUser() async {
    if (!_initialized) return _demoUser;
    try {
      final user = _client!.auth.currentUser;
      if (user == null) return null;
      return _profileFor(user.id, email: user.email ?? '');
    } catch (_) {
      return _demoUser;
    }
  }

  Future<UserModel> _profileFor(
    String id, {
    String fallbackName = '',
    String email = '',
  }) async {
    try {
      final row = await _client!
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));
      if (row != null) return UserModel.fromMap(row);
    } catch (_) {}
    return UserModel(id: id, fullName: fallbackName, email: email);
  }

  Future<void> updateProfile(UserModel user) async {
    if (!_initialized) {
      _demoUser = user;
      return;
    }
    await _client!.from('profiles').update({
      'full_name': user.fullName,
      'phone': user.phone,
      'barangay': user.barangay,
      'farm_size_ha': user.farmSizeHa,
    }).eq('id', user.id).timeout(const Duration(seconds: 6));
  }

  Future<ScanModel> saveScan({
    required UserModel user,
    required DetectionResult result,
    String? imagePath,
    List<int>? imageBytes,
    double? latitude,
    double? longitude,
  }) async {
    String? imageUrl;
    if (_initialized && imageBytes != null && !user.id.startsWith('demo-')) {
      imageUrl = await _uploadBytes(user.id, imageBytes);
    }

    final pending = ScanModel(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      userId: user.id,
      diseaseCode: result.diseaseCode,
      diseaseName: result.diseaseName,
      confidence: result.confidence,
      modelVersion: result.modelVersion,
      isRiceLeaf: result.isRiceLeaf,
      imagePath: imagePath,
      imageUrl: imageUrl,
      barangay: user.barangay,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
    );

    // Demo user — in-memory only.
    if (!_initialized || user.id.startsWith('demo-')) {
      _demoScans.insert(0, pending);
      return pending;
    }

    String? diseaseId;
    try {
      final row = await _client!
          .from('diseases')
          .select('id')
          .eq('code', result.diseaseCode)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));
      diseaseId = row?['id']?.toString();
    } catch (_) {}

    final inserted = await _client!
        .from('scans')
        .insert(pending.copyWith(diseaseId: diseaseId).toInsertMap())
        .select()
        .single()
        .timeout(const Duration(seconds: 8));

    try {
      await _client!.from('activity_logs').insert({
        'user_id': user.id,
        'action': 'scan_completed',
        'entity_type': 'scan',
        'entity_id': inserted['id'],
        'metadata': {
          'disease_code': result.diseaseCode,
          'confidence': result.confidence,
        },
      }).timeout(const Duration(seconds: 4));
    } catch (_) {}

    return ScanModel.fromMap(inserted);
  }

  Future<List<ScanModel>> fetchScans(String userId) async {
    if (!_initialized || userId.startsWith('demo-')) {
      return List.unmodifiable(_demoScans);
    }
    final rows = await _client!
        .from('scans')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .timeout(const Duration(seconds: 8));
    return (rows as List)
        .map((e) => ScanModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteScan(String userId, String scanId) async {
    if (userId.startsWith('demo-') || scanId.startsWith('local-')) {
      _demoScans.removeWhere((s) => s.id == scanId);
      return;
    }
    if (!_initialized) return;
    await _client!
        .from('scans')
        .delete()
        .eq('id', scanId)
        .eq('user_id', userId)
        .timeout(const Duration(seconds: 6));
    try {
      await _client!.from('activity_logs').insert({
        'user_id': userId,
        'action': 'scan_deleted',
        'entity_type': 'scan',
        'entity_id': scanId,
      }).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<void> clearAllScans(String userId) async {
    if (userId.startsWith('demo-')) {
      _demoScans.clear();
      return;
    }
    if (!_initialized) return;
    await _client!
        .from('scans')
        .delete()
        .eq('user_id', userId)
        .timeout(const Duration(seconds: 8));
    try {
      await _client!.from('activity_logs').insert({
        'user_id': userId,
        'action': 'history_cleared',
        'entity_type': 'scan',
      }).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<void> deleteAccount(String userId) async {
    if (userId.startsWith('demo-')) {
      _demoUser = null;
      _demoScans.clear();
      return;
    }
    if (!_initialized) {
      throw Exception('Account deletion requires Supabase configuration.');
    }
    await clearAllScans(userId);
    await _client!.from('profiles').delete().eq('id', userId);
    await signOut();
  }

  Future<void> saveEvaluation({
    required String userId,
    required int rating,
    String? comment,
    String? scanId,
  }) async {
    if (!_initialized || userId.startsWith('demo-')) return;
    await _client!.from('evaluations').insert({
      'user_id': userId,
      'scan_id': scanId,
      'rating': rating,
      'comment': comment,
    }).timeout(const Duration(seconds: 6));
    try {
      await _client!.from('activity_logs').insert({
        'user_id': userId,
        'action': 'evaluation_submitted',
        'entity_type': 'evaluation',
        'metadata': {'rating': rating},
      }).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<void> resetPassword(String email) async {
    if (!_initialized) {
      throw Exception('Password reset requires Supabase configuration.');
    }
    await _client!.auth
        .resetPasswordForEmail(email.trim())
        .timeout(const Duration(seconds: 8));
  }

  Future<String?> _uploadBytes(String userId, List<int> bytes) async {
    try {
      final objectName =
          '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client!.storage
          .from('scan-images')
          .uploadBinary(objectName, Uint8List.fromList(bytes))
          .timeout(const Duration(seconds: 10));
      return _client!.storage.from('scan-images').getPublicUrl(objectName);
    } catch (_) {
      return null;
    }
  }
}
