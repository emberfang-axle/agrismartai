import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/haptics.dart';

/// Professional logout confirmation modal (mobile + admin).
class LogoutDialog {
  LogoutDialog._();

  static Future<bool> show(
    BuildContext context, {
    String appName = 'AgriSmartAI',
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Logout',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final scale = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(scale),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 340,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.logout_rounded,
                                color: AppColors.danger, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Logout Confirmation',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Are you sure you want to logout from $appName?',
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warmGold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.warmGold.withValues(alpha: 0.35)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: AppColors.warning, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You will need to login again to access your account.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.muted,
                                side: const BorderSide(color: AppColors.border),
                                minimumSize: const Size.fromHeight(46),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text('No',
                                  style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.danger,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(46),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text('Yes',
                                  style: TextStyle(fontWeight: FontWeight.w700)),
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
    required Future<void> Function() onConfirm,
    String appName = 'AgriSmartAI',
  }) async {
    await AppHaptics.tap();
    if (!context.mounted) return;
    final ok = await show(context, appName: appName);
    if (!context.mounted) return;
    if (ok) {
      await AppHaptics.success();
      await onConfirm();
    }
  }
}
