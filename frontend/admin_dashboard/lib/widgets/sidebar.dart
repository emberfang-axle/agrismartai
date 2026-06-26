import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/agri_smart_logo.dart';
import '../widgets/logout_dialog.dart';
import '../providers/report_provider.dart';

/// AGRISMARTAI 2.0 enterprise sidebar navigation.
class Sidebar extends ConsumerWidget {
  const Sidebar({super.key, this.inDrawer = false, this.onNavigate});

  final bool inDrawer;
  final VoidCallback? onNavigate;

  static const _sections = [
    (
      title: 'CORE',
      items: [
        (0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
        (1, Icons.people_outline, Icons.people_rounded, 'Farmers'),
        (2, Icons.document_scanner_outlined, Icons.document_scanner, 'Detections'),
      ],
    ),
    (
      title: 'INTELLIGENCE',
      items: [
        (3, Icons.coronavirus_outlined, Icons.coronavirus, 'Disease Database'),
        (4, Icons.insights_outlined, Icons.insights, 'AI Analytics'),
        (5, Icons.assignment_outlined, Icons.assignment_rounded, 'Reports'),
      ],
    ),
    (
      title: 'OPERATIONS',
      items: [
        (6, Icons.rate_review_outlined, Icons.rate_review, 'Feedback'),
        (7, Icons.notifications_outlined, Icons.notifications, 'Notifications'),
        (8, Icons.monitor_heart_outlined, Icons.monitor_heart, 'Monitoring'),
      ],
    ),
    (
      title: 'SYSTEM',
      items: [
        (9, Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, 'Users'),
        (10, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
        (11, Icons.person_outline, Icons.person_rounded, 'Profile'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(navIndexProvider);

    final content = Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: const AgriSmartLogo(size: 44),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final section in _sections) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                    child: Text(section.title,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.muted)),
                  ),
                  for (final item in section.items)
                    _navItem(ref, selected, item.$1, item.$2, item.$3, item.$4),
                ],
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: AppColors.border),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.logout_rounded, color: AppColors.muted, size: 20),
            title: const Text('Logout',
                style: TextStyle(fontSize: 14, color: AppColors.muted)),
            onTap: () async {
              final ok = await AdminLogoutDialog.show(context);
              if (ok) ref.read(adminAuthProvider.notifier).signOut();
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Text('New Bataan • Davao de Oro',
                style: TextStyle(
                    fontSize: 10, color: AppColors.muted.withValues(alpha: 0.8))),
          ),
        ],
      ),
    );

    if (inDrawer) return SafeArea(child: content);

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(child: content),
    );
  }

  Widget _navItem(WidgetRef ref, int selected, int index, IconData icon,
      IconData activeIcon, String label) {
    final active = selected == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: Material(
        color: active ? AppColors.primaryLight.withValues(alpha: 0.7) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            ref.read(navIndexProvider.notifier).state = index;
            onNavigate?.call();
          },
          child: Container(
            decoration: active
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(color: AppColors.accent, width: 3),
                    ),
                  )
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(active ? activeIcon : icon,
                    color: active ? AppColors.primaryDark : AppColors.muted,
                    size: 20),
                const SizedBox(width: 12),
                Text(label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      color: active ? AppColors.primaryDark : AppColors.muted,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
