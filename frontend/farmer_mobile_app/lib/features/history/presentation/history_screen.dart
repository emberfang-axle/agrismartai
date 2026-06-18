import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/di/providers.dart';
import '../../scan/domain/scan_result.dart';
import '../../../shared/branding/app_brand.dart';
import '../../../shared/widgets/app_card.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _search = '';
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final scansAsync = ref.watch(scansProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  Text('Scan History', style: AppBrand.heading1),
                  const SizedBox(width: 10),
                  scansAsync.when(
                    data: (scans) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppBrand.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${scans.length}',
                        style: AppBrand.button.copyWith(
                          color: AppBrand.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: TextField(
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search scans...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: ['All', ...AppConstants.diseases].map((f) {
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: AppBrand.accent.withValues(alpha: 0.2),
                      checkmarkColor: AppBrand.primary,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: scansAsync.when(
                loading: () => ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: 5,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: ShimmerBox(height: 88),
                  ),
                ),
                error: (_, __) => _EmptyState(
                  onRefresh: () => ref.invalidate(scansProvider),
                ),
                data: (scans) {
                  final filtered = scans.where((s) {
                    final matchSearch = s.displayName
                            .toLowerCase()
                            .contains(_search) ||
                        (s.createdAt != null &&
                            DateFormat('MMM d')
                                .format(s.createdAt!)
                                .toLowerCase()
                                .contains(_search));
                    final matchFilter = _filter == 'All' ||
                        s.disease.toLowerCase().contains(_filter.toLowerCase()) ||
                        s.displayName
                            .toLowerCase()
                            .contains(_filter.toLowerCase());
                    return matchSearch && matchFilter;
                  }).toList();

                  if (filtered.isEmpty) {
                    return _EmptyState(
                      onRefresh: () => ref.invalidate(scansProvider),
                    );
                  }

                  return RefreshIndicator(
                    color: AppBrand.primary,
                    onRefresh: () async => ref.invalidate(scansProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final scan = filtered[i];
                        return _HistoryCard(scan: scan, delayMs: i * 50);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ScanResult scan;
  final int delayMs;

  const _HistoryCard({required this.scan, required this.delayMs});

  @override
  Widget build(BuildContext context) {
    final color = AppBrand.diseaseColor(scan.displayName);
    final date = scan.createdAt != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(scan.createdAt!)
        : 'Just now';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        delayMs: delayMs,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: scan.imageUrl != null
                  ? Image.network(
                      scan.imageUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                    )
                  : _thumbPlaceholder(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scan.displayName, style: AppBrand.button),
                  const SizedBox(height: 4),
                  Text(date, style: AppBrand.body.copyWith(fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                '${(scan.confidence * 100).toStringAsFixed(0)}%',
                style: AppBrand.button.copyWith(color: color, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: AppBrand.accent.withValues(alpha: 0.15),
      child: const Icon(Icons.eco_rounded, color: AppBrand.accent),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No scans yet', style: AppBrand.heading2),
          const SizedBox(height: 8),
          Text(
            'Scan a rice leaf to see your history here',
            style: AppBrand.body,
          ),
          const SizedBox(height: 20),
          TextButton(onPressed: onRefresh, child: const Text('Refresh')),
        ],
      ),
    );
  }
}
