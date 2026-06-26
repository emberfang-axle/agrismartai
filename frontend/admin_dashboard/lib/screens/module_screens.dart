import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/report_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_ui.dart';

/// Enterprise module screens for AGRISMARTAI 2.0 admin navigation.
class DiseaseDatabaseScreen extends StatelessWidget {
  const DiseaseDatabaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const diseases = [
      ('Rice Blast', 'Magnaporthe oryzae', 'High', AppColors.danger),
      ('Bacterial Leaf Blight', 'Xanthomonas oryzae', 'High', AppColors.warning),
      ('Rice Tungro', 'Rice tungro bacilliform & spherical virus', 'Severe', AppColors.danger),
      ('Healthy Rice Leaf', 'Oryza sativa', 'None', AppColors.success),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminUi.pageHeader(
            title: 'Rice Disease Database',
            subtitle: 'Reference knowledge base for AI classification and farmer guidance',
          ),
          const SizedBox(height: 24),
          ...diseases.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AdminUi.glassCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: d.$4.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.biotech_outlined, color: d.$4),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.$1,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: AppColors.ink)),
                            Text(d.$2,
                                style: const TextStyle(
                                    color: AppColors.muted, fontSize: 13)),
                          ],
                        ),
                      ),
                      AdminUi.statusChip(d.$3, d.$4),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class AiMonitoringScreen extends ConsumerWidget {
  const AiMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpi = ref.watch(kpiProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminUi.pageHeader(
            title: 'AI Model Monitoring',
            subtitle: 'MobileNetV2 simulation — capstone defense metrics',
          ),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, c) {
            final cross = c.maxWidth > 900 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cross,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.7,
              children: [
                AdminUi.metricTile(
                  label: 'Model Accuracy',
                  value: '${kpi['ai_accuracy']}%',
                  icon: Icons.verified_outlined,
                  color: AppColors.success,
                  trend: 'Target 85%+',
                ),
                AdminUi.metricTile(
                  label: 'Avg Confidence',
                  value: '${kpi['accuracy']}%',
                  icon: Icons.speed,
                  color: AppColors.primary,
                ),
                AdminUi.metricTile(
                  label: 'Inference Time',
                  value: '~1.2s',
                  icon: Icons.timer_outlined,
                  color: AppColors.aiBlue,
                ),
                AdminUi.metricTile(
                  label: 'Model Version',
                  value: 'v2.0',
                  icon: Icons.memory_outlined,
                  color: AppColors.purple,
                ),
              ],
            );
          }),
          const SizedBox(height: 20),
          AdminUi.glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Performance Notes',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.ink)),
                const SizedBox(height: 8),
                Text(
                  'Production deployment will connect to TensorFlow/Keras trained on New Bataan field images. '
                  'Current capstone build uses validated simulation with rice-leaf preprocessing and confidence scoring.',
                  style: TextStyle(
                      color: AppColors.muted.withValues(alpha: 0.9),
                      height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notifications: real data from activity_logs ───────────────────────────────

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Color _colorFor(String action) {
    if (action.contains('scan') || action.contains('detection')) return AppColors.danger;
    if (action.contains('register') || action.contains('login')) return AppColors.primary;
    if (action.contains('verified') || action.contains('approved')) return AppColors.success;
    return AppColors.aiBlue;
  }

  String _labelFor(String action) => switch (action) {
        'scan_completed' => 'Scan Completed',
        'api_detection' => 'AI Detection',
        'user_registered' => 'New Farmer Registered',
        'user_login' => 'User Login',
        'report_verified' => 'Report Verified',
        'report_rejected' => 'Report Rejected',
        'chat_message' => 'Chat Message',
        'admin_login' => 'Admin Login',
        _ => action.replaceAll('_', ' '),
      };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activityProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminUi.pageHeader(
            title: 'Notifications',
            subtitle: 'Platform alerts, disease warnings, and system events',
          ),
          const SizedBox(height: 24),
          activitiesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => AdminUi.emptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load notifications',
              message: 'Check your connection and tap refresh in the top bar.',
            ),
            data: (items) {
              if (items.isEmpty) {
                return AdminUi.emptyState(
                  icon: Icons.notifications_none_outlined,
                  title: 'No notifications yet',
                  message: 'Activity events will appear here as farmers use the app.',
                );
              }
              return Column(
                children: items
                    .map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AdminUi.surfaceCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.notifications_active_outlined,
                                    color: _colorFor(a.action), size: 22),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_labelFor(a.action),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.ink)),
                                      Text(
                                        '${a.actorName}${a.detail.isNotEmpty ? ' · ${a.detail}' : ''}',
                                        style: const TextStyle(
                                            color: AppColors.muted, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _timeAgo(a.createdAt),
                                  style: const TextStyle(
                                      color: AppColors.muted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SystemMonitoringScreen extends ConsumerWidget {
  const SystemMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpi = ref.watch(kpiProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminUi.pageHeader(
            title: 'System Monitoring',
            subtitle: 'Platform health, uptime, and operational status',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: AdminUi.metricTile(
                  label: 'System Uptime',
                  value: '${kpi['uptime']}%',
                  icon: Icons.cloud_done_outlined,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AdminUi.metricTile(
                  label: 'Pending Reports',
                  value: '${kpi['pending']}',
                  icon: Icons.pending_actions_outlined,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AdminUi.glassCard(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Services Status',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.ink)),
                SizedBox(height: 12),
                _ServiceRow('FastAPI Backend', 'Online', AppColors.success),
                _ServiceRow('PostgreSQL Database', 'Connected', AppColors.success),
                _ServiceRow('AI Inference', 'Simulated', AppColors.primary),
                _ServiceRow('Storage', 'Ready', AppColors.success),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── User Management: farmers from PostgreSQL backend ───────────────────────────

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmersAsync = ref.watch(farmerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminUi.pageHeader(
            title: 'User Management',
            subtitle: 'Registered farmers and staff accounts',
          ),
          const SizedBox(height: 24),
          // Staff accounts (static — seeded in PostgreSQL)
          AdminUi.glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Staff Accounts',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.ink)),
                const SizedBox(height: 12),
                _userRow('Administrator', 'admin@agrismartai.ph', 'admin', AppColors.primaryDark),
                const Divider(height: 20),
                _userRow('Field Technician', 'tech@agrismartai.ph', 'technician', AppColors.aiBlue),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Registered farmers from backend
          farmersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => AdminUi.emptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load users',
              message: 'Check your connection and tap refresh.',
            ),
            data: (farmers) {
              if (farmers.isEmpty) {
                return AdminUi.emptyState(
                  icon: Icons.people_outline,
                  title: 'No registered farmers yet',
                  message: 'Farmers will appear here after they register in the app.',
                );
              }
              return AdminUi.glassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Registered Farmers (${farmers.length})',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.ink)),
                    const SizedBox(height: 12),
                    ...farmers.map((f) => Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.deepGreen,
                                  child: Text(
                                    f.fullName.isNotEmpty ? f.fullName[0].toUpperCase() : 'F',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(f.fullName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.ink)),
                                      Text('${f.email} · ${f.barangay}',
                                          style: const TextStyle(
                                              color: AppColors.muted, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    AdminUi.statusChip('farmer', AppColors.success),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Joined ${DateFormat('MMM d, y').format(f.joinedAt)}',
                                      style: const TextStyle(
                                          color: AppColors.muted, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (f != farmers.last) const Divider(height: 20),
                          ],
                        )),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _userRow(String name, String email, String role, Color color) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(name[0],
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.ink)),
              Text(email,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ],
          ),
        ),
        AdminUi.statusChip(role, color),
      ],
    );
  }
}

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminUi.pageHeader(
            title: 'Admin Profile',
            subtitle: 'Account information and preferences',
          ),
          const SizedBox(height: 24),
          AdminUi.glassCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primaryLight,
                  child: const Icon(Icons.person, color: AppColors.primaryDark, size: 36),
                ),
                const SizedBox(width: 20),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AgriSmartAI Administrator',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppColors.ink)),
                      SizedBox(height: 4),
                      Text('admin@agrismartai.ph',
                          style: TextStyle(color: AppColors.muted)),
                      SizedBox(height: 4),
                      Text('New Bataan Municipal Agriculture Office',
                          style: TextStyle(color: AppColors.muted, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final String name;
  final String status;
  final Color color;
  const _ServiceRow(this.name, this.status, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: const TextStyle(color: AppColors.ink))),
          Text(status,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
