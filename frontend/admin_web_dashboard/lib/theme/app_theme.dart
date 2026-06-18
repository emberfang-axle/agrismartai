import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const primary = Color(0xFF0B3B1F);
  static const secondary = Color(0xFFD4A017);
  static const accent = Color(0xFF43A047);
  static const background = Color(0xFFFAF9F6);
  static const surface = Color(0xFFFFFFFF);
  static const sidebarBg = Color(0xFF0B3B1F);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF5C5C5C);
  static const textMuted = Color(0xFF9E9E9E);
  static const textOnDark = Color(0xFFF5F5F5);

  static const blb = Color(0xFFF9A825);
  static const blast = Color(0xFFEF6C00);
  static const tungro = Color(0xFFC62828);
  static const healthy = Color(0xFF43A047);

  static const goldGradient = LinearGradient(
    colors: [Color(0xFFE8C547), Color(0xFFD4A017)],
  );

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 20,
          spreadRadius: -5,
          offset: const Offset(0, 8),
        ),
      ];

  static Color diseaseColor(String disease) {
    final d = disease.toLowerCase();
    if (d.contains('blight') || d == 'blb') return blb;
    if (d.contains('blast')) return blast;
    if (d.contains('tungro')) return tungro;
    return healthy;
  }

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return healthy;
      case 'rejected':
        return tungro;
      default:
        return secondary;
    }
  }

  static TextStyle heading1 = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static TextStyle heading2 = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    color: textSecondary,
    height: 1.5,
  );

  static TextStyle button = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
      ),
      textTheme: TextTheme(
        headlineLarge: heading1,
        headlineMedium: heading2,
        bodyMedium: body,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}
