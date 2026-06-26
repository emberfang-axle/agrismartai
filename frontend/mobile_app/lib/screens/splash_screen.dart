import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../services/postgresql_service.dart';
import '../utils/constants.dart';
import '../widgets/agri_brand_logo.dart';
import 'login_screen.dart';
import 'main_shell.dart';

/// AgriSmartAI splash — logo animation, backend check, progress bar, auto-navigate.
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
  bool _backendOk = true;
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

    await Future.delayed(const Duration(milliseconds: 100));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _titleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _taglineCtrl.forward();

    _progressCtrl.forward();
    final bootstrapFuture = _bootstrap();

    await Future.wait([
      bootstrapFuture,
      Future.delayed(const Duration(milliseconds: _minSplashMs)),
    ]);

    final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
    if (elapsed < _minSplashMs) {
      await Future.delayed(Duration(milliseconds: _minSplashMs - elapsed));
    }

    if (!mounted || _navigated) return;

    if (!_backendOk && !AppConfig.forceOfflineDemo) {
      setState(() {
        _statusText = 'Backend offline — tap Retry or continue in demo';
        _progress = _progressCtrl.value;
      });
      return;
    }

    _navigate();
  }

  Future<void> _bootstrap() async {
    try {
      if (AppConfig.forceOfflineDemo) {
        _backendOk = true;
        if (mounted) {
          setState(() {
            _connectionChecked = true;
            _statusText = 'Offline demo mode';
          });
        }
      } else {
        setState(() => _statusText = 'Checking backend connection...');
        _backendOk = await PostgreSQLService.checkConnection();
        if (mounted) {
          setState(() {
            _connectionChecked = true;
            _statusText = _backendOk
                ? 'Connected to AgriSmartAI API'
                : 'Backend offline — demo mode available';
          });
        }
        if (_backendOk) {
          await PostgreSQLService.instance.init();
        }
      }

      setState(() => _statusText = 'Loading your session...');
      await ref
          .read(authProvider.notifier)
          .bootstrap()
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      if (!AppConfig.forceOfflineDemo) {
        _backendOk = false;
        if (mounted) setState(() => _statusText = 'Connection failed');
      }
    }
  }

  Future<void> _retry() async {
    setState(() {
      _backendOk = true;
      _connectionChecked = false;
      _statusText = 'Retrying connection...';
      _progress = 0;
    });
    _progressCtrl.reset();
    _progressCtrl.forward();
    await _bootstrap();
    if (!mounted) return;
    if (_backendOk || AppConfig.forceOfflineDemo) _navigate();
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
            colors: [Color(0xFF072A16), Color(0xFF0B3B1F), Color(0xFF1A6B3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const Spacer(flex: 2),
                  ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _logoCtrl,
                      curve: Curves.easeOutBack,
                    ),
                    child: const AgriBrandLogo(size: 120, showTagline: false),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _titleCtrl,
                    child: Text(
                      AppConfig.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                        if (!_backendOk &&
                            _connectionChecked &&
                            !AppConfig.forceOfflineDemo) ...[
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
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _navigate,
                            child: const Text(
                              'Continue in demo mode',
                              style: TextStyle(color: Color(0xFFD4A017)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
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
