import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/scan_provider.dart';
import '../utils/constants.dart';
import '../utils/farming_tips.dart';
import '../widgets/agri_brand_logo.dart';
import '../widgets/app_decoration.dart';
import '../widgets/premium_ui.dart';
import 'camera_screen.dart';
import 'chatbot_screen.dart';
import 'da_locator_screen.dart';
import 'history_screen.dart';
import 'weather_screen.dart';

/// AGRISMARTAI — Premium home dashboard.
class HomeScreen extends ConsumerStatefulWidget {
  static const route = '/home';
  final bool showAppBar;
  const HomeScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _tipPage = PageController();
  int _tipIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scanProvider.notifier).loadHistory();
    });
  }

  @override
  void dispose() {
    _tipPage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final summary = ref.watch(scanSummaryProvider);
    final history = ref.watch(scanProvider).history;
    final name = (user?.fullName.split(' ').first ?? 'Farmer').trim();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary, AppColors.secondary],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, CameraScreen.route),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.document_scanner_outlined, color: Colors.white),
          label: const Text('Upload Leaf',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(scanProvider.notifier).loadHistory(),
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, widget.showAppBar ? 16 : 52, 20, 100),
          children: [
            _WelcomeCard(name: name),
            const SizedBox(height: 16),
            _AiBanner(),
            const SizedBox(height: 20),
            _StatsRow(summary: summary),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Quick Actions', subtitle: 'Tap to open'),
            const SizedBox(height: 12),
            _QuickGrid(),
            const SizedBox(height: 24),
            _CropHealthCard(summary: summary),
            const SizedBox(height: 20),
            _AiInsightsSection(summary: summary, history: history),
            const SizedBox(height: 20),
            _WeeklyChart(scans: history.length),
            const SizedBox(height: 20),
            _WeatherSummaryCard(
              onTap: () => Navigator.pushNamed(context, WeatherScreen.route),
            ),
            const SizedBox(height: 20),
            _TipsCarousel(
              controller: _tipPage,
              index: _tipIndex,
              onPage: (i) => setState(() => _tipIndex = i),
            ),
            if (history.isNotEmpty) ...[
              const SizedBox(height: 24),
              const SectionHeader(title: 'Recent Scans', subtitle: 'Timeline'),
              const SizedBox(height: 10),
              ...history.take(3).map((s) => _RecentScanTile(scan: s)),
            ],
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String name;
  const _WelcomeCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.greenGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: PremiumUi.elevation(AppColors.primaryDark, 0.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back, $name!',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  'Keep your rice crops healthy today.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.eco_rounded, color: Color(0xFFD4A017), size: 32),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }
}

class _AiBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tint: AppColors.softGreen,
      child: Row(
        children: [
          const AgriSmartLogo(size: 52, showGlow: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('AI Monitoring Active',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.ink)),
                SizedBox(height: 4),
                Text('Neural disease engine ready for field scans.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, int> summary;
  const _StatsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total Scans', '${summary['total'] ?? 0}', Icons.qr_code_scanner, AppColors.primary),
      ('Healthy', '${summary['healthy'] ?? 0}', Icons.eco_outlined, AppColors.success),
      ('Diseases', '${summary['diseased'] ?? 0}', Icons.coronavirus_outlined, AppColors.danger),
      ('Referrals', '0', Icons.account_balance_outlined, AppColors.info),
    ];
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final (label, value, icon, color) = items[i];
          return Container(
            width: 132,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
              boxShadow: PremiumUi.elevation(null, 0.05),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(value,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Text(label,
                    style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ).animate().fadeIn(delay: (i * 60).ms);
        },
      ),
    );
  }
}

class _QuickGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        PremiumActionCard(
          icon: Icons.document_scanner_outlined,
          title: 'Scan Rice Leaf',
          subtitle: 'AI detection',
          color: AppColors.primary,
          onTap: () => Navigator.pushNamed(context, CameraScreen.route),
        ),
        PremiumActionCard(
          icon: Icons.smart_toy_outlined,
          title: 'AI Assistant',
          subtitle: 'Ka-Agro chat',
          color: AppColors.info,
          onTap: () => Navigator.pushNamed(context, ChatbotScreen.route),
        ),
        PremiumActionCard(
          icon: Icons.history,
          title: 'History',
          subtitle: 'Past scans',
          color: AppColors.secondary,
          onTap: () => Navigator.pushNamed(context, HistoryScreen.route),
        ),
        PremiumActionCard(
          icon: Icons.account_balance_outlined,
          title: 'DA Offices',
          subtitle: 'Locator',
          color: AppColors.primaryDark,
          onTap: () => Navigator.pushNamed(context, DaLocatorScreen.route),
        ),
        PremiumActionCard(
          icon: Icons.wb_sunny_outlined,
          title: 'Weather',
          subtitle: 'Field forecast',
          color: AppColors.warmGold,
          onTap: () => Navigator.pushNamed(context, WeatherScreen.route),
        ),
        PremiumActionCard(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Alerts & tips',
          color: AppColors.accentLime,
          onTap: () {},
        ),
      ],
    );
  }
}

class _CropHealthCard extends StatelessWidget {
  final Map<String, int> summary;
  const _CropHealthCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final total = summary['total'] ?? 0;
    final healthy = summary['healthy'] ?? 0;
    final pct = total == 0 ? 0.0 : healthy / total;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Crop Health Overview',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0.15 : pct,
              minHeight: 10,
              backgroundColor: AppColors.border,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            total == 0
                ? 'Scan leaves to build your health profile.'
                : '${(pct * 100).toStringAsFixed(0)}% healthy across $total scans',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final int scans;
  const _WeeklyChart({required this.scans});

  @override
  Widget build(BuildContext context) {
    final data = [0.3, 0.5, 0.4, 0.7, 0.6, scans > 0 ? 0.85 : 0.2, 0.55];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Analytics',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      height: 100 * data[i],
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.35),
                            AppColors.primary,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherSummaryCard extends StatelessWidget {
  final VoidCallback onTap;
  const _WeatherSummaryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warmGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.wb_sunny_rounded,
                    color: AppColors.warmGold, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Bataan Weather',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('28°C · Partly cloudy · Good for monitoring',
                        style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.caption),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipsCarousel extends StatelessWidget {
  final PageController controller;
  final int index;
  final ValueChanged<int> onPage;
  const _TipsCarousel({
    required this.controller,
    required this.index,
    required this.onPage,
  });

  @override
  Widget build(BuildContext context) {
    final tips = [
      FarmingTips.today(),
      'Synchronize planting with neighbors to reduce pest spread.',
      'Drain fields after heavy rain to prevent bacterial blight.',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Agricultural Tips', subtitle: 'Swipe for more'),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: PageView.builder(
            controller: controller,
            onPageChanged: onPage,
            itemCount: tips.length,
            itemBuilder: (_, i) => Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.softGreen,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(tips[i],
                          style: const TextStyle(
                              fontSize: 13, height: 1.4, color: AppColors.ink))),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
              tips.length,
              (i) => Container(
                    width: i == index ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == index ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
        ),
      ],
    );
  }
}

class _RecentScanTile extends StatelessWidget {
  final dynamic scan;
  const _RecentScanTile({required this.scan});

  @override
  Widget build(BuildContext context) {
    final color = DiseaseData.byCode(scan.diseaseCode).color;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scan.diseaseName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${scan.confidence.toStringAsFixed(0)}% confidence',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI Insights Section ──────────────────────────────────────────────────────
class _AiInsightsSection extends StatelessWidget {
  final Map<String, int> summary;
  final List<dynamic> history;
  const _AiInsightsSection({required this.summary, required this.history});

  List<_Insight> _buildInsights() {
    final insights = <_Insight>[];
    final total = summary['total'] ?? 0;
    final diseased = summary['diseased'] ?? 0;
    final healthy = summary['healthy'] ?? 0;

    if (total == 0) {
      insights.add(const _Insight(
        icon: Icons.tips_and_updates_outlined,
        title: 'Start your first scan',
        body: 'Tap "Scan Leaf" to begin building your crop health profile.',
        color: AppColors.primary,
      ));
      insights.add(const _Insight(
        icon: Icons.auto_awesome_outlined,
        title: 'AI engine ready',
        body: 'MobileNetV2 is loaded and ready to detect Bacterial Leaf Blight, Rice Blast, and Tungro.',
        color: AppColors.info,
      ));
    } else {
      if (diseased > 0) {
        final pct = (diseased / total * 100).round();
        insights.add(_Insight(
          icon: Icons.warning_amber_rounded,
          title: '$pct% disease rate detected',
          body: '$diseased of your $total scans show disease. Consider contacting your DA technician.',
          color: pct > 50 ? AppColors.danger : AppColors.warning,
        ));
      }
      if (healthy > 0 && diseased == 0) {
        insights.add(const _Insight(
          icon: Icons.eco_outlined,
          title: 'Excellent crop health',
          body: 'All scans show healthy crops. Keep monitoring weekly during the growing season.',
          color: AppColors.success,
        ));
      }
      if (history.isNotEmpty) {
        final latest = history.first;
        insights.add(_Insight(
          icon: Icons.schedule_outlined,
          title: 'Latest: ${latest.diseaseName}',
          body: 'Detected with ${latest.confidence.toStringAsFixed(0)}% confidence. '
              '${latest.diseaseCode == 'healthy' ? 'No action needed.' : 'Review treatment plan.'}',
          color: DiseaseData.byCode(latest.diseaseCode).color,
        ));
      }
    }

    insights.add(const _Insight(
      icon: Icons.wb_sunny_outlined,
      title: 'Weather advisory',
      body: 'High humidity this week increases fungal disease risk. Inspect leaves daily.',
      color: AppColors.warmGold,
    ));

    return insights;
  }

  @override
  Widget build(BuildContext context) {
    final insights = _buildInsights();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'AI Insights', subtitle: 'Personalized recommendations'),
        const SizedBox(height: 10),
        ...insights.asMap().entries.map((e) => _InsightCard(
              insight: e.value,
              index: e.key,
            )),
      ],
    );
  }
}

class _Insight {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const _Insight({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
}

class _InsightCard extends StatelessWidget {
  final _Insight insight;
  final int index;
  const _InsightCard({required this.insight, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: insight.color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(insight.icon, size: 18, color: insight.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: insight.color)),
                const SizedBox(height: 4),
                Text(insight.body,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.muted, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.03, end: 0);
  }
}
