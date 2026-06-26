import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../models/report_model.dart';
import '../providers/data_mode_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../services/admin_api_service.dart';
import '../widgets/chart_widget.dart';
import '../widgets/sidebar.dart';
import '../widgets/stats_card.dart';
import 'analytics_screen.dart';
import 'evaluations_screen.dart';
import 'farmers_screen.dart';
import 'reports_screen.dart';
import 'scans_screen.dart';
import 'module_screens.dart';
import 'settings_screen.dart';

/// AgriSmartAI v2.0 — Enterprise admin dashboard.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _titles = [
    'Command Center',
    'Farmer Management',
    'Disease Detections',
    'Disease Database',
    'AI Analytics',
    'Reports',
    'Feedback',
    'Notifications',
    'System Monitor',
    'User Management',
    'Settings',
    'Admin Profile',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navIndexProvider);
    final wide = MediaQuery.sizeOf(context).width >= 1000;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      drawer: wide
          ? null
          : Drawer(
              backgroundColor: AppColors.surface,
              child: Sidebar(
                inDrawer: true,
                onNavigate: () => Navigator.pop(context),
              ),
            ),
      body: Row(
        children: [
          if (wide) const Sidebar(),
          Expanded(
            child: Column(
              children: [
                _TopBar(title: _titles[index], showMenu: !wide),
                Expanded(child: _content(index)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(int index) => switch (index) {
        1 => const FarmersScreen(),
        2 => const ScansScreen(),
        3 => const DiseaseDatabaseScreen(),
        4 => const AnalyticsScreen(),
        5 => const ReportsScreen(),
        6 => const EvaluationsScreen(),
        7 => const NotificationsScreen(),
        8 => const SystemMonitoringScreen(),
        9 => const UserManagementScreen(),
        10 => const SettingsScreen(),
        11 => const AdminProfileScreen(),
        _ => const _CommandCenter(),
      };
}

// ─── Top bar ──────────────────────────────────────────────────────────────────
class _TopBar extends ConsumerWidget {
  final String title;
  final bool showMenu;
  const _TopBar({required this.title, this.showMenu = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(adminNameProvider);
    final demo = ref.watch(usingDemoDataProvider);
    final narrow = MediaQuery.sizeOf(context).width < 720;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: narrow ? 16 : 28, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showMenu)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, size: 22),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                tooltip: 'Menu',
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                Text('AgriSmartAI · New Bataan',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.caption)),
              ],
            ),
          ),
          if (demo)
            _Chip('DEMO', AppColors.warning),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.caption, size: 20),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(reportProvider.notifier).refresh();
              ref.invalidate(activityProvider);
              ref.invalidate(farmerProvider);
              ref.invalidate(diseaseStatsProvider);
              ref.invalidate(evaluationsProvider);
            },
          ),
          if (!narrow) ...[
            SizedBox(
              width: 200,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  isDense: true,
                ),
                onChanged: (v) =>
                    ref.read(globalSearchProvider.notifier).state =
                        v.trim(),
              ),
            ),
            const SizedBox(width: 12),
          ],
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'A',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
          ),
          if (!narrow) ...[
            const SizedBox(width: 8),
            Text(name,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink)),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    );
  }
}

// ─── Command center (overview) ────────────────────────────────────────────────
class _CommandCenter extends ConsumerWidget {
  const _CommandCenter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpi = ref.watch(kpiProvider);
    final statsAsync = ref.watch(diseaseStatsProvider);
    final reportsAsync = ref.watch(reportProvider);
    final activitiesAsync = ref.watch(activityProvider);
    final reports = reportsAsync.value ?? const <ReportModel>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero banner
          _HeroBanner(kpi: kpi),
          const SizedBox(height: 20),
          // KPI grid
          _KpiGrid(kpi: kpi),
          const SizedBox(height: 20),
          // Charts
          _ChartRow(statsAsync: statsAsync, reports: reports),
          const SizedBox(height: 20),
          // Bottom row: recent activities + recent reports
          _BottomRow(
              activitiesAsync: activitiesAsync, reports: reports),
        ],
      ),
    );
  }
}

// ─── Hero banner ──────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final Map<String, num> kpi;
  const _HeroBanner({required this.kpi});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: DashboardTheme.heroGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepGreen.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('AGRISMARTAI 2.0',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5)),
                ),
                const SizedBox(height: 14),
                const Text('Agricultural Command Center',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  '${kpi['farmers']} farmers · ${kpi['scans']} AI detections · New Bataan, Davao de Oro',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.80),
                      fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _HeroChip(
                        '${kpi['healthy_pct']}% Healthy', AppColors.aiAccent),
                    const SizedBox(width: 8),
                    _HeroChip(
                        '${kpi['accuracy']}% Accuracy', AppColors.warmGold),
                    const SizedBox(width: 8),
                    _HeroChip('${kpi['uptime']}% Uptime', Colors.white70),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(Icons.hub_outlined,
              color: Colors.white.withValues(alpha: 0.15),
              size: 80),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;
  final Color color;
  const _HeroChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ─── KPI grid ─────────────────────────────────────────────────────────────────
class _KpiGrid extends StatelessWidget {
  final Map<String, num> kpi;
  const _KpiGrid({required this.kpi});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final cols = c.maxWidth > 1200 ? 4 : c.maxWidth > 700 ? 3 : 2;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.65,
        children: [
          StatsCard(
              icon: Icons.people_outline,
              label: 'Total Farmers',
              value: '${kpi['farmers']}',
              color: AppColors.deepGreen),
          StatsCard(
              icon: Icons.document_scanner_outlined,
              label: 'AI Scans',
              value: '${kpi['scans']}',
              color: AppColors.primary),
          StatsCard(
              icon: Icons.eco_outlined,
              label: 'Healthy Crop %',
              value: '${kpi['healthy_pct']}%',
              color: AppColors.success),
          StatsCard(
              icon: Icons.coronavirus_outlined,
              label: 'Disease Cases',
              value: '${kpi['diseased']}',
              color: AppColors.danger),
          StatsCard(
              icon: Icons.analytics_outlined,
              label: 'Detection Accuracy',
              value: '${kpi['accuracy']}%',
              color: AppColors.info,
              trend: 'Target 85%+'),
          StatsCard(
              icon: Icons.groups_outlined,
              label: 'Monthly Active',
              value: '${kpi['mau']}',
              color: AppColors.purple),
          StatsCard(
              icon: Icons.psychology_outlined,
              label: 'AI Accuracy',
              value: '${kpi['ai_accuracy']}%',
              color: AppColors.primary),
          StatsCard(
              icon: Icons.cloud_done_outlined,
              label: 'System Uptime',
              value: '${kpi['uptime']}%',
              color: AppColors.success,
              trend: 'Live'),
        ],
      );
    });
  }
}

// ─── Charts row ───────────────────────────────────────────────────────────────
class _ChartRow extends StatelessWidget {
  final AsyncValue<List<DiseaseStat>> statsAsync;
  final List<ReportModel> reports;
  const _ChartRow({required this.statsAsync, required this.reports});

  List<DiseaseStat> get _stats {
    return statsAsync.maybeWhen(
      data: (v) =>
          v.isNotEmpty ? v : _fromReports(reports),
      orElse: () => _fromReports(reports),
    );
  }

  List<DiseaseStat> _fromReports(List<ReportModel> r) {
    const names = {
      'bacterial_leaf_blight': 'Bact. Leaf Blight',
      'rice_blast': 'Rice Blast',
      'tungro': 'Tungro',
      'healthy': 'Healthy',
    };
    final buckets = <String, List<double>>{};
    for (final x in r) {
      buckets.putIfAbsent(x.diseaseCode, () => []).add(x.confidence);
    }
    return names.entries.map((e) {
      final vals = buckets[e.key] ?? [];
      final avg = vals.isEmpty
          ? 0.0
          : vals.reduce((a, b) => a + b) / vals.length;
      return DiseaseStat(
          code: e.key,
          name: e.value,
          count: vals.length,
          avgConfidence: double.parse(avg.toStringAsFixed(1)));
    }).where((s) => s.count > 0).toList();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return LayoutBuilder(builder: (_, c) {
      final wide = c.maxWidth > 900;
      final bar = _ChartCard(
        title: 'Disease Distribution',
        subtitle: 'Detections by type',
        height: 260,
        child: DiseaseBarChart(stats: stats),
      );
      final pie = _ChartCard(
        title: 'Crop Health Share',
        subtitle: 'Percentage by category',
        height: 260,
        child: DiseasePieChart(stats: stats),
      );
      return wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: bar),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: pie),
            ])
          : Column(
              children: [bar, const SizedBox(height: 12), pie]);
    });
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double height;
  final Widget child;
  const _ChartCard(
      {required this.title,
      this.subtitle,
      required this.height,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: DashboardTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.ink)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.caption)),
          ],
          const SizedBox(height: 16),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}

// ─── Bottom row ───────────────────────────────────────────────────────────────
class _BottomRow extends StatelessWidget {
  final AsyncValue<List<ActivityEntry>> activitiesAsync;
  final List<ReportModel> reports;
  const _BottomRow(
      {required this.activitiesAsync, required this.reports});

  @override
  Widget build(BuildContext context) {
    final recent = [...reports]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return LayoutBuilder(builder: (_, c) {
      final wide = c.maxWidth > 900;
      final activityCard = _SectionCard(
        title: 'Recent Activity',
        child: activitiesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2)),
          ),
          error: (_, __) => const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Unable to load activity.',
                style: TextStyle(color: AppColors.caption)),
          ),
          data: (items) => items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No recent activity.',
                      style: TextStyle(color: AppColors.caption)),
                )
              : Column(
                  children: [
                    for (final a in items.take(6)) _ActivityRow(a: a),
                  ],
                ),
        ),
      );

      final reportsCard = _SectionCard(
        title: 'Recent Detections',
        child: recent.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No detections yet.',
                    style: TextStyle(color: AppColors.caption)))
            : Column(
                children: [
                  for (final r in recent.take(6))
                    _DetectionRow(r: r),
                ],
              ),
      );

      return wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: activityCard),
              const SizedBox(width: 12),
              Expanded(child: reportsCard),
            ])
          : Column(children: [
              activityCard,
              const SizedBox(height: 12),
              reportsCard,
            ]);
    });
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: DashboardTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.ink)),
          ),
          const Divider(height: 1, color: AppColors.border),
          child,
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ActivityEntry a;
  const _ActivityRow({required this.a});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.info.withValues(alpha: 0.10),
        child: const Icon(Icons.history_toggle_off,
            color: AppColors.info, size: 15),
      ),
      title: Text(a.action.replaceAll('_', ' '),
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500)),
      subtitle: Text(
          '${a.actorName} · ${DateFormat('MMM d, h:mm a').format(a.createdAt)}',
          style: const TextStyle(fontSize: 11, color: AppColors.caption)),
    );
  }
}

class _DetectionRow extends StatelessWidget {
  final ReportModel r;
  const _DetectionRow({required this.r});

  @override
  Widget build(BuildContext context) {
    final color = diseaseColor(r.diseaseCode);
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(Icons.eco, color: color, size: 15),
      ),
      title: Text(r.diseaseName,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text('${r.farmerName} · ${r.barangay}',
          style: const TextStyle(
              fontSize: 11, color: AppColors.caption)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${r.confidence}%',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
          Text(DateFormat('MMM d').format(r.createdAt),
              style: const TextStyle(
                  fontSize: 10, color: AppColors.caption)),
        ],
      ),
    );
  }
}
