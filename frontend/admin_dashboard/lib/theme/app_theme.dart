import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AgriSmartAI v2.0 — Enterprise Admin Design System.
/// Inspired by Stripe, Supabase, Linear, Vercel.
class DashboardTheme {
  DashboardTheme._();

  // Brand gradients
  static const brandGradient = LinearGradient(
    colors: [Color(0xFF0B3B1F), Color(0xFF145A32), Color(0xFF1A6B3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF0B3B1F), Color(0xFF145A32), Color(0xFF1A6B3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
      blurRadius: 20,
      spreadRadius: -4,
      offset: const Offset(0, 8),
    ),
  ];

  static BoxDecoration glassCard({double radius = 16}) => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: cardShadow,
      );

  static BoxDecoration surfaceCard = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.border),
    boxShadow: cardShadow,
  );

  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.pageBg,
      canvasColor: AppColors.pageBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: AppColors.surface,
      ),
    );

    final textTheme = (kIsWeb
            ? base.textTheme
            : GoogleFonts.interTextTheme(base.textTheme))
        .copyWith(
      displaySmall: _h(28, FontWeight.w700, AppColors.ink),
      headlineSmall: _h(20, FontWeight.w700, AppColors.ink),
      titleLarge: _h(16, FontWeight.w600, AppColors.ink),
      titleMedium: _h(14, FontWeight.w600, AppColors.ink),
      bodyMedium: _t(13, AppColors.muted),
      bodySmall: _t(12, AppColors.caption),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.pageBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(42),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          textStyle: _h(13, FontWeight.w600, Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  static TextStyle _h(double size, FontWeight w, Color c) =>
      kIsWeb
          ? TextStyle(fontSize: size, fontWeight: w, color: c)
          : GoogleFonts.inter(fontSize: size, fontWeight: w, color: c);

  static TextStyle _t(double size, Color c) =>
      kIsWeb
          ? TextStyle(fontSize: size, color: c)
          : GoogleFonts.inter(fontSize: size, color: c);
}

/// AgriSmartAI v2.0 — Admin color palette (AGRISMARTAI V2).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0B3B1F);
  static const Color primaryDark = Color(0xFF072A16);
  static const Color primaryLight = Color(0xFFE8F3EC);
  static const Color deepGreen = primary;
  static const Color accent = Color(0xFFD4A017);
  static const Color aiAccent = accent;

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF2563EB);
  static const Color purple = Color(0xFF7C3AED);

  static const Color pageBg = Color(0xFFF4F8F5);
  static const Color bg = pageBg;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE5E7EB);

  static const Color ink = Color(0xFF111827);
  static const Color muted = Color(0xFF6B7280);
  static const Color caption = Color(0xFF9CA3AF);

  static const Color warmGold = Color(0xFFD4A017);
  static const Color aiBlue = info;
  static const Color aiBlueLight = Color(0xFFEFF6FF);
  static const Color leafGreen = accent;
  static const Color softGreen = Color(0xFFECFDF5);
}
