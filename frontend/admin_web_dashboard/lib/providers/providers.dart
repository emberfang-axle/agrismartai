import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_models.dart';
import '../services/admin_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(supabaseClientProvider)),
);

final adminServiceProvider = Provider<AdminService>(
  (ref) => AdminService(ref.watch(supabaseClientProvider)),
);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final isAdminProvider = FutureProvider<bool>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(authServiceProvider).isAdmin();
});

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) {
  return ref.watch(adminServiceProvider).getStats();
});

final reportsProvider = FutureProvider.family<List<ScanReport>, ReportFilters>(
  (ref, filters) {
    return ref.watch(adminServiceProvider).getReports(
          status: filters.status,
          disease: filters.disease,
          barangay: filters.barangay,
          search: filters.search,
        );
  },
);

final farmersProvider = FutureProvider.family<List<FarmerProfile>, FarmerFilters>(
  (ref, filters) {
    return ref.watch(adminServiceProvider).getFarmers(
          barangay: filters.barangay,
          search: filters.search,
        );
  },
);

final analyticsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminServiceProvider).getAnalytics();
});

final settingsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminServiceProvider).getSettings();
});

final recentActivityProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminServiceProvider).getRecentActivity();
});

class ReportFilters {
  final String? status;
  final String? disease;
  final String? barangay;
  final String? search;

  const ReportFilters({
    this.status,
    this.disease,
    this.barangay,
    this.search,
  });

  @override
  bool operator ==(Object other) =>
      other is ReportFilters &&
      other.status == status &&
      other.disease == disease &&
      other.barangay == barangay &&
      other.search == search;

  @override
  int get hashCode => Object.hash(status, disease, barangay, search);
}

class FarmerFilters {
  final String? barangay;
  final String? search;

  const FarmerFilters({this.barangay, this.search});

  @override
  bool operator ==(Object other) =>
      other is FarmerFilters &&
      other.barangay == barangay &&
      other.search == search;

  @override
  int get hashCode => Object.hash(barangay, search);
}

final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

final reportFiltersProvider = StateProvider<ReportFilters>(
  (ref) => const ReportFilters(),
);

final farmerFiltersProvider = StateProvider<FarmerFilters>(
  (ref) => const FarmerFilters(),
);
