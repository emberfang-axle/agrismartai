import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_models.dart';

class AuthService {
  final SupabaseClient _client;
  AuthService(this._client);

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;
    final row = await _client
        .from('admins')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
    return row != null;
  }

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
    final admin = await isAdmin();
    if (!admin) {
      await _client.auth.signOut();
      throw Exception('Not authorized as admin');
    }
  }

  Future<void> signOut() => _client.auth.signOut();
}

class AdminService {
  final SupabaseClient _client;
  AdminService(this._client);

  Future<DashboardStats> getStats() async {
    final profiles = await _client.from('profiles').select('id');
    final scans = await _client.from('scans').select('disease, status');

    final farmerCount = (profiles as List).length;
    final scanList = scans as List;
    final pending = scanList.where((s) => s['status'] == 'pending').length;

    final diseaseMap = <String, int>{};
    for (final s in scanList) {
      final d = (s['disease'] as String?) ?? 'Unknown';
      diseaseMap[d] = (diseaseMap[d] ?? 0) + 1;
    }

    return DashboardStats(
      totalFarmers: farmerCount,
      totalReports: scanList.length,
      pendingVerifications: pending,
      diseasesByType: diseaseMap,
    );
  }

  Future<List<ScanReport>> getReports({
    String? status,
    String? disease,
    String? barangay,
    String? search,
  }) async {
    var query = _client.from('scans').select('*, profiles(*)');

    final rows = await query.order('created_at', ascending: false);
    var reports = (rows as List)
        .map((e) => ScanReport.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    if (status != null && status != 'All') {
      reports = reports.where((r) => r.status == status.toLowerCase()).toList();
    }
    if (disease != null && disease != 'All') {
      reports = reports
          .where((r) =>
              r.disease.toLowerCase().contains(disease.toLowerCase()) ||
              r.displayDisease.toLowerCase().contains(disease.toLowerCase()))
          .toList();
    }
    if (barangay != null && barangay != 'All') {
      reports = reports.where((r) => r.barangay == barangay).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      reports = reports
          .where((r) =>
              r.farmerName.toLowerCase().contains(q) ||
              r.barangay.toLowerCase().contains(q) ||
              r.displayDisease.toLowerCase().contains(q))
          .toList();
    }
    return reports;
  }

  Future<void> verifyReport(String scanId) async {
    await _client
        .from('scans')
        .update({'status': 'verified'})
        .eq('id', scanId);
  }

  Future<List<FarmerProfile>> getFarmers({
    String? barangay,
    String? search,
  }) async {
    final profiles = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false);

    final scans = await _client.from('scans').select('user_id');
    final scanCounts = <String, int>{};
    for (final s in scans as List) {
      final uid = s['user_id'] as String;
      scanCounts[uid] = (scanCounts[uid] ?? 0) + 1;
    }

    var farmers = (profiles as List).map((p) {
      final id = p['id'] as String;
      return FarmerProfile(
        id: id,
        fullName: p['full_name'] as String? ?? 'Farmer',
        email: p['email'] as String? ?? '',
        barangay: p['barangay'] as String? ?? '',
        totalScans: scanCounts[id] ?? 0,
        joinDate: DateTime.tryParse(p['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
    }).toList();

    if (barangay != null && barangay != 'All') {
      farmers = farmers.where((f) => f.barangay == barangay).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      farmers = farmers
          .where((f) =>
              f.fullName.toLowerCase().contains(q) ||
              f.email.toLowerCase().contains(q))
          .toList();
    }
    return farmers;
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final scans = await _client
        .from('scans')
        .select('disease, created_at, profiles(barangay)');

    final list = scans as List;
    final byDisease = <String, int>{};
    final byMonth = <String, int>{};
    final byBarangay = <String, int>{};

    for (final s in list) {
      final disease = s['disease'] as String? ?? 'Unknown';
      byDisease[disease] = (byDisease[disease] ?? 0) + 1;

      final created = DateTime.tryParse(s['created_at']?.toString() ?? '');
      if (created != null) {
        final key = '${created.year}-${created.month.toString().padLeft(2, '0')}';
        byMonth[key] = (byMonth[key] ?? 0) + 1;
      }

      final profile = s['profiles'] as Map<String, dynamic>?;
      final brgy = profile?['barangay'] as String? ?? 'Unknown';
      byBarangay[brgy] = (byBarangay[brgy] ?? 0) + 1;
    }

    return {
      'byDisease': byDisease,
      'byMonth': byMonth,
      'byBarangay': byBarangay,
    };
  }

  Future<Map<String, dynamic>> getSettings() async {
    final row = await _client
        .from('settings')
        .select()
        .eq('key', 'app_settings')
        .maybeSingle();

    return row?['value'] as Map<String, dynamic>? ??
        {
          'da_phone': '(082) 123-4567',
          'da_address': 'DA Compound, Bago Oshiro, Davao City',
          'da_hours': 'Mon–Fri, 8AM–5PM',
          'fertilizer_blb': 'Reduce nitrogen by 30%, apply MOP 40 kg/ha',
          'fertilizer_blast': 'Apply calcium silicate 200 kg/ha',
          'fertilizer_tungro': 'Balanced NPK with extra potassium',
          'fertilizer_healthy': 'Regular NPK at tillering stage',
        };
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _client.from('settings').upsert({
      'key': 'app_settings',
      'value': settings,
    });
  }

  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 8}) async {
    final rows = await _client
        .from('scans')
        .select('*, profiles(full_name, barangay)')
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List).cast<Map<String, dynamic>>();
  }
}
