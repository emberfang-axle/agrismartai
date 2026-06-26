import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// AGRISMARTAI 2.0 shared admin UI primitives.
class AdminUi {
  AdminUi._();

  static Widget pageHeader({
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 14)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  static Widget glassCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      decoration: DashboardTheme.glassCard(),
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
    );
  }

  static Widget surfaceCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      decoration: DashboardTheme.surfaceCard,
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
    );
  }

  static Widget metricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: DashboardTheme.surfaceCard.copyWith(
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(trend,
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        ],
      ),
    );
  }

  static Widget emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return AdminUi.surfaceCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.softGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    size: 36, color: AppColors.primaryDark.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink)),
              const SizedBox(height: 6),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  static Widget starRating(int rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: AppColors.warmGold,
        ),
      ),
    );
  }
}
