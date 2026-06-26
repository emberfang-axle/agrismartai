// AgriSmartAI v2.0 — Animation duration and curve tokens.
import 'package:flutter/material.dart';

class AppAnimation {
  AppAnimation._();

  // Durations
  static const Duration micro = Duration(milliseconds: 200);
  static const Duration card = Duration(milliseconds: 400);
  static const Duration page = Duration(milliseconds: 600);
  static const Duration hero = Duration(milliseconds: 1200);
  static const Duration splash = Duration(milliseconds: 5000);

  // Curves
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve decelerate = Curves.easeOutCubic;
  static const Curve accelerate = Curves.easeInCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve emphasis = Curves.easeOutBack;
}
