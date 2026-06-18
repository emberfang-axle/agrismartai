import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AgriSmartAI brand system — shared across mobile and web.
class AppBrand {
  AppBrand._();

  static const name = 'AgriSmartAI';
  static const tagline = 'Smart Farming, Better Harvest';
  static const taglineTl = 'Matalinong Pagsasaka, Masaganang Ani';

  static const primary = Color(0xFF0B3B1F);
  static const secondary = Color(0xFFD4A017);
  static const accent = Color(0xFF43A047);
  static const background = Color(0xFFFAF9F6);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF5C5C5C);
  static const textMuted = Color(0xFF9E9E9E);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B3B1F), Color(0xFF1B5E20), Color(0xFF2E7D32)],
  );

  static const goldGradient = LinearGradient(
    colors: [Color(0xFFE8C547), Color(0xFFD4A017)],
  );

  static const loginGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF43A047), Color(0xFF0B3B1F)],
  );

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 20,
          spreadRadius: -5,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get goldShadow => [
        BoxShadow(
          color: secondary.withValues(alpha: 0.3),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get goldButtonShadow => goldShadow;

  static TextStyle get heading1 => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: text,
      );

  static TextStyle get heading2 => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: text,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 15,
        color: textSecondary,
        height: 1.5,
      );

  static TextStyle get button => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static Color diseaseColor(String disease) {
    final d = disease.toLowerCase();
    if (d.contains('blight') || d == 'blb') return const Color(0xFFF9A825);
    if (d.contains('blast')) return const Color(0xFFEF6C00);
    if (d.contains('tungro')) return const Color(0xFFC62828);
    return accent;
  }

  static LinearGradient diseaseGradient(String disease) {
    final c = diseaseColor(disease);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [c.withValues(alpha: 0.85), c.withValues(alpha: 0.35)],
    );
  }
}
