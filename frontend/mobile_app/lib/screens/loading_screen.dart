import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/scan_payload.dart';
import '../providers/scan_provider.dart';
import '../utils/constants.dart';
import '../widgets/premium_ui.dart';
import 'result_screen.dart';

/// AgriSmartAI v2.0 — Neural AI processing screen.
/// Shows real AI pipeline stages with animated visuals so farmers
/// understand the AI is actively working — not just loading.
class LoadingScreen extends ConsumerStatefulWidget {
  static const route = '/loading';
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen>
    with TickerProviderStateMixin {
  bool _started = false;
  int _currentStep = 0;
  bool _allDone = false;

  late final AnimationController _radarCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _stepCtrl;

  static const _steps = [
    _AiStep(Icons.biotech_outlined, 'Analyzing Leaf Structure',
        'Neural preprocessing & edge detection'),
    _AiStep(Icons.search_outlined, 'Detecting Symptoms',
        'Color, lesion, and stripe pattern analysis'),
    _AiStep(Icons.hub_outlined, 'Comparing Disease Patterns',
        'Matching against rice disease knowledge base'),
    _AiStep(Icons.assignment_outlined, 'Generating Recommendations',
        'Treatment, fertilizer, and DA referral protocol'),
  ];

  @override
  void initState() {
    super.initState();
    _radarCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
          ..repeat();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
          ..repeat(reverse: true);
    _stepCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    _pulseCtrl.dispose();
    _stepCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final payload = ModalRoute.of(context)?.settings.arguments as ScanPayload?;
    if (payload == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _run(payload));
  }

  Future<void> _run(ScanPayload payload) async {
    // Animate step progression in sync with backend call
    _advanceSteps();
    try {
      final result = await ref
          .read(scanProvider.notifier)
          .analyze(payload)
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;
      if (result == null) {
        final err = ref.read(scanProvider).error ?? 'Not a valid rice leaf image.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
        Navigator.pop(context);
        return;
      }
      if (mounted) setState(() => _allDone = true);
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, ResultScreen.route);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
      Navigator.pop(context);
    }
  }

  Future<void> _advanceSteps() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(
          Duration(milliseconds: 500 + i * 300));
      if (!mounted) return;
      setState(() => _currentStep = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payload =
        ModalRoute.of(context)?.settings.arguments as ScanPayload?;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              _HeaderSection(allDone: _allDone),
              const SizedBox(height: 32),
              // Radar + image preview
              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _radarCtrl,
                      builder: (_, __) => CustomPaint(
                        size: const Size(200, 200),
                        painter: _RadarPainter(
                          progress: _radarCtrl.value,
                          allDone: _allDone,
                        ),
                      ),
                    ),
                    if (payload != null)
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, child) => Transform.scale(
                          scale: 1 + _pulseCtrl.value * 0.015,
                          child: child,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AiGridOverlay(
                            child: Image.memory(
                              payload.bytes,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    if (_allDone)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.success.withValues(alpha: 0.85),
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 48),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Step list
              Expanded(
                child: ListView.separated(
                  itemCount: _steps.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) => _StepTile(
                    step: _steps[i],
                    state: i < _currentStep
                        ? _StepState.complete
                        : i == _currentStep
                            ? _StepState.active
                            : _StepState.pending,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _ScanFooter(allDone: _allDone),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _HeaderSection extends StatelessWidget {
  final bool allDone;
  const _HeaderSection({required this.allDone});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.biotech_outlined,
              color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                allDone ? 'Analysis Complete' : 'AI Neural Processing',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                allDone
                    ? 'Redirecting to results...'
                    : 'MobileNetV2 · Disease Classification Engine',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        if (!allDone)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }
}

// ─── Radar painter ────────────────────────────────────────────────────────────
class _RadarPainter extends CustomPainter {
  final double progress;
  final bool allDone;
  _RadarPainter({required this.progress, required this.allDone});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    // Concentric rings
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        maxR * i / 3,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    if (allDone) {
      // Success glow
      canvas.drawCircle(
        center,
        maxR - 4,
        Paint()
          ..color = AppColors.success.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill,
      );
      return;
    }

    // Radar sweep
    final sweepShader = SweepGradient(
      colors: [
        Colors.transparent,
        AppColors.primary.withValues(alpha: 0.08),
        AppColors.primary.withValues(alpha: 0.20),
        AppColors.aiAccent.withValues(alpha: 0.30),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 0.7, 0.9, 1.0],
      transform: GradientRotation(progress * math.pi * 2 - math.pi / 2),
    ).createShader(Rect.fromCircle(center: center, radius: maxR));

    canvas.drawCircle(
      center,
      maxR - 4,
      Paint()..shader = sweepShader,
    );

    // Sweep line
    final lineAngle = progress * math.pi * 2 - math.pi / 2;
    canvas.drawLine(
      center,
      Offset(
        center.dx + (maxR - 4) * math.cos(lineAngle),
        center.dy + (maxR - 4) * math.sin(lineAngle),
      ),
      Paint()
        ..color = AppColors.aiAccent.withValues(alpha: 0.7)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // Outer ring
    canvas.drawCircle(
      center,
      maxR - 4,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.progress != progress || old.allDone != allDone;
}

// ─── Step tile ────────────────────────────────────────────────────────────────
enum _StepState { pending, active, complete }

class _AiStep {
  final IconData icon;
  final String title;
  final String subtitle;
  const _AiStep(this.icon, this.title, this.subtitle);
}

class _StepTile extends StatelessWidget {
  final _AiStep step;
  final _StepState state;
  const _StepTile({required this.step, required this.state});

  @override
  Widget build(BuildContext context) {
    final active = state == _StepState.active;
    final done = state == _StepState.complete;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withValues(alpha: 0.06)
            : done
                ? AppColors.success.withValues(alpha: 0.05)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? AppColors.primary.withValues(alpha: 0.25)
              : done
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : done
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : done
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.border,
              ),
            ),
            child: done
                ? const Icon(Icons.check_rounded,
                    size: 18, color: AppColors.success)
                : active
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(step.icon, size: 18, color: AppColors.caption),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                    color: active
                        ? AppColors.primary
                        : done
                            ? AppColors.ink
                            : AppColors.muted,
                  ),
                ),
                Text(
                  step.subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.caption),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Footer ──────────────────────────────────────────────────────────────────
class _ScanFooter extends StatelessWidget {
  final bool allDone;
  const _ScanFooter({required this.allDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            allDone ? Icons.verified_outlined : Icons.shield_outlined,
            size: 18,
            color: allDone ? AppColors.success : AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              allDone
                  ? 'Analysis complete — preparing your results'
                  : 'Powered by MobileNetV2 · Encrypted upload to AgriSmartAI servers',
              style:
                  const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
