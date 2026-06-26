import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../models/report_model.dart';
import '../providers/report_provider.dart';
import '../widgets/admin_ui.dart';
import '../widgets/chart_widget.dart';

/// AgriSmartAI :: Analytics screen (OBJECTIVE 2 & 4).
/// Visualises disease distribution and model confidence across New Bataan.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(diseaseStatsProvider);
    final kpi = ref.watch(kpiProvider);
    final reports = ref.watch(reportProvider).value ?? const <ReportModel>[];

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: AdminUi.emptyState(
          icon: Icons.bar_chart_outlined,
          title: 'Analytics unavailable',
          message: 'Tap refresh in the top bar to reload chart data.',
        ),
      ),
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminUi.pageHeader(
              title: 'Analytics',
              subtitle:
                  'Disease trends and model confidence across ${kpi['farmers']} farmers',
            ),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth > 900;
              final bar = _card(context, 'Detections by Disease', 300,
                  DiseaseBarChart(stats: stats));
              final pie = _card(context, 'Distribution Share', 300,
                  DiseasePieChart(stats: stats));
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: bar),
                        const SizedBox(width: 16),
                        Expanded(child: pie),
                      ],
                    )
                  : Column(children: [bar, const SizedBox(height: 16), pie]);
            }),
            const SizedBox(height: 24),
            _card(context, 'Monthly Scans', 260, MonthlyScanChart(reports: reports)),
            const SizedBox(height: 24),
            Text('Model Confidence by Disease',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Average detection confidence by disease type (OBJECTIVE 2).',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    for (final s in stats.where((e) => e.count > 0))
                      _confidenceRow(context, s.name, s.avgConfidence,
                          diseaseColor(s.code)),
                    if (stats.every((e) => e.count == 0))
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No data yet.',
                            style: TextStyle(color: AppColors.muted)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _summaryBanner(context, kpi),
          ],
        ),
      ),
    );
  }

  Widget _card(
      BuildContext context, String title, double height, Widget child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            SizedBox(height: height, child: child),
          ],
        ),
      ),
    );
  }

  Widget _confidenceRow(
      BuildContext context, String name, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
              width: 170,
              child: Text(name,
                  style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 12,
                backgroundColor: AppColors.softGreen,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('$value%',
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _summaryBanner(BuildContext context, Map<String, num> kpi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deepGreen, AppColors.leafGreen],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _metric('${kpi['scans']}', 'Total Scans'),
          _metric('${kpi['diseased']}', 'Diseased'),
          _metric('${kpi['pending']}', 'Pending Review'),
          _metric('${kpi['accuracy']}%', 'Avg. Confidence'),
        ],
      ),
    );
  }

  Widget _metric(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
