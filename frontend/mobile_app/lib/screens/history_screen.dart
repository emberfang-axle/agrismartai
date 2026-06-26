import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/scan_model.dart';
import '../providers/scan_provider.dart';
import '../utils/constants.dart';
import '../widgets/app_decoration.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/skeleton_loader.dart';
import 'camera_screen.dart';

/// Scan history with search, filters, pull-to-refresh, and skeleton loading.
class HistoryScreen extends ConsumerStatefulWidget {
  static const route = '/history';
  final bool showAppBar;

  const HistoryScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _query = '';
  String _filter = 'all';

  static const _filters = [
    ('all', 'All'),
    ('bacterial_leaf_blight', 'BLB'),
    ('rice_blast', 'Blast'),
    ('tungro', 'Tungro'),
    ('healthy', 'Healthy'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(scanProvider.notifier).loadHistory());
  }

  List<ScanModel> _filtered(List<ScanModel> history) {
    return history.where((s) {
      final matchFilter = _filter == 'all' || s.diseaseCode == _filter;
      final q = _query.toLowerCase();
      final matchQuery = q.isEmpty ||
          s.diseaseName.toLowerCase().contains(q) ||
          s.diseaseCode.contains(q);
      return matchFilter && matchQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);
    final history = scanState.history;
    final loading = scanState.loading;
    final error = scanState.error;
    final filtered = _filtered(history);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Scan History'),
              actions: [
                if (history.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: 'Clear All History',
                    onPressed: () => _confirmClearAll(context, ref),
                  ),
              ],
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.showAppBar)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Scan History',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.softGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${history.length}',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                  if (history.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined),
                      tooltip: 'Clear All History',
                      onPressed: () => _confirmClearAll(context, ref),
                    ),
                  ],
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search scans...',
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon: const Icon(Icons.tune, size: 20),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _filters.map((f) {
                final active = _filter == f.$1;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(f.$2),
                    selected: active,
                    onSelected: (_) => setState(() => _filter = f.$1),
                    selectedColor: AppColors.softGreen,
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? AppColors.primary : AppColors.muted,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: error != null && history.isEmpty
                ? EmptyStateView(
                    icon: Icons.cloud_off_outlined,
                    title: 'Could not load history',
                    message: error,
                    actionLabel: 'Retry',
                    onAction: () =>
                        ref.read(scanProvider.notifier).loadHistory(),
                  )
                : loading && history.isEmpty
                ? const HistorySkeletonList()
                : filtered.isEmpty
                    ? EmptyStateView(
                        icon: Icons.history,
                        title: history.isEmpty ? 'No scans yet' : 'No matches',
                        message: history.isEmpty
                            ? 'Scan a rice leaf to build your detection history.'
                            : 'Try a different search or filter.',
                        actionLabel: history.isEmpty ? 'Scan Now' : null,
                        onAction: history.isEmpty
                            ? () => Navigator.pushNamed(
                                context, CameraScreen.route)
                            : null,
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () =>
                            ref.read(scanProvider.notifier).loadHistory(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => _HistoryTile(
                                scan: filtered[i],
                                onDelete: () =>
                                    _confirmDeleteScan(context, ref, filtered[i]),
                              )
                              .animate()
                              .fadeIn(delay: (i * 40).ms)
                              .slideX(begin: 0.02, end: 0),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteScan(
    BuildContext context,
    WidgetRef ref,
    ScanModel scan,
  ) async {
    await ConfirmationDialog.confirmAndRun(
      context,
      title: 'Delete Scan',
      message: 'Are you sure you want to delete this scan record?',
      confirmText: 'Delete',
      icon: Icons.delete_outline_rounded,
      confirmColor: AppColors.danger,
      onConfirm: () async {
        final ok = await ref.read(scanProvider.notifier).deleteScan(scan.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Scan deleted.' : 'Could not delete scan.'),
          ),
        );
      },
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    await ConfirmationDialog.confirmAndRun(
      context,
      title: 'Clear All History',
      message:
          'Are you sure you want to delete ALL scan history? This cannot be undone.',
      warning: 'All your scan records will be permanently deleted.',
      confirmText: 'Clear All',
      icon: Icons.delete_forever_rounded,
      confirmColor: AppColors.danger,
      onConfirm: () async {
        final ok = await ref.read(scanProvider.notifier).clearAllHistory();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'History cleared.' : 'Could not clear history.'),
          ),
        );
      },
    );
  }
}

class _HistoryTile extends StatefulWidget {
  final ScanModel scan;
  final VoidCallback onDelete;
  const _HistoryTile({required this.scan, required this.onDelete});

  @override
  State<_HistoryTile> createState() => _HistoryTileState();
}

class _HistoryTileState extends State<_HistoryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scan = widget.scan;
    final color = DiseaseData.byCode(scan.diseaseCode).color;
    final df = DateFormat('MMM d, y • h:mm a');
    final isHealthy = scan.diseaseCode == 'healthy';
    final info = DiseaseData.byCode(scan.diseaseCode);

    return Dismissible(
      key: ValueKey(widget.scan.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        widget.onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(left: 22),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 22),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Container(width: 2, height: _expanded ? 120 : 48, color: AppColors.border),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: scan.imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: scan.imageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const SkeletonLoader(
                                        width: 56, height: 56, radius: 12),
                                    errorWidget: (_, __, ___) => _thumbFallback(color),
                                  )
                                : _thumbFallback(color),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(scan.diseaseName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 15)),
                              Text(df.format(scan.createdAt),
                                  style: const TextStyle(
                                      color: AppColors.muted, fontSize: 11)),
                              const SizedBox(height: 6),
                              StatusBadge(
                                label: isHealthy ? 'Healthy' : 'Detected',
                                color: color,
                                icon: isHealthy ? Icons.check : Icons.warning_amber_rounded,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Text('${scan.confidence.toStringAsFixed(0)}%',
                                style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15)),
                            Icon(
                              _expanded ? Icons.expand_less : Icons.expand_more,
                              color: AppColors.caption,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_expanded) ...[
                      const SizedBox(height: 12),
                      Text(info.treatment,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted, height: 1.4)),
                      const SizedBox(height: 6),
                      Text('Fertilizer: ${info.fertilizer}',
                          style: const TextStyle(fontSize: 11, color: AppColors.caption)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _thumbFallback(Color color) => Container(
        color: color.withValues(alpha: 0.12),
        child: Icon(Icons.eco, color: color, size: 28),
      );
}
