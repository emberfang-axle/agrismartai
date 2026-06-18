import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_charts.dart';
import '../widgets/admin_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final activityAsync = ref.watch(recentActivityProvider);
    final analyticsAsync = ref.watch(analyticsProvider);
    final collapsed = ref.watch(sidebarCollapsedProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Dashboard',
          subtitle: 'Overview of AgriSmartAI field data',
          actions: [
            IconButton(
              icon: Icon(collapsed ? Icons.menu_open : Icons.menu),
              onPressed: () => ref
                  .read(sidebarCollapsedProvider.notifier)
                  .update((s) => !s),
            ),
            const SizedBox(width: 8),
            GoldButton(
              label: 'Refresh',
              icon: Icons.refresh_rounded,
              onPressed: () {
                ref.invalidate(dashboardStatsProvider);
                ref.invalidate(recentActivityProvider);
              },
            ),
          ],
        ),
        Expanded(
          child: statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e', style: AppTheme.body)),
            data: (stats) {
              final byMonth = analyticsAsync.maybeWhen(
                data: (a) => Map<String, int>.from(a['byMonth'] as Map? ?? {}),
                orElse: () => <String, int>{},
              );

              return SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth > 900 ? 4 : 2;
                      return GridView.count(
                        crossAxisCount: cols,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 2.2,
                        children: [
                          StatsCard(
                            title: 'Total Farmers',
                            value: '${stats.totalFarmers}',
                            icon: Icons.people_rounded,
                            color: AppTheme.primary,
                          ),
                          StatsCard(
                            title: 'Total Reports',
                            value: '${stats.totalReports}',
                            icon: Icons.assignment_rounded,
                            color: AppTheme.accent,
                          ),
                          StatsCard(
                            title: 'Pending Verifications',
                            value: '${stats.pendingVerifications}',
                            icon: Icons.pending_actions_rounded,
                            color: AppTheme.secondary,
                          ),
                          StatsCard(
                            title: 'Disease Types',
                            value: '${stats.diseasesByType.length}',
                            icon: Icons.biotech_rounded,
                            color: AppTheme.blast,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 800) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ChartCard(
                                title: 'Disease Distribution',
                                child: DiseasePieChart(data: stats.diseasesByType),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ChartCard(
                                title: 'Reports by Month',
                                child: MonthlyBarChart(data: byMonth),
                              ),
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          ChartCard(
                            title: 'Disease Distribution',
                            child: DiseasePieChart(data: stats.diseasesByType),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recent Activity', style: AppTheme.heading2),
                        const SizedBox(height: 16),
                        activityAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, __) =>
                              Text('Could not load activity', style: AppTheme.body),
                          data: (items) {
                            if (items.isEmpty) {
                              return Text('No scans yet', style: AppTheme.body);
                            }
                            return Column(
                              children: items.map((item) {
                                final profile =
                                    item['profiles'] as Map<String, dynamic>?;
                                final name =
                                    profile?['full_name'] ?? 'Farmer';
                                final disease = item['disease'] ?? '';
                                final created = DateTime.tryParse(
                                        item['created_at']?.toString() ?? '') ??
                                    DateTime.now();
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.diseaseColor(disease)
                                        .withValues(alpha: 0.15),
                                    child: Icon(
                                      Icons.eco_rounded,
                                      color: AppTheme.diseaseColor(disease),
                                    ),
                                  ),
                                  title: Text('$name — $disease',
                                      style: AppTheme.button.copyWith(fontSize: 14)),
                                  subtitle: Text(
                                    DateFormat('MMM d, h:mm a').format(created),
                                    style: AppTheme.body.copyWith(fontSize: 12),
                                  ),
                                  trailing: _StatusChip(
                                    status: item['status'] as String? ?? 'pending',
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
            },
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: AppTheme.button.copyWith(color: color, fontSize: 12),
      ),
    );
  }
}
