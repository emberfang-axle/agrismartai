import 'package:flutter/services.dart';

/// Light haptic feedback on button taps (mobile only).
class AppHaptics {
  AppHaptics._();

  static Future<void> tap() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
  }
}
