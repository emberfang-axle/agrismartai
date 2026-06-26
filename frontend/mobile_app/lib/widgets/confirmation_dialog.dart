import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/haptics.dart';

/// Reusable confirmation modal for destructive actions (logout, delete, clear all).
class ConfirmationDialog {
  ConfirmationDialog._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String? warning,
    required String confirmText,
    required IconData icon,
    required Color confirmColor,
    String cancelText = 'Cancel',
    bool barrierDismissible = false,
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: title,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final scale = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(scale),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 340,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).cardTheme.color ?? Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: confirmColor.withValues(alpha: 0.1),
                        child: Icon(icon, color: confirmColor, size: 32),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.45,
                          color: AppColors.muted,
                        ),
                      ),
                      if (warning != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warmGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.warmGold.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: AppColors.warning, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  warning,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.35,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF757575),
                                side: const BorderSide(color: AppColors.border),
                                minimumSize: const Size.fromHeight(46),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                cancelText,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: confirmColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(46),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                confirmText,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  /// Shows dialog then runs [onConfirm] if user confirms.
  static Future<void> confirmAndRun(
    BuildContext context, {
    required String title,
    required String message,
    String? warning,
    required String confirmText,
    required IconData icon,
    required Color confirmColor,
    required Future<void> Function() onConfirm,
  }) async {
    final ok = await show(
      context,
      title: title,
      message: message,
      warning: warning,
      confirmText: confirmText,
      icon: icon,
      confirmColor: confirmColor,
    );
    if (!context.mounted) return;
    if (ok) {
      await AppHaptics.success();
      await onConfirm();
    }
  }
}
