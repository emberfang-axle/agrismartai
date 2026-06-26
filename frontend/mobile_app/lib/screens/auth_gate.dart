import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import 'login_screen.dart';
import 'main_shell.dart';

/// Restores session on web/mobile, then routes to login or main app.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      if (AppConfig.isSupabaseConfigured) {
        await SupabaseService.init();
      }
      await ref.read(authProvider.notifier).bootstrap()
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
    if (mounted) setState(() => _bootstrapped = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_bootstrapped) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.deepGreen),
              const SizedBox(height: 16),
              Text(AppConfig.appName,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              const Text('Loading your session...',
                  style: TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      );
    }

    final auth = ref.watch(authProvider);
    if (auth.status == AuthStatus.authenticated) {
      return const MainShell();
    }
    return const LoginScreen();
  }
}
