import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/haptics.dart';

/// Pill-shaped gold gradient button (premium CTA).
class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const GoldButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shadowColor: AppColors.warmGold.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: loading
            ? null
            : () async {
                await AppHaptics.tap();
                onPressed?.call();
              },
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
