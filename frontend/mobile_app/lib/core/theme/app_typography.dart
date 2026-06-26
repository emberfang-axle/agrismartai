import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// AgriSmartAI v2.0 — Typography design tokens.
/// Poppins for headings, Inter for body. Single source of truth.
class AppTypography {
  AppTypography._();

  // ── Display ──────────────────────────────────────────────────────────
  static TextStyle get displayLarge => _heading(36, FontWeight.w800);
  static TextStyle get displayMedium => _heading(28, FontWeight.w700);

  // ── Heading ──────────────────────────────────────────────────────────
  static TextStyle get headingLarge => _heading(24, FontWeight.w700);
  static TextStyle get headingMedium => _heading(20, FontWeight.w700);
  static TextStyle get headingSmall => _heading(18, FontWeight.w600);

  // ── Card / Section ───────────────────────────────────────────────────
  static TextStyle get cardTitle => _heading(16, FontWeight.w600);
  static TextStyle get sectionLabel => _heading(
        12,
        FontWeight.w700,
        color: AppColors.muted,
        letterSpacing: 1.2,
      );

  // ── Body ─────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => _body(16);
  static TextStyle get body => _body(14);
  static TextStyle get bodySmall => _body(13, color: AppColors.muted);

  // ── Supporting ───────────────────────────────────────────────────────
  static TextStyle get caption => _body(12, color: AppColors.caption);
  static TextStyle get overline => _body(
        10,
        color: AppColors.muted,
        weight: FontWeight.w700,
        letterSpacing: 1.0,
      );
  static TextStyle get button => _heading(15, FontWeight.w600);
  static TextStyle get buttonSmall => _heading(13, FontWeight.w600);

  // ── Helpers ──────────────────────────────────────────────────────────
  static TextStyle _heading(
    double size,
    FontWeight weight, {
    Color? color,
    double letterSpacing = 0,
  }) {
    final c = color ?? AppColors.ink;
    if (kIsWeb) {
      return TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: c,
        letterSpacing: letterSpacing,
      );
    }
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: c,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle _body(
    double size, {
    Color? color,
    FontWeight? weight,
    double letterSpacing = 0,
  }) {
    final c = color ?? AppColors.ink;
    final w = weight ?? FontWeight.w400;
    if (kIsWeb) {
      return TextStyle(
        fontSize: size,
        fontWeight: w,
        color: c,
        letterSpacing: letterSpacing,
        height: 1.5,
      );
    }
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: w,
      color: c,
      letterSpacing: letterSpacing,
      height: 1.5,
    );
  }

  /// Build a complete [TextTheme] from tokens.
  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        headlineLarge: headingLarge,
        headlineMedium: headingMedium,
        headlineSmall: headingSmall,
        titleLarge: cardTitle,
        titleMedium: bodyLarge.copyWith(fontWeight: FontWeight.w500),
        titleSmall: body.copyWith(fontWeight: FontWeight.w500),
        bodyLarge: bodyLarge,
        bodyMedium: body,
        bodySmall: bodySmall,
        labelLarge: button,
        labelMedium: buttonSmall,
        labelSmall: caption,
      );
}
