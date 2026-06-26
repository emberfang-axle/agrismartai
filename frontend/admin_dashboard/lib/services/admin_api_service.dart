import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/evaluation_model.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import '../utils/app_config.dart';

/// Admin REST client — PostgreSQL data via Python backend only.
class AdminApiService {
  AdminApiService._();
  static final AdminApiService instance = AdminApiService._();

  String get baseUrl => AppConfig.apiBaseUrl;
  bool _backendOk = false;
  UserModel? _session;

  bool get isReady => _backendOk;
  UserModel? get session => _session;

  Future<bool> checkHealth() async {
    try {
      final r = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 3));
      _backendOk = r.statusCode == 200;
      return _backendOk;
    } catch (_) {
      _backendOk = false;
      return false;
    }
  }

  Future<void> init() async {
    await checkHealth();
  }

  Future<bool> signInAdmin(String email, String password) async {
    if (!_backendOk) {
      final ok = await checkHealth();
      if (!ok) return false;
    }
    try {
      final r = await http
          .post(
            Uri.parse('$baseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return false;
      final map = jsonDecode(r.body) as Map<String, dynamic>;
      final role = map['role']?.toString() ?? '';
      if (role != 'admin') return false;
      _session = UserModel(
        id: map['id']?.toString() ?? '',
        fullName: map['full_name']?.toString() ?? 'Administrator',
        email: map['email']?.toString() ?? email,
        role: role,
        barangay: map['barangay']?.toString() ?? 'New Bataan',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    _session = null;
  }

  String? adminDisplayName() => _session?.fullName;

  Future<List<ReportModel>> fetchReports() async {
    if (!_backendOk) return [];
    try {
      final r = await http
          .get(Uri.parse('$baseUrl/api/reports'))
          .timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return [];
      final rows = jsonDecode(r.body) as List<dynamic>;
      return rows.map((row) {
        final map = row as Map<String, dynamic>;
        return ReportModel(
          id: map['id']?.toString() ?? '',
          farmerName: map['farmer_name']?.toString() ?? 'Unknown',
          barangay: map['barangay']?.toString() ?? 'New Bataan',
          diseaseCode: map['disease_code']?.toString() ?? 'healthy',
          diseaseName: map['disease_name']?.toString() ?? 'Healthy',
          confidence:
              double.tryParse(map['confidence']?.toString() ?? '0') ?? 0,
          status: ReportStatusX.fromString(map['status']?.toString()),
          imageUrl: map['image_url']?.toString(),
          createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.now(),
          reviewerNote: map['reviewer_note']?.toString(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<DiseaseStat>> fetchDiseaseStats() async {
    if (!_backendOk) return [];
    try {
      final r = await http
          .get(Uri.parse('$baseUrl/api/disease-stats'))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return [];
      final rows = jsonDecode(r.body) as List<dynamic>;
      return rows.map((row) {
        final map = row as Map<String, dynamic>;
        return DiseaseStat(
          code: map['disease_code']?.toString() ?? '',
          name: map['disease_label']?.toString() ?? '',
          count: int.tryParse(map['total_scans']?.toString() ?? '0') ?? 0,
          avgConfidence:
              double.tryParse(map['avg_confidence']?.toString() ?? '0') ?? 0,
        );
      }).where((s) => s.count > 0).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<FarmerModel>> fetchFarmers() async {
    if (!_backendOk) return [];
    try {
      final r = await http
          .get(Uri.parse('$baseUrl/api/farmers'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return [];
      final rows = jsonDecode(r.body) as List<dynamic>;
      return rows.map((row) {
        final map = row as Map<String, dynamic>;
        return FarmerModel(
          id: map['id']?.toString() ?? '',
          fullName: map['name']?.toString() ?? '',
          email: map['email']?.toString() ?? '',
          barangay: map['barangay']?.toString() ?? 'New Bataan',
          totalScans: int.tryParse(map['total_scans']?.toString() ?? '0') ?? 0,
          diseasedScans:
              int.tryParse(map['diseased_scans']?.toString() ?? '0') ?? 0,
          joinedAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ActivityEntry>> fetchRecentActivities({int limit = 50}) async {
    // Activity log table optional — derive from recent reports when live.
    final reports = await fetchReports();
    return reports.take(limit).map((r) {
      return ActivityEntry(
        id: r.id,
        action: r.status == ReportStatus.verified
            ? 'report_verified'
            : r.status == ReportStatus.rejected
                ? 'report_rejected'
                : 'scan_completed',
        actorName: r.farmerName,
        detail: '${r.diseaseName} · ${r.confidence.toStringAsFixed(0)}%',
        createdAt: r.createdAt,
      );
    }).toList();
  }

  Future<List<EvaluationModel>> fetchEvaluations() async {
    if (!_backendOk) return [];
    try {
      final r = await http
          .get(Uri.parse('$baseUrl/api/feedback'))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return [];
      final rows = jsonDecode(r.body) as List<dynamic>;
      return rows.map((row) {
        final map = row as Map<String, dynamic>;
        return EvaluationModel(
          id: map['id']?.toString() ?? '',
          farmerName: map['farmer_name']?.toString() ?? 'Farmer',
          rating: int.tryParse(map['rating']?.toString() ?? '5') ?? 5,
          comment: map['comment']?.toString(),
          createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> verifyReport(String reportId, {String? note}) async {
    await _patchStatus(reportId, 'verified', note);
  }

  Future<void> rejectReport(String reportId, {String? note}) async {
    await _patchStatus(reportId, 'rejected', note);
  }

  Future<void> _patchStatus(String reportId, String status, String? note) async {
    if (!_backendOk) throw StateError('Backend not ready');
    final r = await http
        .patch(
          Uri.parse('$baseUrl/api/reports/$reportId/status'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'status': status,
            if (note != null && note.isNotEmpty) 'reviewer_note': note,
          }),
        )
        .timeout(const Duration(seconds: 8));
    if (r.statusCode >= 400) {
      throw Exception('Failed to update report (${r.statusCode})');
    }
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
