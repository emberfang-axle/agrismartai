import 'package:flutter/material.dart';

/// AgriSmartAI v2.0 — Color design tokens.
/// Single source of truth. No hardcoded colors anywhere else.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFFA5D6A7);
  static const Color deepGreen = Color(0xFF1B5E20);
  static const Color accent = Color(0xFF66BB6A);
  static const Color aiAccent = Color(0xFF00E676);

  // Gold
  static const Color warmGold = Color(0xFFFFB300);
  static const Color goldLight = Color(0xFFFFE082);

  // Semantic
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1565C0);

  // Surface
  static const Color background = Color(0xFFF8FAF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F8F1);
  static const Color border = Color(0xFFE0EEE0);
  static const Color divider = Color(0xFFEAF0EA);

  // Text
  static const Color ink = Color(0xFF0D1F12);
  static const Color muted = Color(0xFF5C7A5C);
  static const Color caption = Color(0xFF8FA88F);

  // Legacy aliases (keep backward compat while migrating)
  static const Color cream = background;
  static const Color pageBg = background;
  static const Color softGreen = Color(0xFFE8F5E9);
  static const Color primaryLight2 = surfaceVariant;
  static const Color danger = error;
  static const Color aiBlue = info;
  static const Color aiBlueLight = Color(0xFFE3F2FD);
  static const Color leafGreen = accent;

  // Dark
  static const Color darkBg = Color(0xFF0A1A0D);
  static const Color darkSurface = Color(0xFF132015);
  static const Color darkInk = Color(0xFFE8F5E9);
  static const Color darkMuted = Color(0xFF7AAB7A);
}
