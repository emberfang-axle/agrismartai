import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../models/report_model.dart';
import '../providers/report_provider.dart';
import '../widgets/admin_confirmation_dialog.dart';
import '../widgets/chart_widget.dart';

/// Professional reports table with search, filter, and pagination.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportStatus? _filter;
  final _search = TextEditingController();
  String _query = '';
  int _page = 0;
  static const _pageSize = 8;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ReportModel> _filtered(List<ReportModel> all) {
    final global = ref.watch(globalSearchProvider);
    var list = _filter == null
        ? all
        : all.where((r) => r.status == _filter).toList();
    final q = (_query.isNotEmpty ? _query : global).toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((r) =>
              r.farmerName.toLowerCase().contains(q) ||
              r.diseaseName.toLowerCase().contains(q) ||
              r.barangay.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportProvider);
    final all = reportsAsync.value ?? const <ReportModel>[];
    final reports = _filtered(all);
        final totalPages = (reports.length / _pageSize).ceil().clamp(1, 999);
        if (_page >= totalPages) _page = totalPages - 1;
        final pageItems =
            reports.skip(_page * _pageSize).take(_pageSize).toList();

        return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  gradient: DashboardTheme.brandGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Disease Reports',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text('Review farmer scans before they enter official records',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ReviewGuideBanner(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() {
                    _query = v.trim();
                    _page = 0;
                  }),
                  decoration: InputDecoration(
                    hintText: 'Search farmer, disease, barangay...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _chip('All', null),
              _chip('Pending', ReportStatus.pending),
              _chip('Verified', ReportStatus.verified),
              _chip('Rejected', ReportStatus.rejected),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                _header(context),
                const Divider(height: 1),
                if (pageItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('No reports match your search or filter.',
                        style: TextStyle(color: AppColors.muted)),
                  ),
                for (final r in pageItems) _row(context, r),
                if (reports.isNotEmpty) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _page > 0
                              ? () => setState(() => _page--)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(
                          'Page ${_page + 1} of $totalPages (${reports.length} total)',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        IconButton(
                          onPressed: _page < totalPages - 1
                              ? () => setState(() => _page++)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, ReportStatus? status) {
    final selected = _filter == status;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.deepGreen,
      labelStyle:
          TextStyle(color: selected ? Colors.white : AppColors.ink),
      onSelected: (_) => setState(() {
        _filter = status;
        _page = 0;
      }),
    );
  }

  Widget _header(BuildContext context) {
    TextStyle s() =>
        const TextStyle(fontWeight: FontWeight.w600, color: AppColors.muted, fontSize: 12);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('IMAGE', style: s())),
          Expanded(flex: 3, child: Text('FARMER / DISEASE', style: s())),
          Expanded(flex: 2, child: Text('BARANGAY', style: s())),
          Expanded(flex: 2, child: Text('CONFIDENCE', style: s())),
          Expanded(flex: 2, child: Text('DATE', style: s())),
          Expanded(flex: 2, child: Text('STATUS', style: s())),
          Expanded(flex: 3, child: Text('ACTIONS', style: s())),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, ReportModel r) {
    final color = diseaseColor(r.diseaseCode);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: r.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: r.imageUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _imageFallback(color),
                    ),
                  )
                : _imageFallback(color),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.diseaseName,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(r.farmerName,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(r.barangay)),
          Expanded(
              flex: 2,
              child: Text('${r.confidence}%',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w600))),
          Expanded(
              flex: 2,
              child: Text(DateFormat('MMM d, y').format(r.createdAt),
                  style: const TextStyle(color: AppColors.muted))),
          Expanded(flex: 2, child: _statusBadge(r.status)),
          Expanded(
            flex: 3,
            child: r.status == ReportStatus.pending
                ? Row(
                    children: [
                      _ActionBtn(
                        label: 'Verify',
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                        onPressed: () => _confirmVerify(context, r),
                      ),
                      const SizedBox(width: 8),
                      _ActionBtn(
                        label: 'Reject',
                        icon: Icons.cancel_outlined,
                        color: AppColors.danger,
                        onPressed: () => _confirmReject(context, r),
                      ),
                    ],
                  )
                : Text(r.reviewerNote ?? '—',
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback(Color color) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.eco, color: color, size: 20),
      );

  Future<void> _confirmVerify(BuildContext context, ReportModel r) async {
    final ok = await AdminConfirmationDialog.show(
      context,
      title: 'Verify Disease Report?',
      message:
          'Confirm that the AI diagnosis for "${r.diseaseName}" matches the uploaded leaf image.',
      info:
          'Purpose: Verified reports are trusted for DA outbreak monitoring, barangay heat maps, and farmer treatment advisories.',
      icon: Icons.verified_outlined,
      iconColor: AppColors.success,
      yesColor: AppColors.success,
    );
    if (!ok || !context.mounted) return;
    final err = await ref
        .read(reportProvider.notifier)
        .verify(r.id, note: 'Verified by admin');
    if (context.mounted && err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _confirmReject(BuildContext context, ReportModel r) async {
    final ok = await AdminConfirmationDialog.show(
      context,
      title: 'Reject Disease Report?',
      message:
          'Mark this scan from ${r.farmerName} as invalid or incorrect?',
      info:
          'Purpose: Reject blurry photos, non-rice images, or wrong AI labels so farmers are not given incorrect treatment advice.',
      icon: Icons.block_outlined,
      iconColor: AppColors.danger,
      yesColor: AppColors.danger,
    );
    if (!ok || !context.mounted) return;
    final err = await ref
        .read(reportProvider.notifier)
        .reject(r.id, note: 'Rejected by admin');
    if (context.mounted && err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Widget _statusBadge(ReportStatus status) {
    final color = switch (status) {
      ReportStatus.verified => AppColors.success,
      ReportStatus.rejected => AppColors.danger,
      ReportStatus.pending => AppColors.warning,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(status.label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      ),
    );
  }
}

class _ReviewGuideBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.softGreen,
            AppColors.primaryLight.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Verify vs Reject — what they mean',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.ink)),
                SizedBox(height: 8),
                Text(
                  '• Verify — Admin confirms the AI disease result is correct. '
                  'The report is added to official monitoring and analytics.\n'
                  '• Reject — Admin flags a bad scan (wrong image, poor quality, '
                  'or wrong disease). It is removed from trusted records so farmers '
                  'do not receive incorrect advice.',
                  style: TextStyle(
                      fontSize: 12.5, height: 1.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
