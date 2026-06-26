import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/report_provider.dart';
import '../theme/app_theme.dart';

/// Full activity audit trail for admin monitoring (OBJECTIVE 4).
class ActivityLogsScreen extends ConsumerWidget {
  const ActivityLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activityProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activityProvider);
        await ref.read(activityProvider.future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activity Logs',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('System audit trail — logins, scans, verifications',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.muted)),
            const SizedBox(height: 20),
            Card(
              child: activitiesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: CircularProgressIndicator(color: AppColors.aiBlue)),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: $e',
                      style: const TextStyle(color: AppColors.danger)),
                ),
                data: (items) => items.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No activity recorded yet.',
                            style: TextStyle(color: AppColors.muted)),
                      )
                    : Column(
                        children: [
                          for (final a in items)
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.aiBlueLight,
                                child: Icon(
                                  _iconFor(a.action),
                                  color: AppColors.aiBlue,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                a.action.replaceAll('_', ' ').toUpperCase(),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              subtitle: Text(
                                '${a.actorName}\n${a.detail}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                DateFormat('MMM d, h:mm a').format(a.createdAt),
                                style: const TextStyle(
                                    color: AppColors.muted, fontSize: 11),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String action) => switch (action) {
        'report_verified' => Icons.verified_outlined,
        'report_rejected' => Icons.cancel_outlined,
        'api_detection' || 'scan_completed' => Icons.qr_code_scanner,
        'chat_message' => Icons.chat_bubble_outline,
        _ => Icons.history,
      };
}
