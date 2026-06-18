import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_brand.dart';

/// Rice leaf + AI badge logo — consistent across splash, login, chat.
class AppLogo extends StatelessWidget {
  final double size;
  final bool animate;

  const AppLogo({super.key, this.size = 100, this.animate = false});

  @override
  Widget build(BuildContext context) {
    Widget logo = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppBrand.heroGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: AppBrand.cardShadow,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.eco_rounded, size: size * 0.55, color: AppBrand.accent.withValues(alpha: 0.95)),
          Positioned(
            right: size * 0.1,
            bottom: size * 0.1,
            child: Container(
              padding: EdgeInsets.all(size * 0.06),
              decoration: BoxDecoration(
                color: AppBrand.secondary,
                shape: BoxShape.circle,
                boxShadow: AppBrand.goldShadow,
              ),
              child: Icon(Icons.auto_awesome_rounded, size: size * 0.2, color: AppBrand.primary),
            ),
          ),
        ],
      ),
    );

    if (animate) {
      logo = logo
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(begin: const Offset(0.96, 0.96), end: const Offset(1.04, 1.04), duration: 1400.ms);
    }
    return logo;
  }
}

class BrandTitle extends StatelessWidget {
  final Color? color;
  final double fontSize;

  const BrandTitle({super.key, this.color, this.fontSize = 28});

  @override
  Widget build(BuildContext context) {
    return Text(
      AppBrand.name,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
        color: color ?? AppBrand.secondary,
        letterSpacing: -0.5,
      ),
    );
  }
}
