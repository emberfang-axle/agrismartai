import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'providers/providers.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_shell.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught: $error\n$stack');
    return true;
  };

  runApp(const ProviderScope(child: AdminBootstrapApp()));
}

class AdminBootstrapApp extends StatefulWidget {
  const AdminBootstrapApp({super.key});

  @override
  State<AdminBootstrapApp> createState() => _AdminBootstrapAppState();
}

class _AdminBootstrapAppState extends State<AdminBootstrapApp> {
  _BootState _state = _BootState.loading;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      AppConfig.validate();
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      if (mounted) setState(() => _state = _BootState.ready);
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _BootState.error;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriSmartAI Admin',
      theme: AppTheme.theme(),
      home: switch (_state) {
        _BootState.loading => const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 16),
                  Text('Loading AgriSmartAI Admin...'),
                ],
              ),
            ),
          ),
        _BootState.error => Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    SelectableText(_error ?? 'Startup error'),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _init, child: const Text('Retry')),
                  ],
                ),
              ),
            ),
          ),
        _BootState.ready => const AdminApp(),
      },
    );
  }
}

enum _BootState { loading, error, ready }

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'AgriSmartAI — DA Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme(),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isAdminAsync = ref.watch(isAdminProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      ),
      error: (_, __) => const AdminLoginScreen(),
      data: (state) {
        if (state.session == null) return const AdminLoginScreen();

        return isAdminAsync.when(
          loading: () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          ),
          error: (_, __) => const AdminLoginScreen(),
          data: (isAdmin) => isAdmin ? const AdminShell() : const AdminLoginScreen(),
        );
      },
    );
  }
}
