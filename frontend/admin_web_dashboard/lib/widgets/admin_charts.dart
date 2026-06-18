import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DiseasePieChart extends StatelessWidget {
  final Map<String, int> data;

  const DiseasePieChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(child: Text('No data yet', style: AppTheme.body));
    }

    final entries = data.entries.toList();
    final total = entries.fold<int>(0, (s, e) => s + e.value);

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 48,
        sections: List.generate(entries.length, (i) {
          final e = entries[i];
          final color = AppTheme.diseaseColor(e.key);
          return PieChartSectionData(
            value: e.value.toDouble(),
            title: '${((e.value / total) * 100).toStringAsFixed(0)}%',
            color: color,
            radius: 56,
            titleStyle: AppTheme.button.copyWith(
              color: Colors.white,
              fontSize: 12,
            ),
          );
        }),
      ),
    );
  }
}

class MonthlyBarChart extends StatelessWidget {
  final Map<String, int> data;

  const MonthlyBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(child: Text('No data yet', style: AppTheme.body));
    }

    final sorted = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxY = sorted.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxY + 2).toDouble(),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= sorted.length) return const SizedBox.shrink();
                final label = sorted[i].key.split('-').last;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(label, style: AppTheme.body.copyWith(fontSize: 11)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(sorted.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: sorted[i].value.toDouble(),
                color: AppTheme.primary,
                width: 22,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class BarangayBarChart extends StatelessWidget {
  final Map<String, int> data;

  const BarangayBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(child: Text('No data yet', style: AppTheme.body));
    }

    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();
    final maxY = top.first.value;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxY + 2).toDouble(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= top.length) return const SizedBox.shrink();
                final name = top[i].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    name.length > 8 ? '${name.substring(0, 6)}…' : name,
                    style: AppTheme.body.copyWith(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(top.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: top[i].value.toDouble(),
                color: AppTheme.diseaseColor(top[i].key),
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class DiseaseTrendLineChart extends StatelessWidget {
  final Map<String, int> data;

  const DiseaseTrendLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(child: Text('No data yet', style: AppTheme.body));
    }

    final sorted = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxY = sorted.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: (maxY + 2).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= sorted.length) return const SizedBox.shrink();
                return Text(
                  sorted[i].key.split('-').last,
                  style: AppTheme.body.copyWith(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              sorted.length,
              (i) => FlSpot(i.toDouble(), sorted[i].value.toDouble()),
            ),
            isCurved: true,
            color: AppTheme.accent,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.accent.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final double height;

  const ChartCard({
    super.key,
    required this.title,
    required this.child,
    this.height = 260,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.heading2),
          const SizedBox(height: 20),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}
