import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/report_model.dart';
import '../providers/report_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_confirmation_dialog.dart';
import '../widgets/admin_ui.dart';
import '../widgets/chart_widget.dart';

/// AgriSmartAI :: Detection Verification Screen.
/// Technicians can review, approve, or reject scan reports.
class ScansScreen extends ConsumerStatefulWidget {
  const ScansScreen({super.key});

  @override
  ConsumerState<ScansScreen> createState() => _ScansScreenState();
}

class _ScansScreenState extends ConsumerState<ScansScreen>
    with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  String _query = '';
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _search.dispose();
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final global = ref.watch(globalSearchProvider);
    final reports = ref.watch(reportProvider).value ?? const <ReportModel>[];
    final q = _query.isNotEmpty ? _query : global;

    final filtered = reports.where((r) {
      if (q.isEmpty) return true;
      final ql = q.toLowerCase();
      return r.farmerName.toLowerCase().contains(ql) ||
          r.diseaseName.toLowerCase().contains(ql) ||
          r.barangay.toLowerCase().contains(ql);
    }).toList();

    final pending = filtered.where((r) => r.status == ReportStatus.pending).toList();
    final verified = filtered.where((r) => r.status == ReportStatus.verified).toList();
    final rejected = filtered.where((r) => r.status == ReportStatus.rejected).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Disease Detections',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 2),
                        Text('${filtered.length} scan records · Verification workflow',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.muted)),
                      ],
                    ),
                  ),
                  // Stats pills
                  _StatusPill('${pending.length} Pending', AppColors.warning),
                  const SizedBox(width: 8),
                  _StatusPill('${verified.length} Verified', AppColors.success),
                ],
              ),
              const SizedBox(height: 16),
              // Search
              TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Search farmer, disease, or barangay...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              // Tabs
              TabBar(
                controller: _tab,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.muted,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'All (${filtered.length})'),
                  Tab(text: 'Pending (${pending.length})'),
                  Tab(text: 'Verified (${verified.length})'),
                  Tab(text: 'Rejected (${rejected.length})'),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        // Content
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _ScanGrid(reports: filtered),
              _ScanGrid(reports: pending, emptyMessage: 'No pending verifications.'),
              _ScanGrid(reports: verified, emptyMessage: 'No verified scans yet.'),
              _ScanGrid(reports: rejected, emptyMessage: 'No rejected scans.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Scan Grid ────────────────────────────────────────────────────────────────
class _ScanGrid extends StatelessWidget {
  final List<ReportModel> reports;
  final String emptyMessage;
  const _ScanGrid({required this.reports, this.emptyMessage = 'No records found.'});

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return Center(
        child: AdminUi.emptyState(
          icon: Icons.document_scanner_outlined,
          title: emptyMessage,
          message: 'Records will appear here when available.',
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(builder: (_, c) {
        final cols = c.maxWidth > 1200 ? 3 : (c.maxWidth > 720 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: cols == 1 ? 2.2 : 1.5,
          ),
          itemCount: reports.length,
          itemBuilder: (_, i) => _VerificationCard(report: reports[i]),
        );
      }),
    );
  }
}

// ─── Verification Card ────────────────────────────────────────────────────────
class _VerificationCard extends ConsumerStatefulWidget {
  final ReportModel report;
  const _VerificationCard({required this.report});

  @override
  ConsumerState<_VerificationCard> createState() => _VerificationCardState();
}

class _VerificationCardState extends ConsumerState<_VerificationCard> {
  bool _processing = false;

  Color get _diseaseColor => diseaseColor(widget.report.diseaseCode);

  Future<void> _verify() async {
    final ok = await AdminConfirmationDialog.show(
      context,
      title: 'Verify Disease Report?',
      message:
          'Confirm that "${widget.report.diseaseName}" is the correct diagnosis for this leaf image.',
      info:
          'Verified scans are counted in outbreak maps and farmer advisories.',
      icon: Icons.verified_outlined,
      iconColor: AppColors.success,
      yesColor: AppColors.success,
    );
    if (!ok || !mounted) return;
    setState(() => _processing = true);
    await ref.read(reportProvider.notifier).verify(widget.report.id);
    if (mounted) setState(() => _processing = false);
  }

  Future<void> _reject() async {
    final ok = await AdminConfirmationDialog.show(
      context,
      title: 'Reject Disease Report?',
      message:
          'Mark this scan as invalid or incorrectly diagnosed?',
      info:
          'Use Reject for blurry photos, non-rice images, or wrong AI results.',
      icon: Icons.block_outlined,
      iconColor: AppColors.danger,
      yesColor: AppColors.danger,
    );
    if (!ok || !mounted) return;
    final note = await _showNoteDialog();
    if (note == null || !mounted) return;
    setState(() => _processing = true);
    await ref.read(reportProvider.notifier).reject(widget.report.id, note: note);
    if (mounted) setState(() => _processing = false);
  }

  Future<String?> _showNoteDialog() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rejection note (optional)'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'e.g. Not a rice leaf, image too blurry...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    final color = _diseaseColor;
    final isPending = r.status == ReportStatus.pending;
    final isVerified = r.status == ReportStatus.verified;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: r.status == ReportStatus.verified
              ? AppColors.success.withValues(alpha: 0.35)
              : r.status == ReportStatus.rejected
                  ? AppColors.danger.withValues(alpha: 0.25)
                  : AppColors.border,
        ),
        boxShadow: DashboardTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status bar at top
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: r.status == ReportStatus.verified
                  ? AppColors.success
                  : r.status == ReportStatus.rejected
                      ? AppColors.danger
                      : AppColors.warning,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: image + disease info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: r.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: r.imageUrl!,
                                  fit: BoxFit.cover,
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
                            Text(r.diseaseName,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(r.farmerName,
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.muted)),
                            Text(r.barangay,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.caption)),
                          ],
                        ),
                      ),
                      // Confidence badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${r.confidence.toStringAsFixed(0)}%',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w800,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Date + status
                  Row(
                    children: [
                      const Icon(Icons.schedule_outlined,
                          size: 12, color: AppColors.caption),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, y · h:mm a').format(r.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.caption),
                      ),
                      const Spacer(),
                      _StatusBadge(status: r.status),
                    ],
                  ),
                  if (r.reviewerNote != null && r.reviewerNote!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Note: ${r.reviewerNote}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                            fontStyle: FontStyle.italic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const Spacer(),
                  // Action buttons (only for pending)
                  if (isPending)
                    _processing
                        ? const Center(
                            child: SizedBox(
                              height: 28,
                              width: 28,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primary),
                            ),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _reject,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.danger,
                                    side: BorderSide(
                                        color: AppColors.danger.withValues(alpha: 0.4)),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.close, size: 14),
                                  label: const Text('Reject',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _verify,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    minimumSize: Size.zero,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.check, size: 14),
                                  label: const Text('Verify',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          )
                  else if (isVerified)
                    Row(
                      children: [
                        const Icon(Icons.verified_outlined,
                            size: 14, color: AppColors.success),
                        const SizedBox(width: 6),
                        Text('Verified by technician',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600)),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(Icons.cancel_outlined,
                            size: 14, color: AppColors.danger.withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Text('Rejected',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.danger.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbFallback(Color color) => Container(
        color: color.withValues(alpha: 0.1),
        child: Icon(Icons.eco, color: color, size: 28),
      );
}

// ─── Status badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final ReportStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      ReportStatus.verified => ('Verified', AppColors.success, Icons.check_circle_outline),
      ReportStatus.rejected => ('Rejected', AppColors.danger, Icons.cancel_outlined),
      ReportStatus.pending => ('Pending', AppColors.warning, Icons.pending_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
