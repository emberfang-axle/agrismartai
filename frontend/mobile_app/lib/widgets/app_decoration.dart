import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'agri_brand_logo.dart';

/// Shared visual primitives for a consistent farmer-friendly UI.
class AppDecoration {
  AppDecoration._();

  static const primaryGradient = LinearGradient(
    colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.45, 1.0],
  );

  static const aiGradient = LinearGradient(
    colors: [AppColors.primary, AppColors.leafGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const goldGradient = LinearGradient(
    colors: [Color(0xFFE8C547), AppColors.warmGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF0F5132), Color(0xFF1B8A5A), Color(0xFF3CCF91)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static List<BoxShadow> softShadow([Color color = Colors.black]) => [
        BoxShadow(
          color: color.withValues(alpha: 0.07),
          blurRadius: 20,
          spreadRadius: -5,
          offset: const Offset(0, 8),
        ),
      ];

  static BoxDecoration card({Color? color, bool border = false}) =>
      BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: border ? AppColors.border : Colors.transparent,
        ),
        boxShadow: softShadow(),
      );

  static BoxDecoration hero({double radius = 24}) => BoxDecoration(
        gradient: heroGradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepGreen.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      );

  static BoxDecoration scannerFrame() => BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.aiBlue.withValues(alpha: 0.45), width: 2),
        gradient: LinearGradient(
          colors: [
            AppColors.aiBlueLight.withValues(alpha: 0.5),
            AppColors.softGreen,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.muted)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class BrandBadge extends StatelessWidget {
  final String label;
  final Color? color;
  const BrandBadge({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.warmGold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Text(label,
          style: TextStyle(
            color: c,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          )),
    );
  }
}

/// Branded AgriSmartAI logo mark.
class AgriLogo extends StatelessWidget {
  final double size;
  final bool showGlow;
  final bool animatedRing;

  const AgriLogo({
    super.key,
    this.size = 72,
    this.showGlow = false,
    this.animatedRing = false,
  });

  @override
  Widget build(BuildContext context) {
    return AgriBrandLogo(
      size: size,
      showGlow: showGlow,
      animateRing: animatedRing,
    );
  }
}

/// Decorative agriculture field background for auth screens.
class AgricultureBackground extends StatelessWidget {
  final Widget child;
  const AgricultureBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.pageBg, Color(0xFFE2E8F0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: -40,
          right: -30,
          child: Icon(Icons.grass,
              size: 180, color: AppColors.primary.withValues(alpha: 0.06)),
        ),
        Positioned(
          bottom: 80,
          left: -20,
          child: Icon(Icons.water_drop,
              size: 120, color: AppColors.aiBlue.withValues(alpha: 0.06)),
        ),
        child,
      ],
    );
  }
}

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.softGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.deepGreen.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class DashboardStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const DashboardStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecoration.card(border: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.muted)),
          if (subtitle != null)
            Text(subtitle!,
                style: const TextStyle(fontSize: 11, color: AppColors.aiBlue)),
        ],
      ),
    );
  }
}

class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeSlidePageRoute({required this.page, super.settings})
      : super(
          pageBuilder: (_, __, ___) => page,
          // Keep routes fully visible on web — fade transitions can leave a blank screen.
          transitionsBuilder: (_, __, ___, child) => child,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = (_ctrl.value + i * 0.2) % 1.0;
            final opacity = 0.3 + (t < 0.5 ? t : 1 - t) * 1.4;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: opacity.clamp(0.3, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

class AiScanAnimation extends StatefulWidget {
  final double size;
  const AiScanAnimation({super.key, this.size = 120});

  @override
  State<AiScanAnimation> createState() => _AiScanAnimationState();
}

class _AiScanAnimationState extends State<AiScanAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return CustomPaint(
            painter: _ScanRingPainter(progress: _ctrl.value),
            child: Center(
              child: AgriLogo(size: widget.size * 0.55, showGlow: true),
            ),
          );
        },
      ),
    );
  }
}

class _ScanRingPainter extends CustomPainter {
  final double progress;
  _ScanRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final ring = Paint()
      ..color = AppColors.aiBlue.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, ring);

    final sweep = Paint()
      ..shader = SweepGradient(
        colors: [
          AppColors.aiBlue.withValues(alpha: 0.0),
          AppColors.aiBlue,
          AppColors.warmGold,
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(progress * 6.28),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57,
      2.5,
      false,
      sweep,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanRingPainter old) => old.progress != progress;
}
