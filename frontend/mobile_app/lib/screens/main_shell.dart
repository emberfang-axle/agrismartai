import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';
import 'camera_screen.dart';
import 'chatbot_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Material 3 floating bottom navigation — Home · Scan · Assistant · History · Profile.
class MainShell extends StatefulWidget {
  static const route = '/shell';
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _nav = 0;

  int get _pageIndex => switch (_nav) {
        0 => 0,
        2 => 1,
        3 => 2,
        4 => 3,
        _ => 0,
      };

  static const _pages = [
    HomeScreen(showAppBar: false),
    ChatbotScreen(showAppBar: false),
    HistoryScreen(showAppBar: false),
    ProfileScreen(showAppBar: false),
  ];

  void _onNav(int index) {
    HapticFeedback.lightImpact();
    if (index == 1) {
      Navigator.pushNamed(context, CameraScreen.route);
      return;
    }
    setState(() => _nav = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _pageIndex, children: _pages),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard.withValues(alpha: 0.95) : AppColors.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark
                ? AppColors.secondary.withValues(alpha: 0.2)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            height: 68,
            elevation: 0,
            backgroundColor: Colors.transparent,
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            selectedIndex: _nav,
            onDestinationSelected: _onNav,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              _dest(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _dest(1, Icons.document_scanner_outlined, Icons.document_scanner, 'Scan'),
              _dest(2, Icons.smart_toy_outlined, Icons.smart_toy_rounded, 'Assistant'),
              _dest(3, Icons.history_outlined, Icons.history_rounded, 'History'),
              _dest(4, Icons.person_outline, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  NavigationDestination _dest(
      int i, IconData icon, IconData active, String label) {
    final selected = _nav == i;
    return NavigationDestination(
      icon: Icon(icon, color: selected ? AppColors.primary : AppColors.muted),
      selectedIcon:
          Icon(active, color: AppColors.primary),
      label: label,
    );
  }
}
