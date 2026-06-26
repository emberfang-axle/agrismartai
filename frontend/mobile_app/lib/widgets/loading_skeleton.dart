import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'skeleton_loader.dart';

export 'skeleton_loader.dart';

/// Dashboard-style skeleton for home / profile loading states.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(height: 28, width: 180, radius: 8),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _statSkeleton()),
              const SizedBox(width: 12),
              Expanded(child: _statSkeleton()),
            ],
          ),
          const SizedBox(height: 20),
          const SkeletonLoader(height: 120, radius: AppRadius.card),
          const SizedBox(height: 16),
          const SkeletonLoader(height: 80, radius: AppRadius.card),
          const SizedBox(height: 16),
          const SkeletonLoader(height: 80, radius: AppRadius.card),
        ],
      ),
    );
  }

  Widget _statSkeleton() => const SkeletonLoader(height: 90, radius: AppRadius.card);
}

/// Profile screen skeleton.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SkeletonLoader(width: 88, height: 88, radius: 44),
          const SizedBox(height: 16),
          const SkeletonLoader(height: 22, width: 140, radius: 8),
          const SizedBox(height: 8),
          const SkeletonLoader(height: 14, width: 200, radius: 6),
          const SizedBox(height: 24),
          const SkeletonLoader(height: 100, radius: AppRadius.card),
          const SizedBox(height: 12),
          const SkeletonLoader(height: 100, radius: AppRadius.card),
        ],
      ),
    );
  }
}

/// Result screen skeleton while loading detection data.
class ResultSkeleton extends StatelessWidget {
  const ResultSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SkeletonLoader(height: 220, radius: 22),
          const SizedBox(height: 16),
          const SkeletonLoader(height: 100, radius: 20),
          const SizedBox(height: 12),
          const SkeletonLoader(height: 80, radius: 20),
          const SizedBox(height: 12),
          const SkeletonLoader(height: 80, radius: 20),
        ],
      ),
    );
  }
}
