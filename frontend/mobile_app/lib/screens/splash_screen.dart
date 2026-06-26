import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import '../widgets/agri_brand_logo.dart';
import 'login_screen.dart';
import 'main_shell.dart';

/// AgriSmartAI splash — logo animation, Supabase check, progress bar, auto-navigate.
class SplashScreen extends ConsumerStatefulWidget {
  static const route = '/';
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _titleCtrl;
  late final AnimationController _taglineCtrl;
  late final AnimationController _progressCtrl;

  double _progress = 0;
  bool _supabaseOk = true;
  bool _connectionChecked = false;
  bool _navigated = false;
  String _statusText = 'Initializing...';

  static const _minSplashMs = 2500;
  static const _version = 'v1.0.0';

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _titleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _taglineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..addListener(() {
        if (mounted) setState(() => _progress = _progressCtrl.value);
      });

    _startSequence();
  }

  Future<void> _startSequence() async {
    final startedAt = DateTime.now();

    // Staggered entrance animations
    await Future.delayed(const Duration(milliseconds: 100));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _titleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _taglineCtrl.forward();

    // Run bootstrap + connection check in parallel with progress bar
    _progressCtrl.forward();
    final bootstrapFuture = _bootstrap();

    await Future.wait([
      bootstrapFuture,
      Future.delayed(const Duration(milliseconds: _minSplashMs)),
    ]);

    // Ensure minimum splash duration
    final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
    if (elapsed < _minSplashMs) {
      await Future.delayed(Duration(milliseconds: _minSplashMs - elapsed));
    }

    if (!mounted || _navigated) return;

    if (!_supabaseOk && AppConfig.isSupabaseConfigured) {
      setState(() {
        _statusText = 'Connection failed — tap Retry';
        _progress = _progressCtrl.value;
      });
      return;
    }

    _navigate();
  }

  Future<void> _bootstrap() async {
    try {
      setState(() => _statusText = 'Checking Supabase connection...');

      if (AppConfig.isSupabaseConfigured) {
        _supabaseOk = await SupabaseService.checkConnection();
        if (mounted) {
          setState(() {
            _connectionChecked = true;
            _statusText = _supabaseOk
                ? 'Connected to AgriSmartAI cloud'
                : 'Connection failed';
          });
        }
        if (_supabaseOk) {
          await SupabaseService.init();
        }
      } else {
        _supabaseOk = true;
        if (mounted) {
          setState(() {
            _connectionChecked = true;
            _statusText = 'Offline demo mode';
          });
        }
      }

      setState(() => _statusText = 'Loading your session...');
      await ref
          .read(authProvider.notifier)
          .bootstrap()
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      if (AppConfig.isSupabaseConfigured) {
        _supabaseOk = false;
        if (mounted) setState(() => _statusText = 'Connection failed');
      }
    }
  }

  Future<void> _retry() async {
    setState(() {
      _supabaseOk = true;
      _connectionChecked = false;
      _statusText = 'Retrying connection...';
      _progress = 0;
    });
    _progressCtrl.reset();
    _progressCtrl.forward();
    await _bootstrap();
    if (!mounted) return;
    if (_supabaseOk) _navigate();
  }

  void _navigate() {
    if (_navigated || !mounted) return;
    _navigated = true;
    final authed = ref.read(authProvider).status == AuthStatus.authenticated;
    Navigator.pushReplacementNamed(
      context,
      authed ? MainShell.route : LoginScreen.route,
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _titleCtrl.dispose();
    _taglineCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B3B1F),
              Color(0xFF052A14),
              Color(0xFF021A0C),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const Spacer(flex: 2),
                  // Logo — fade + scale (1.0 → 1.2)
                  FadeTransition(
                    opacity: _logoCtrl,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 1.2).animate(
                        CurvedAnimation(
                          parent: _logoCtrl,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: const AgriSmartLogo(size: 100, showGlow: true),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // App name — gold gradient, fade + slide up
                  AnimatedBuilder(
                    animation: _titleCtrl,
                    builder: (_, child) => Opacity(
                      opacity: _titleCtrl.value,
                      child: Transform.translate(
                        offset: Offset(0, 24 * (1 - _titleCtrl.value)),
                        child: child,
                      ),
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFD4A017),
                          Color(0xFFFFD54F),
                          Color(0xFFD4A017),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Text(
                        'AgriSmartAI',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Color(0x66000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tagline — fade in
                  FadeTransition(
                    opacity: _taglineCtrl,
                    child: const Text(
                      'Smart Farming, Better Harvest',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        letterSpacing: 0.4,
                        color: Color(0xCCFFFFFF),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  // Loading progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _progress.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFD4A017),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        if (!_supabaseOk &&
                            _connectionChecked &&
                            AppConfig.isSupabaseConfigured) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Retry Connection'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFD4A017),
                              side: const BorderSide(color: Color(0xFFD4A017)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
              // Version bottom-right
              Positioned(
                right: 20,
                bottom: 16,
                child: Text(
                  _version,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
