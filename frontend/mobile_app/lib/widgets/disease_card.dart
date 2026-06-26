import 'package:flutter/material.dart';

import '../models/scan_model.dart';
import '../utils/constants.dart';

/// AgriSmartAI :: Disease detail card (symptoms / treatment / fertilizer).
/// OBJECTIVE 3: surfaces the fertilizer recommendation to the farmer.
class DiseaseCard extends StatelessWidget {
  final DiseaseInfo info;

  const DiseaseCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final color = DiseaseData.byCode(info.code).color;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.coronavirus_outlined, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(info.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      if (info.scientificName.isNotEmpty)
                        Text(info.scientificName,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.muted)),
                    ],
                  ),
                ),
                _SeverityChip(severity: info.severity, color: color),
              ],
            ),
            if (info.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(info.description,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
            _section(context, Icons.search, 'Symptoms', info.symptoms),
            _section(context, Icons.healing, 'Treatment', info.treatment),
            _section(context, Icons.eco, 'Fertilizer Recommendation',
                info.fertilizer, highlight: true),
            _section(context, Icons.shield_outlined, 'Prevention',
                info.prevention),
          ],
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context,
    IconData icon,
    String title,
    String body, {
    bool highlight = false,
  }) {
    if (body.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlight ? AppColors.warmGold.withValues(alpha: 0.10) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 18,
                    color: highlight ? AppColors.warmGold : AppColors.leafGreen),
                const SizedBox(width: 6),
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final String severity;
  final Color color;
  const _SeverityChip({required this.severity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(severity,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
