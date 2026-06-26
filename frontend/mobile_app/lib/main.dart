import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_gate.dart';
import 'screens/camera_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/da_locator_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/result_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/weather_screen.dart';
import 'services/postgresql_service.dart';
import 'utils/constants.dart';

void main() {
  bootstrapApp();
  runApp(const ProviderScope(child: AgriSmartApp()));
}

class AgriSmartApp extends ConsumerStatefulWidget {
  const AgriSmartApp({super.key});

  @override
  ConsumerState<AgriSmartApp> createState() => _AgriSmartAppState();
}

class _AgriSmartAppState extends ConsumerState<AgriSmartApp> {
  @override
  void initState() {
    super.initState();
    PostgreSQLService.instance.init();
  }

  static Widget _pageFor(String? name) {
    switch (name) {
      case WeatherScreen.route:
        return const WeatherScreen();
      case SettingsScreen.route:
        return const SettingsScreen();
      case LoginScreen.route:
        return const LoginScreen();
      case RegisterScreen.route:
        return const RegisterScreen();
      case MainShell.route:
        return const MainShell();
      case HomeScreen.route:
        return const HomeScreen();
      case CameraScreen.route:
        return const CameraScreen();
      case LoadingScreen.route:
        return const LoadingScreen();
      case ResultScreen.route:
        return const ResultScreen();
      case HistoryScreen.route:
        return const HistoryScreen();
      case ChatbotScreen.route:
        return const ChatbotScreen();
      case DaLocatorScreen.route:
        return const DaLocatorScreen();
      case ProfileScreen.route:
        return const ProfileScreen();
      default:
        return const AuthGate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      // Branded splash → login (capstone demo).
      home: const SplashScreen(),
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
        settings: settings,
        pageBuilder: (_, __, ___) => _pageFor(settings.name),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.03, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
