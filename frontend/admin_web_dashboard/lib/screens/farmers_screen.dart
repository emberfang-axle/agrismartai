import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_widgets.dart';

class FarmersScreen extends ConsumerStatefulWidget {
  const FarmersScreen({super.key});

  @override
  ConsumerState<FarmersScreen> createState() => _FarmersScreenState();
}

class _FarmersScreenState extends ConsumerState<FarmersScreen> {
  final _searchCtrl = TextEditingController();
  String _barangay = 'All';

  static const _barangays = [
    'All', 'Batinao', 'New Bataan', 'Compostela', 'Poblacion',
  ];

  FarmerFilters get _filters => FarmerFilters(
        barangay: _barangay,
        search: _searchCtrl.text,
      );

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final farmersAsync = ref.watch(farmersProvider(_filters));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(
          title: 'Farmers',
          subtitle: 'Registered farmers across barangays',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
          child: Wrap(
            spacing: 12,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  value: _barangay,
                  decoration: const InputDecoration(labelText: 'Barangay'),
                  items: _barangays
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => setState(() => _barangay = v!),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: farmersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (farmers) {
              if (farmers.isEmpty) {
                return Center(
                  child: Text('No farmers found', style: AppTheme.body),
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
                    headingRowColor: WidgetStateProperty.all(AppTheme.background),
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Barangay')),
                      DataColumn(label: Text('Total Scans')),
                      DataColumn(label: Text('Join Date')),
                    ],
                    rows: farmers.map((f) {
                      return DataRow(cells: [
                        DataCell(Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  AppTheme.accent.withValues(alpha: 0.15),
                              child: Text(
                                f.fullName.isNotEmpty
                                    ? f.fullName[0].toUpperCase()
                                    : 'F',
                                style: AppTheme.button.copyWith(
                                  color: AppTheme.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(f.fullName, style: AppTheme.button.copyWith(fontSize: 13)),
                          ],
                        )),
                        DataCell(Text(f.email, style: AppTheme.body)),
                        DataCell(Text(f.barangay, style: AppTheme.body)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${f.totalScans}',
                              style: AppTheme.button.copyWith(
                                color: AppTheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(
                          DateFormat('MMM d, yyyy').format(f.joinDate),
                          style: AppTheme.body,
                        )),
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
