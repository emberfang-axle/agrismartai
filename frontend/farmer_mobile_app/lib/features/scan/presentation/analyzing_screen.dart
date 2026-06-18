import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/di/providers.dart';
import '../../../shared/branding/app_brand.dart';
import 'result_screen.dart';

class AnalyzingScreen extends ConsumerStatefulWidget {
  final File imageFile;
  const AnalyzingScreen({super.key, required this.imageFile});

  @override
  ConsumerState<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends ConsumerState<AnalyzingScreen> {
  int _step = 0;
  final _steps = const [
    '🌱 Scanning leaf...',
    '🧠 Identifying disease...',
    '📊 Analyzing severity...',
  ];
  late final String _tip;

  @override
  void initState() {
    super.initState();
    _tip = AppConstants.farmingTips[
        Random().nextInt(AppConstants.farmingTips.length)];
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    for (var i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() => _step = i);
    }

    try {
      final result = await ref
          .read(detectionRepositoryProvider)
          .analyze(widget.imageFile);

      ref.read(scanContextProvider.notifier).state =
          result.copyWith(localImagePath: widget.imageFile.path);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              result: result,
              imageFile: widget.imageFile,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
              _GrowingPlant(),
              const SizedBox(height: 32),
              Text(
                'Analyzing rice leaf...',
                style: AppBrand.heading2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 32),
              ...List.generate(_steps.length, (i) {
                final active = i <= _step;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: AnimatedOpacity(
                    opacity: active ? 1 : 0.35,
                    duration: 300.ms,
                    child: Text(
                      _steps[i],
                      style: AppBrand.body.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _tip,
                    textAlign: TextAlign.center,
                    style: AppBrand.body.copyWith(color: Colors.white70),
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

class _GrowingPlant extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 60,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.brown.shade400,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Icon(Icons.eco_rounded, size: 80, color: AppBrand.accent)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.6, 0.6),
                end: const Offset(1, 1),
                duration: 1500.ms,
                curve: Curves.easeInOut,
              )
              .moveY(begin: 20, end: 0, duration: 1500.ms),
        ],
      ),
    );
  }
}
