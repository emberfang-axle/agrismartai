import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/evaluation_model.dart';
import '../providers/report_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_ui.dart';

/// Farmer satisfaction ratings (OBJECTIVE 4).
class EvaluationsScreen extends ConsumerWidget {
  const EvaluationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evaluationsAsync = ref.watch(evaluationsProvider);

    return evaluationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: AdminUi.emptyState(
          icon: Icons.star_outline,
          title: 'Could not load evaluations',
          message: 'Tap refresh in the top bar to try again.',
        ),
      ),
      data: (items) {
        final avg = items.isEmpty
            ? 0.0
            : items.map((e) => e.rating).reduce((a, b) => a + b) / items.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminUi.pageHeader(
                title: 'Farmer Evaluations',
                subtitle: 'Feedback on detection accuracy and usability',
              ),
              const SizedBox(height: 20),
              if (items.isNotEmpty)
                Row(
                  children: [
                    AdminUi.surfaceCard(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          Text(avg.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink)),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AdminUi.starRating(avg.round()),
                              Text('${items.length} reviews',
                                  style: const TextStyle(
                                      color: AppColors.muted, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              if (items.isEmpty)
                AdminUi.emptyState(
                  icon: Icons.rate_review_outlined,
                  title: 'No evaluations yet',
                  message: 'Farmers can rate the app from their Profile screen.',
                )
              else
                AdminUi.surfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 20, endIndent: 20),
                        _EvaluationTile(e: items[i]),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EvaluationTile extends StatelessWidget {
  final EvaluationModel e;
  const _EvaluationTile({required this.e});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.warmGold.withValues(alpha: 0.15),
            child: Text('${e.rating}',
                style: const TextStyle(
                    color: AppColors.deepGreen, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(e.farmerName,
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    Text(DateFormat('MMM d, y').format(e.createdAt),
                        style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                AdminUi.starRating(e.rating, size: 18),
                if (e.diseaseName != null) ...[
                  const SizedBox(height: 6),
                  AdminUi.statusChip('Scan: ${e.diseaseName!}', AppColors.aiBlue),
                ],
                if (e.comment != null && e.comment!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(e.comment!,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
