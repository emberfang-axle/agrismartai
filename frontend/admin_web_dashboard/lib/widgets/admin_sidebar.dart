import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  final bool collapsed;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
    this.collapsed = false,
  });

  static const _items = [
    (Icons.dashboard_rounded, 'Dashboard'),
    (Icons.assignment_rounded, 'Reports'),
    (Icons.people_rounded, 'Farmers'),
    (Icons.bar_chart_rounded, 'Analytics'),
    (Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: collapsed ? 72 : 260,
      decoration: const BoxDecoration(color: AppTheme.sidebarBg),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 12 : 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.eco_rounded, color: AppTheme.secondary),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AgriSmartAI',
                          style: AppTheme.button.copyWith(
                            color: AppTheme.secondary,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'DA Admin',
                          style: AppTheme.body.copyWith(
                            color: AppTheme.textOnDark.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          ...List.generate(_items.length, (i) {
            final (icon, label) = _items[i];
            final selected = selectedIndex == i;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Material(
                color: selected
                    ? AppTheme.accent.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelect(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          color: selected ? AppTheme.secondary : AppTheme.textOnDark.withValues(alpha: 0.7),
                          size: 22,
                        ),
                        if (!collapsed) ...[
                          const SizedBox(width: 14),
                          Text(
                            label,
                            style: AppTheme.button.copyWith(
                              color: selected
                                  ? Colors.white
                                  : AppTheme.textOnDark.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'New Bataan • Batinao',
                style: AppTheme.body.copyWith(
                  color: AppTheme.textOnDark.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              leading: Icon(
                Icons.logout_rounded,
                color: Colors.red.shade300,
                size: 22,
              ),
              title: collapsed
                  ? null
                  : Text(
                      'Logout',
                      style: AppTheme.button.copyWith(
                        color: Colors.red.shade300,
                        fontSize: 14,
                      ),
                    ),
              onTap: onLogout,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
