import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config.dart';

/// AgriSmartAI entry — safe Supabase init, visible loading, error screen on failure.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true;
  };

  runApp(const ProviderScope(child: BootstrapApp()));
}

/// Shows loading immediately, then Supabase init, then the real app or an error.
class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  _BootState _state = _BootState.loading;
  String? _error;
  String _status = 'Starting AgriSmartAI...';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      setState(() => _status = 'Checking configuration...');
      AppConfig.validate();

      setState(() => _status = 'Connecting to Supabase...');
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      if (!mounted) return;
      setState(() {
        _state = _BootState.ready;
        _status = 'Ready';
      });
    } catch (e, st) {
      debugPrint('Bootstrap failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _state = _BootState.error;
        _error = e.toString();
        _status = 'Startup failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriSmartAI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B3B1F),
          primary: const Color(0xFF0B3B1F),
          secondary: const Color(0xFFD4A017),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF9F6),
      ),
      home: switch (_state) {
        _BootState.loading => _LoadingScreen(status: _status),
        _BootState.error => _ErrorScreen(
            message: _error ?? 'Unknown startup error',
            onRetry: () {
              setState(() {
                _state = _BootState.loading;
                _error = null;
                _status = 'Retrying...';
              });
              _initialize();
            },
          ),
        _BootState.ready => const AgriSmartApp(),
      },
    );
  }
}

enum _BootState { loading, error, ready }

class _LoadingScreen extends StatelessWidget {
  final String status;
  const _LoadingScreen({required this.status});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B3B1F), Color(0xFF1B5E20), Color(0xFF2E7D32)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.eco_rounded, size: 56, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'AgriSmartAI',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4A017),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Smart Farming, Better Harvest',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(status, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Color(0xFFC62828)),
              const SizedBox(height: 16),
              const Text(
                'AgriSmartAI could not start',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: SelectableText(
                  message,
                  style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0B3B1F),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
