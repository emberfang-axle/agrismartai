import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/branding/app_brand.dart';
import '../../../shared/branding/app_logo.dart';
import '../../../shared/widgets/app_card.dart';
import '../../auth/presentation/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'Connecting to Supabase...';
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final hasSession = Supabase.instance.client.auth.currentSession != null;
    if (mounted) {
      setState(() {
        _connected = hasSession;
        _status = hasSession ? 'Session found ✓' : 'Ready — sign in to continue';
      });
    }
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      Navigator.of(context).pushReplacement(slideFadeRoute(const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppBrand.heroGradient),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 120, animate: true),
              const SizedBox(height: 28),
              Text(AppBrand.name, style: AppBrand.heading1.copyWith(color: AppBrand.secondary, fontSize: 32))
                  .animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
              const SizedBox(height: 8),
              Text(AppBrand.tagline, style: AppBrand.body.copyWith(color: Colors.white70))
                  .animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 48),
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white70)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_connected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(_status, style: AppBrand.body.copyWith(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
