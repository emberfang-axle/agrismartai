import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/evaluation_model.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import '../utils/app_config.dart';

/// Supabase reads for admin dashboard (falls back to demo data when unavailable).
class AdminSupabaseService {
  AdminSupabaseService._();
  static final AdminSupabaseService instance = AdminSupabaseService._();

  static bool _initialized = false;

  bool get isReady => AppConfig.isSupabaseConfigured && _initialized;

  SupabaseClient? get _client =>
      isReady ? Supabase.instance.client : null;

  static Future<void> init() async {
    if (!AppConfig.isSupabaseConfigured || _initialized) return;
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: AppConfig.supabaseAnonKey,
      ).timeout(const Duration(seconds: 6));
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  Future<bool> signInAdmin(String email, String password) async {
    if (!isReady) return false;
    final res = await _client!.auth
        .signInWithPassword(email: email, password: password)
        .timeout(const Duration(seconds: 8));
    final user = res.user;
    if (user == null) return false;
    final ok = await isStaffUser();
    if (ok) {
      await _logActivity('admin_login', 'auth', user.id);
    }
    return ok;
  }

  Future<bool> isStaffUser() async {
    if (!isReady) return false;
    final user = _client!.auth.currentUser;
    if (user == null) return false;
    // Check profile role from DB.
    final profile = await _client!
        .from('profiles')
        .select('role, email')
        .eq('id', user.id)
        .maybeSingle()
        .timeout(const Duration(seconds: 5));
    final role = profile?['role']?.toString() ?? '';
    if (role == 'admin' || role == 'technician') return true;
    // Fallback: treat the known admin email as staff even if role not set yet.
    final email = profile?['email']?.toString() ?? user.email ?? '';
    if (email == 'admin@agrismartai.ph' || email == 'tech@agrismartai.ph') {
      // Upgrade role in DB so future logins work correctly.
      try {
        final newRole = email == 'admin@agrismartai.ph' ? 'admin' : 'technician';
        await _client!.from('profiles').update({'role': newRole}).eq('id', user.id);
      } catch (_) {}
      return true;
    }
    return false;
  }

  Future<void> signOut() async {
    if (!isReady) return;
    try {
      await _client!.auth.signOut();
    } catch (_) {}
  }

  Future<String?> adminDisplayName() async {
    if (!isReady) return null;
    final user = _client!.auth.currentUser;
    if (user == null) return null;
    final row = await _client!
        .from('profiles')
        .select('full_name')
        .eq('id', user.id)
        .maybeSingle();
    return row?['full_name']?.toString() ?? user.email;
  }

  Future<List<ReportModel>> fetchReports() async {
    if (!isReady) return [];
    final rows = await _client!
        .from('scans')
        .select(
            'id, disease_code, disease_name, confidence, image_url, barangay, created_at, profiles(full_name, barangay), reports(status, reviewer_note)')
        .order('created_at', ascending: false)
        .limit(200)
        .timeout(const Duration(seconds: 12));

    return (rows as List).map((row) {
      final map = row as Map<String, dynamic>;
      final profile = map['profiles'];
      final reports = map['reports'];
      Map<String, dynamic>? reportRow;
      if (reports is List && reports.isNotEmpty) {
        reportRow = reports.first as Map<String, dynamic>;
      } else if (reports is Map<String, dynamic>) {
        reportRow = reports;
      }

      final farmerName = profile is Map
          ? profile['full_name']?.toString() ?? 'Unknown'
          : 'Unknown';
      final barangay = map['barangay']?.toString() ??
          (profile is Map ? profile['barangay']?.toString() : null) ??
          'New Bataan';

      return ReportModel(
        id: map['id']?.toString() ?? '',
        farmerName: farmerName,
        barangay: barangay,
        diseaseCode: map['disease_code']?.toString() ?? 'healthy',
        diseaseName: map['disease_name']?.toString() ?? 'Healthy',
        confidence:
            double.tryParse(map['confidence']?.toString() ?? '0') ?? 0,
        status: ReportStatusX.fromString(reportRow?['status']?.toString()),
        imageUrl: map['image_url']?.toString(),
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
            DateTime.now(),
        reviewerNote: reportRow?['reviewer_note']?.toString(),
      );
    }).toList();
  }

  Future<List<DiseaseStat>> fetchDiseaseStats() async {
    if (!isReady) return [];
    final rows = await _client!
        .from('disease_stats')
        .select(
            'disease_code, disease_name, total_scans, avg_confidence')
        .order('total_scans', ascending: false)
        .timeout(const Duration(seconds: 8));

    return (rows as List).map((row) {
      final map = row as Map<String, dynamic>;
      return DiseaseStat(
        code: map['disease_code']?.toString() ?? '',
        name: map['disease_name']?.toString() ?? '',
        count: int.tryParse(map['total_scans']?.toString() ?? '0') ?? 0,
        avgConfidence:
            double.tryParse(map['avg_confidence']?.toString() ?? '0') ?? 0,
      );
    }).where((s) => s.count > 0).toList();
  }

  Future<List<FarmerModel>> fetchFarmers() async {
    if (!isReady) return [];
    final profiles = await _client!
        .from('profiles')
        .select('id, full_name, email, phone, role, barangay, created_at')
        .eq('role', 'farmer')
        .order('created_at', ascending: false)
        .timeout(const Duration(seconds: 10));

    final scans = await _client!
        .from('scans')
        .select('user_id, disease_code')
        .timeout(const Duration(seconds: 10));

    final totals = <String, int>{};
    final diseased = <String, int>{};
    for (final s in scans as List) {
      final m = s as Map<String, dynamic>;
      final uid = m['user_id']?.toString() ?? '';
      totals[uid] = (totals[uid] ?? 0) + 1;
      if (m['disease_code']?.toString() != 'healthy') {
        diseased[uid] = (diseased[uid] ?? 0) + 1;
      }
    }

    return (profiles as List).map((row) {
      final map = row as Map<String, dynamic>;
      final id = map['id']?.toString() ?? '';
      return FarmerModel(
        id: id,
        fullName: map['full_name']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        phone: map['phone']?.toString(),
        role: map['role']?.toString() ?? 'farmer',
        barangay: map['barangay']?.toString() ?? 'New Bataan',
        totalScans: totals[id] ?? 0,
        diseasedScans: diseased[id] ?? 0,
        joinedAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  Future<List<ActivityEntry>> fetchRecentActivities({int limit = 50}) async {
    if (!isReady) return [];
    final rows = await _client!
        .from('activity_logs')
        .select('id, action, entity_type, metadata, created_at, profiles(full_name)')
        .order('created_at', ascending: false)
        .limit(limit)
        .timeout(const Duration(seconds: 8));

    return (rows as List).map((row) {
      final map = row as Map<String, dynamic>;
      final profile = map['profiles'];
      final name = profile is Map
          ? profile['full_name']?.toString() ?? 'System'
          : 'System';
      final meta = map['metadata'];
      final detail = meta is Map
          ? meta.entries.map((e) => '${e.key}: ${e.value}').join(' · ')
          : meta?.toString() ?? '';
      return ActivityEntry(
        id: map['id']?.toString() ?? '',
        action: map['action']?.toString() ?? 'activity',
        actorName: name,
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
            DateTime.now(),
        detail: detail.isEmpty ? map['entity_type']?.toString() ?? '' : detail,
      );
    }).toList();
  }

  Future<List<EvaluationModel>> fetchEvaluations() async {
    if (!isReady) return [];
    final rows = await _client!
        .from('evaluations')
        .select(
            'id, rating, comment, created_at, profiles(full_name), scans(disease_name)')
        .order('created_at', ascending: false)
        .limit(100)
        .timeout(const Duration(seconds: 8));

    return (rows as List).map((row) {
      final map = row as Map<String, dynamic>;
      final profile = map['profiles'];
      final scan = map['scans'];
      final farmerName = profile is Map
          ? profile['full_name']?.toString() ?? 'Farmer'
          : 'Farmer';
      final diseaseName = scan is Map
          ? scan['disease_name']?.toString()
          : null;
      return EvaluationModel(
        id: map['id']?.toString() ?? '',
        farmerName: farmerName,
        rating: int.tryParse(map['rating']?.toString() ?? '5') ?? 5,
        comment: map['comment']?.toString(),
        diseaseName: diseaseName,
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  Future<void> verifyReport(String scanId, {String? note}) async {
    if (!isReady) throw StateError('Supabase not ready');
    final adminId = _client!.auth.currentUser?.id;
    final scan = await _client!
        .from('scans')
        .select('user_id')
        .eq('id', scanId)
        .maybeSingle();
    final farmerId = scan?['user_id']?.toString() ?? adminId;
    await _client!.from('reports').upsert({
      'scan_id': scanId,
      'farmer_id': farmerId,
      'status': 'verified',
      'reviewer_note': note,
      'reviewed_by': adminId,
      'reviewed_at': DateTime.now().toIso8601String(),
    }, onConflict: 'scan_id');
    await _logActivity('report_verified', 'scan', scanId);
  }

  Future<void> rejectReport(String scanId, {String? note}) async {
    if (!isReady) throw StateError('Supabase not ready');
    final adminId = _client!.auth.currentUser?.id;
    final scan = await _client!
        .from('scans')
        .select('user_id')
        .eq('id', scanId)
        .maybeSingle();
    final farmerId = scan?['user_id']?.toString() ?? adminId;
    await _client!.from('reports').upsert({
      'scan_id': scanId,
      'farmer_id': farmerId,
      'status': 'rejected',
      'reviewer_note': note,
      'reviewed_by': adminId,
      'reviewed_at': DateTime.now().toIso8601String(),
    }, onConflict: 'scan_id');
    await _logActivity('report_rejected', 'scan', scanId);
  }

  Future<void> _logActivity(String action, String entityType, String entityId) async {
    try {
      await _client!.from('activity_logs').insert({
        'user_id': _client!.auth.currentUser?.id,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
      });
    } catch (_) {}
  }
}

class ActivityEntry {
  final String id;
  final String action;
  final String actorName;
  final String detail;
  final DateTime createdAt;

  const ActivityEntry({
    required this.id,
    required this.action,
    required this.actorName,
    required this.detail,
    required this.createdAt,
  });
}
