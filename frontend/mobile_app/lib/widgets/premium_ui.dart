import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/constants.dart';

/// AGRISMARTAI V2 — shared premium SaaS UI primitives.
class PremiumUi {
  PremiumUi._();

  static const brandGradient = LinearGradient(
    colors: [Color(0xFF064420), Color(0xFF0E8A39), Color(0xFF2EBE60)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const meshGradient = LinearGradient(
    colors: [Color(0xFFF7FAF8), Color(0xFFECFDF3), Color(0xFFF0F9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> elevation([Color? c, double a = 0.08]) => [
        BoxShadow(
          color: (c ?? const Color(0xFF0F172A)).withValues(alpha: a),
          blurRadius: 24,
          spreadRadius: -6,
          offset: const Offset(0, 12),
        ),
      ];

  static BoxDecoration glass({
    Color? tint,
    double radius = 20,
    bool border = true,
  }) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: [
            (tint ?? Colors.white).withValues(alpha: 0.92),
            (tint ?? Colors.white).withValues(alpha: 0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: border
            ? Border.all(color: Colors.white.withValues(alpha: 0.65))
            : null,
        boxShadow: elevation(),
      );
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? tint;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              decoration: PremiumUi.glass(tint: tint),
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool large;

  const PremiumActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.large = false,
  });

  @override
  State<PremiumActionCard> createState() => _PremiumActionCardState();
}

class _PremiumActionCardState extends State<PremiumActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: 120.ms,
        child: AnimatedContainer(
          duration: 200.ms,
          padding: EdgeInsets.all(widget.large ? 22 : 18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: PremiumUi.elevation(widget.color, _pressed ? 0.04 : 0.07),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withValues(alpha: 0.18),
                      widget.color.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: widget.color, size: widget.large ? 28 : 24),
              ),
              SizedBox(height: widget.large ? 16 : 12),
              Text(
                widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: widget.large ? 17 : 15,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color accent;

  const InsightCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.muted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DiagnosisSection extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color? accent;

  const DiagnosisSection({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = accent ?? AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: c),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: c,
                      letterSpacing: 0.3)),
            ],
          ),
          const SizedBox(height: 10),
          Text(content,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.ink, height: 1.5)),
        ],
      ),
    );
  }
}

class AiGridOverlay extends StatelessWidget {
  final Widget child;
  final bool animate;

  const AiGridOverlay({super.key, required this.child, this.animate = true});

  @override
  Widget build(BuildContext context) {
    final grid = CustomPaint(
      foregroundPainter: _GridPainter(),
      child: child,
    );
    if (!animate) return grid;
    return grid
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 2200.ms, color: AppColors.accent.withValues(alpha: 0.15));
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.12)
      ..strokeWidth = 0.5;
    const step = 18.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String greetingForTime() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good Morning';
  if (h < 17) return 'Good Afternoon';
  return 'Good Evening';
}
