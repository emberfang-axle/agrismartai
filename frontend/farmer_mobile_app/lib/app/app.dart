import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/main_shell.dart';
import '../features/splash/presentation/splash_screen.dart';

class AgriSmartApp extends ConsumerWidget {
  const AgriSmartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'AgriSmartAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAF9F6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B3B1F),
          primary: const Color(0xFF0B3B1F),
          secondary: const Color(0xFFD4A017),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFAF9F6),
          foregroundColor: Color(0xFF1A1A1A),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const SplashScreen(),
      error: (e, _) => LoginScreen(bootstrapError: e.toString()),
      data: (state) {
        if (state.session != null) {
          return const MainShell();
        }
        return const LoginScreen();
      },
    );
  }
}
