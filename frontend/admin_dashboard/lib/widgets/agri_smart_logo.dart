import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Unified AgriSmartAI brand mark — identical to mobile app logo.
class AgriSmartLogo extends StatelessWidget {
  final double size;
  final bool showTagline;
  final bool inverted;
  final bool showGlow;

  const AgriSmartLogo({
    super.key,
    this.size = 50,
    this.showTagline = true,
    this.inverted = false,
    this.showGlow = false,
  });

  const AgriSmartLogo.compact({super.key, this.size = 36})
      : showTagline = false,
        inverted = false,
        showGlow = false;

  @override
  Widget build(BuildContext context) {
    final deepGreen = inverted ? Colors.white : const Color(0xFF0B3B1F);
    final gold = const Color(0xFFD4A017);
    final taglineColor =
        inverted ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF6B6B6B);
    final boxBg = inverted
        ? Colors.white.withValues(alpha: 0.15)
        : const Color(0xFF0B3B1F);

    final iconBox = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: boxBg,
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: [
          if (showGlow)
            BoxShadow(
              color: gold.withValues(alpha: 0.45),
              blurRadius: size * 0.35,
              spreadRadius: size * 0.02,
            ),
          if (!inverted)
            BoxShadow(
              color: const Color(0xFF0B3B1F).withValues(alpha: 0.18),
              blurRadius: size * 0.12,
              offset: Offset(0, size * 0.06),
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.eco_rounded, color: gold, size: size * 0.52),
          Positioned(
            right: size * 0.12,
            top: size * 0.12,
            child: Icon(Icons.auto_awesome, color: gold, size: size * 0.22),
          ),
        ],
      ),
    );

    if (!showTagline) return iconBox;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconBox,
        SizedBox(width: size * 0.2),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AgriSmartAI',
                style: _logoTitle(size * 0.5, deepGreen),
              ),
              Text(
                'Smart Farming, Better Harvest',
                style: _logoTagline(size * 0.2, taglineColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

TextStyle _logoTitle(double fontSize, Color color) {
  if (kIsWeb) {
    return TextStyle(
      fontFamily: 'Segoe UI',
      fontWeight: FontWeight.bold,
      fontSize: fontSize,
      color: color,
      height: 1.1,
    );
  }
  return GoogleFonts.poppins(
    fontWeight: FontWeight.bold,
    fontSize: fontSize,
    color: color,
    height: 1.1,
  );
}

TextStyle _logoTagline(double fontSize, Color color) {
  if (kIsWeb) {
    return TextStyle(
      fontFamily: 'Segoe UI',
      fontSize: fontSize,
      color: color,
      height: 1.2,
    );
  }
  return GoogleFonts.inter(
    fontSize: fontSize,
    color: color,
    height: 1.2,
  );
}
