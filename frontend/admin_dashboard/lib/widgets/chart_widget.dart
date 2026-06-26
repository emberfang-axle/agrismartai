import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/report_model.dart';

/// AgriSmartAI :: fl_chart widgets for the analytics dashboard (OBJECTIVE 4).

Color diseaseColor(String code) => switch (code) {
      'bacterial_leaf_blight' => AppColors.warning,
      'rice_blast' => AppColors.danger,
      'tungro' => AppColors.purple,
      _ => AppColors.success,
    };

/// Bar chart of scan counts per disease.
class DiseaseBarChart extends StatelessWidget {
  final List<DiseaseStat> stats;
  const DiseaseBarChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final maxY = stats.isEmpty
        ? 10.0
        : (stats.map((s) => s.count).reduce((a, b) => a > b ? a : b) + 2)
            .toDouble();

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= stats.length) return const SizedBox.shrink();
                final short = stats[i].name.split(' ').first;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(short,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.muted)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < stats.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: stats[i].count.toDouble(),
                  color: diseaseColor(stats[i].code),
                  width: 26,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Pie chart of disease distribution share.
class DiseasePieChart extends StatelessWidget {
  final List<DiseaseStat> stats;
  const DiseasePieChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.fold<int>(0, (sum, s) => sum + s.count);
    final visible = stats.where((s) => s.count > 0).toList();

    if (total == 0) {
      return const Center(
        child: Text('No data yet', style: TextStyle(color: AppColors.muted)),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 36,
              sectionsSpace: 2,
              sections: [
                for (final s in visible)
                  PieChartSectionData(
                    value: s.count.toDouble(),
                    title: '${((s.count / total) * 100).round()}%',
                    color: diseaseColor(s.code),
                    radius: 58,
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in visible)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: diseaseColor(s.code),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('${s.name} (${s.count})',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.ink)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Line chart of monthly scan volume (last 6 months).
class MonthlyScanChart extends StatelessWidget {
  final List<ReportModel> reports;
  const MonthlyScanChart({super.key, required this.reports});

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  List<(String, int)> _buckets() {
    final now = DateTime.now();
    final out = <(String, int)>[];
    for (var i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final count = reports
          .where((r) =>
              r.createdAt.year == d.year && r.createdAt.month == d.month)
          .length;
      out.add((_months[d.month - 1], count));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final data = _buckets();
    if (reports.isEmpty) {
      return const Center(
        child: Text('No scan data yet', style: TextStyle(color: AppColors.muted)),
      );
    }
    final maxY = (data.map((e) => e.$2).reduce((a, b) => a > b ? a : b) + 2)
        .toDouble()
        .clamp(4.0, 999.0);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY.toDouble(),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(data[i].$1,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.muted)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < data.length; i++)
                FlSpot(i.toDouble(), data[i].$2.toDouble()),
            ],
            isCurved: true,
            color: AppColors.aiBlue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.aiBlue.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
