import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../utils/constants.dart';

/// Shimmer skeleton for loading states.
class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF21262D) : AppColors.border,
      highlightColor: isDark ? const Color(0xFF30363D) : Colors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.border,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class HistorySkeletonList extends StatelessWidget {
  const HistorySkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const Row(
        children: [
          SkeletonLoader(width: 72, height: 72, radius: 16),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(height: 16, radius: 8),
                SizedBox(height: 8),
                SkeletonLoader(width: 120, height: 12, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
