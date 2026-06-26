import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/constants.dart';

/// Animated AI confidence meter (OBJECTIVE 2: 85%+ accuracy).
class ConfidenceMeter extends StatelessWidget {
  final double confidence;
  final Color color;

  const ConfidenceMeter({
    super.key,
    required this.confidence,
    this.color = AppColors.aiBlue,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (confidence.clamp(0, 100)) / 100.0;
    final meetsTarget = confidence >= 85;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.auto_awesome, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Confidence Score',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(meetsTarget ? 'Meets 85% accuracy target' : 'Consider rescanning',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
            Text('${confidence.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    )),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Container(height: 16, color: AppColors.softGreen),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.6), color],
                    ),
                  ),
                ),
              ).animate().scaleX(
                    begin: 0,
                    end: 1,
                    alignment: Alignment.centerLeft,
                    duration: 800.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
