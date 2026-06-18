import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../widgets/admin_sidebar.dart';
import 'admin_login_screen.dart';
import 'analytics_screen.dart';
import 'dashboard_screen.dart';
import 'farmers_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  Future<void> _logout() async {
    await ref.read(authServiceProvider).signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final collapsed = ref.watch(sidebarCollapsedProvider);

    final pages = const [
      DashboardScreen(),
      ReportsScreen(),
      FarmersScreen(),
      AnalyticsScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: _index,
            onSelect: (i) => setState(() => _index = i),
            onLogout: _logout,
            collapsed: collapsed,
          ),
          Expanded(child: pages[_index]),
        ],
      ),
    );
  }
}
