import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_widgets.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final _searchCtrl = TextEditingController();
  String _status = 'All';
  String _disease = 'All';
  String _barangay = 'All';

  static const _statuses = ['All', 'pending', 'verified'];
  static const _diseases = ['All', 'BLB', 'Blast', 'Tungro', 'Healthy'];
  static const _barangays = [
    'All', 'Batinao', 'New Bataan', 'Compostela', 'Poblacion',
  ];

  ReportFilters get _filters => ReportFilters(
        status: _status,
        disease: _disease,
        barangay: _barangay,
        search: _searchCtrl.text,
      );

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify(String id) async {
    await ref.read(adminServiceProvider).verifyReport(id);
    ref.invalidate(reportsProvider(_filters));
    ref.invalidate(dashboardStatsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report verified')),
      );
    }
  }

  void _exportCsv(List<dynamic> reports) {
    final buf = StringBuffer(
      'Farmer,Barangay,Date,Disease,Confidence,Status\n',
    );
    for (final r in reports) {
      buf.writeln(
        '"${r.farmerName}","${r.barangay}",'
        '"${DateFormat('yyyy-MM-dd').format(r.createdAt)}",'
        '"${r.displayDisease}",${(r.confidence * 100).toStringAsFixed(1)}%,'
        '"${r.status}"',
      );
    }
    // Web clipboard fallback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV ready (${reports.length} rows) — copy from console'),
        duration: const Duration(seconds: 3),
      ),
    );
    debugPrint(buf.toString());
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsProvider(_filters));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Reports',
          subtitle: 'Farmer scan reports from the field',
          actions: [
            reportsAsync.maybeWhen(
              data: (reports) => GoldButton(
                label: 'Export CSV',
                icon: Icons.download_rounded,
                onPressed: () => _exportCsv(reports),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search farmer, barangay...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              _FilterDropdown(
                label: 'Status',
                value: _status,
                items: _statuses,
                onChanged: (v) => setState(() => _status = v!),
              ),
              _FilterDropdown(
                label: 'Disease',
                value: _disease,
                items: _diseases,
                onChanged: (v) => setState(() => _disease = v!),
              ),
              _FilterDropdown(
                label: 'Barangay',
                value: _barangay,
                items: _barangays,
                onChanged: (v) => setState(() => _barangay = v!),
              ),
            ],
          ),
        ),
        Expanded(
          child: reportsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (reports) {
              if (reports.isEmpty) {
                return Center(
                  child: Text('No reports found', style: AppTheme.body),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      AppTheme.background,
                    ),
                    columns: const [
                      DataColumn(label: Text('Farmer')),
                      DataColumn(label: Text('Barangay')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Disease')),
                      DataColumn(label: Text('Confidence')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: reports.map((r) {
                      return DataRow(cells: [
                        DataCell(Text(r.farmerName, style: AppTheme.button.copyWith(fontSize: 13))),
                        DataCell(Text(r.barangay, style: AppTheme.body)),
                        DataCell(Text(
                          DateFormat('MMM d, yyyy').format(r.createdAt),
                          style: AppTheme.body,
                        )),
                        DataCell(Text(r.displayDisease, style: AppTheme.body)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.diseaseColor(r.disease)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${(r.confidence * 100).toStringAsFixed(0)}%',
                              style: AppTheme.button.copyWith(
                                fontSize: 12,
                                color: AppTheme.diseaseColor(r.disease),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            r.status,
                            style: AppTheme.button.copyWith(
                              color: AppTheme.statusColor(r.status),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataCell(
                          r.status == 'pending'
                              ? TextButton(
                                  onPressed: () => _verify(r.id),
                                  child: Text(
                                    'Verify',
                                    style: AppTheme.button.copyWith(
                                      color: AppTheme.accent,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.check_circle,
                                  color: AppTheme.healthy, size: 20),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: items
            .map((i) => DropdownMenuItem(value: i, child: Text(i)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
