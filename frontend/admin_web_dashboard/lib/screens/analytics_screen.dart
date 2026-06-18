import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_charts.dart';
import '../widgets/admin_widgets.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Disease Analytics',
          subtitle: 'Trends and patterns across New Bataan',
          actions: [
            GoldButton(
              label: 'Refresh',
              icon: Icons.refresh_rounded,
              onPressed: () => ref.invalidate(analyticsProvider),
            ),
          ],
        ),
        Expanded(
          child: analyticsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (data) {
              final byDisease =
                  Map<String, int>.from(data['byDisease'] as Map? ?? {});
              final byMonth =
                  Map<String, int>.from(data['byMonth'] as Map? ?? {});
              final byBarangay =
                  Map<String, int>.from(data['byBarangay'] as Map? ?? {});

              return SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 900) {
                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ChartCard(
                                  title: 'Most Common Diseases',
                                  child: MonthlyBarChart(
                                    data: byDisease.isEmpty
                                        ? {'BLB': 0}
                                        : byDisease,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ChartCard(
                                  title: 'Disease Distribution',
                                  child: DiseasePieChart(data: byDisease),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ChartCard(
                                  title: 'Disease Trends Over Time',
                                  height: 280,
                                  child: DiseaseTrendLineChart(data: byMonth),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ChartCard(
                                  title: 'Disease by Barangay',
                                  child: BarangayBarChart(data: byBarangay),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        ChartCard(
                          title: 'Most Common Diseases',
                          child: MonthlyBarChart(data: byDisease),
                        ),
                        const SizedBox(height: 16),
                        ChartCard(
                          title: 'Disease Trends Over Time',
                          height: 280,
                          child: DiseaseTrendLineChart(data: byMonth),
                        ),
                        const SizedBox(height: 16),
                        ChartCard(
                          title: 'Disease by Barangay',
                          child: BarangayBarChart(data: byBarangay),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
