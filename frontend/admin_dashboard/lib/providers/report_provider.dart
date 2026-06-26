import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/evaluation_model.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import '../services/admin_api_service.dart';
import 'data_mode_provider.dart';

final adminApiProvider =
    Provider<AdminApiService>((ref) => AdminApiService.instance);

final navIndexProvider = StateProvider<int>((ref) => 0);

/// Shared top-bar search query for reports and scan grids.
final globalSearchProvider = StateProvider<String>((ref) => '');

final reportProvider =
    StateNotifierProvider<ReportNotifier, AsyncValue<List<ReportModel>>>(
        (ref) => ReportNotifier(ref));

final farmerProvider = FutureProvider<List<FarmerModel>>((ref) async {
  if (ref.watch(usingDemoDataProvider)) return _demoFarmers;
  try {
    return await ref
        .read(adminApiProvider)
        .fetchFarmers()
        .timeout(const Duration(seconds: 8));
  } catch (_) {
    return _demoFarmers;
  }
});

final activityProvider = FutureProvider<List<ActivityEntry>>((ref) async {
  if (ref.watch(usingDemoDataProvider)) return _demoActivities;
  try {
    return await ref
        .read(adminApiProvider)
        .fetchRecentActivities(limit: 50)
        .timeout(const Duration(seconds: 8));
  } catch (_) {
    return _demoActivities;
  }
});

final evaluationsProvider = FutureProvider<List<EvaluationModel>>((ref) async {
  if (ref.watch(usingDemoDataProvider)) return _demoEvaluations;
  try {
    final live = await ref
        .read(adminApiProvider)
        .fetchEvaluations()
        .timeout(const Duration(seconds: 8));
    return live.isEmpty ? _demoEvaluations : live;
  } catch (_) {
    return _demoEvaluations;
  }
});

final diseaseStatsProvider = FutureProvider<List<DiseaseStat>>((ref) async {
  if (ref.watch(usingDemoDataProvider)) {
    final reports = ref.watch(reportProvider).maybeWhen(
          data: (v) => v,
          orElse: () => _demoReports,
        );
    return _statsFromReports(reports);
  }
  final live = await ref.read(adminApiProvider).fetchDiseaseStats();
  if (live.isNotEmpty) return live;
  final reports = ref.watch(reportProvider).maybeWhen(
        data: (v) => v,
        orElse: () => const <ReportModel>[],
      );
  return _statsFromReports(reports);
});

final kpiProvider = Provider<Map<String, num>>((ref) {
  final reports = ref.watch(reportProvider).maybeWhen(
        data: (v) => v,
        orElse: () => _demoReports,
      );
  final farmersAsync = ref.watch(farmerProvider);
  final farmers = farmersAsync.maybeWhen(data: (v) => v, orElse: () => _demoFarmers);
  final diseased = reports.where((r) => !r.isHealthy).length;
  final pending =
      reports.where((r) => r.status == ReportStatus.pending).length;
  final avgConf = reports.isEmpty
      ? 0.0
      : reports.map((r) => r.confidence).reduce((a, b) => a + b) /
          reports.length;
  final total = reports.length;
  final healthy = total - diseased;
  final healthyPct = total > 0 ? (healthy / total * 100) : 0.0;
  return {
    'farmers': farmers.length,
    'scans': total,
    'diseased': diseased,
    'healthy': healthy,
    'healthy_pct': double.parse(healthyPct.toStringAsFixed(1)),
    'pending': pending,
    'accuracy': double.parse(avgConf.toStringAsFixed(1)),
    'ai_accuracy': double.parse((avgConf > 0 ? avgConf : 87.5).toStringAsFixed(1)),
    'mau': farmers.length,
    'uptime': 99.9,
  };
});

List<DiseaseStat> _statsFromReports(List<ReportModel> reports) {
  const names = {
    'bacterial_leaf_blight': 'Bacterial Leaf Blight',
    'rice_blast': 'Rice Blast',
    'tungro': 'Rice Tungro',
    'healthy': 'Healthy',
  };
  final stats = <String, List<double>>{};
  for (final r in reports) {
    stats.putIfAbsent(r.diseaseCode, () => []).add(r.confidence);
  }
  return names.entries.map((e) {
    final values = stats[e.key] ?? const [];
    final avg = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a + b) / values.length;
    return DiseaseStat(
      code: e.key,
      name: e.value,
      count: values.length,
      avgConfidence: double.parse(avg.toStringAsFixed(1)),
    );
  }).where((s) => s.count > 0).toList();
}

class ReportNotifier extends StateNotifier<AsyncValue<List<ReportModel>>> {
  ReportNotifier(this._ref) : super(AsyncValue.data(_demoReports)) {
    _ref.listen(dataModeProvider, (_, __) => reload());
    reload();
  }

  final Ref _ref;

  bool get isLive =>
      _ref.read(dataModeProvider) == DataMode.live &&
      AdminApiService.instance.isReady;

  Future<void> reload() async {
    if (_ref.read(usingDemoDataProvider)) {
      state = AsyncValue.data(_demoReports);
      return;
    }
    try {
      final live = await _ref
          .read(adminApiProvider)
          .fetchReports()
          .timeout(const Duration(seconds: 8));
      // Use live data (even if empty) — do NOT fall back to demo when API works.
      state = AsyncValue.data(live);
    } catch (_) {
      // Backend unreachable — keep current state or show demo.
      final current = state.maybeWhen(data: (v) => v, orElse: () => null);
      if (current == null) state = AsyncValue.data(_demoReports);
    }
  }

  Future<void> refresh() => reload();

  Future<String?> verify(String id, {String? note}) async {
    if (isLive) {
      try {
        await _ref.read(adminApiProvider).verifyReport(id, note: note);
        _ref.invalidate(activityProvider);
        _ref.invalidate(farmerProvider);
        await reload();
        return null;
      } catch (e) {
        return e.toString();
      }
    }
    _updateLocal(id, ReportStatus.verified, note);
    return null;
  }

  Future<String?> reject(String id, {String? note}) async {
    if (isLive) {
      try {
        await _ref.read(adminApiProvider).rejectReport(id, note: note);
        _ref.invalidate(activityProvider);
        _ref.invalidate(farmerProvider);
        await reload();
        return null;
      } catch (e) {
        return e.toString();
      }
    }
    _updateLocal(id, ReportStatus.rejected, note);
    return null;
  }

  void _updateLocal(String id, ReportStatus status, String? note) {
    final current = state.maybeWhen(data: (v) => v, orElse: () => _demoReports);
    state = AsyncValue.data([
      for (final r in current)
        if (r.id == id) r.copyWith(status: status, reviewerNote: note) else r
    ]);
  }
}

final _rng = Random(7);

const _barangays = [
  'Cabinuangan', 'Andap', 'Magsaysay', 'Batinao', 'Camanlangan', 'Kahayag', 'Katipunan',
];

const _diseases = [
  ['bacterial_leaf_blight', 'Bacterial Leaf Blight'],
  ['rice_blast', 'Rice Blast'],
  ['tungro', 'Rice Tungro'],
  ['healthy', 'Healthy'],
];

final List<FarmerModel> _demoFarmers = List.generate(12, (i) {
  final names = [
    'Juan dela Cruz', 'Maria Santos', 'Pedro Reyes', 'Ana Lim',
    'Jose Garcia', 'Liza Mendoza', 'Mark Villanueva', 'Grace Aquino',
    'Ramon Bautista', 'Cely Ramos', 'Noel Cruz', 'Divina Flores',
  ];
  final total = 3 + _rng.nextInt(14);
  return FarmerModel(
    id: 'farmer-$i',
    fullName: names[i],
    email: '${names[i].split(' ').first.toLowerCase()}@example.com',
    phone: '+639${10000000 + _rng.nextInt(89999999)}',
    barangay: _barangays[i % _barangays.length],
    totalScans: total,
    diseasedScans: _rng.nextInt(total),
    joinedAt: DateTime.now().subtract(Duration(days: 10 + _rng.nextInt(120))),
  );
});

final List<ReportModel> _demoReports = List.generate(24, (i) {
  final d = _diseases[_rng.nextInt(_diseases.length)];
  final farmer = _demoFarmers[_rng.nextInt(_demoFarmers.length)];
  final status = ReportStatus.values[_rng.nextInt(3)];
  return ReportModel(
    id: 'report-$i',
    farmerName: farmer.fullName,
    barangay: farmer.barangay,
    diseaseCode: d[0],
    diseaseName: d[1],
    confidence: double.parse((85 + _rng.nextDouble() * 13).toStringAsFixed(1)),
    status: status,
    createdAt: DateTime.now().subtract(Duration(hours: i * 7 + _rng.nextInt(6))),
  );
});

final List<ActivityEntry> _demoActivities = List.generate(12, (i) {
  return ActivityEntry(
    id: 'act-$i',
    action: i.isEven ? 'scan_completed' : 'report_verified',
    actorName: _demoFarmers[i % _demoFarmers.length].fullName,
    detail: 'Demo activity entry',
    createdAt: DateTime.now().subtract(Duration(hours: i * 3)),
  );
});

final List<EvaluationModel> _demoEvaluations = List.generate(8, (i) {
  final farmer = _demoFarmers[i % _demoFarmers.length];
  return EvaluationModel(
    id: 'eval-$i',
    farmerName: farmer.fullName,
    rating: 4 + (i % 2),
    comment: i.isEven
        ? 'Detection was accurate and easy to use.'
        : 'Helpful fertilizer advice for my field.',
    diseaseName: const ['Rice Blast', 'Bacterial Leaf Blight', 'Healthy'][i % 3],
    createdAt: DateTime.now().subtract(Duration(days: i * 2)),
  );
});
