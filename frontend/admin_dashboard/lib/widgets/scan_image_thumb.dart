import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Thumbnail for scan images in admin tables and cards.
class ScanImageThumb extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final Color fallbackColor;

  const ScanImageThumb({
    super.key,
    this.imageUrl,
    this.size = 40,
    this.fallbackColor = AppColors.deepGreen,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: AppColors.softGreen,
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
        color: fallbackColor.withValues(alpha: 0.12),
        child: Icon(Icons.eco, color: fallbackColor, size: size * 0.45),
      );
}
