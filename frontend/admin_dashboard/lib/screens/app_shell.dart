import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

/// Routes between login and dashboard. Supabase init runs in background.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(appBootProvider.future));
  }

  @override
  Widget build(BuildContext context) {
    final boot = ref.watch(appBootProvider);
    return boot.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _authGate(),
      data: (_) => _authGate(),
    );
  }

  Widget _authGate() {
    final isAuthed = ref.watch(adminAuthProvider);
    return isAuthed ? const DashboardScreen() : const LoginScreen();
  }
}
