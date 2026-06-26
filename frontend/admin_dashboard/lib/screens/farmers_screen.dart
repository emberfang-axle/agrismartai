import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../providers/report_provider.dart';
import '../widgets/admin_ui.dart';

/// Registered farmers with search, contact info, and detail sheet.
class FarmersScreen extends ConsumerStatefulWidget {
  const FarmersScreen({super.key});

  @override
  ConsumerState<FarmersScreen> createState() => _FarmersScreenState();
}

class _FarmersScreenState extends ConsumerState<FarmersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final farmersAsync = ref.watch(farmerProvider);
    final global = ref.watch(globalSearchProvider);
    final effectiveQuery = _query.isNotEmpty ? _query : global;

    return farmersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: AdminUi.emptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load farmers',
          message: 'Check your connection and tap refresh in the top bar.',
        ),
      ),
      data: (all) {
        final farmers = all.where((f) {
          final q = effectiveQuery.toLowerCase();
          return q.isEmpty ||
              f.fullName.toLowerCase().contains(q) ||
              f.barangay.toLowerCase().contains(q) ||
              f.email.toLowerCase().contains(q);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminUi.pageHeader(
                title: 'Registered Farmers',
                subtitle: '${all.length} farmers in New Bataan monitoring program',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 380,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search name, barangay, or email...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(height: 24),
              if (farmers.isEmpty)
                AdminUi.emptyState(
                  icon: Icons.people_outline,
                  title: 'No farmers found',
                  message: effectiveQuery.isEmpty
                      ? 'Farmers will appear here after registration.'
                      : 'Try a different search term.',
                )
              else
                LayoutBuilder(builder: (context, c) {
                  final cross = c.maxWidth > 1200 ? 3 : c.maxWidth > 700 ? 2 : 1;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cross,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: cross == 1 ? 2.4 : 1.5,
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: farmers.length,
                    itemBuilder: (_, i) => _FarmerCard(
                      farmer: farmers[i],
                      onTap: () => _showDetail(context, farmers[i]),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  void _showDetail(BuildContext context, FarmerModel f) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.deepGreen,
                  child: Text(f.initials,
                      style: const TextStyle(color: Colors.white, fontSize: 18)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.fullName, style: Theme.of(ctx).textTheme.titleLarge),
                      Text(f.barangay,
                          style: const TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _detailRow(Icons.email_outlined, 'Email', f.email),
            if ((f.phone ?? '').isNotEmpty)
              _detailRow(Icons.phone_outlined, 'Phone', f.phone!),
            _detailRow(Icons.qr_code_scanner, 'Total scans', '${f.totalScans}'),
            _detailRow(Icons.warning_amber_rounded, 'Diseased scans', '${f.diseasedScans}'),
            _detailRow(Icons.calendar_today_outlined, 'Joined',
                DateFormat('MMMM d, y').format(f.joinedAt)),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _FarmerCard extends StatelessWidget {
  final FarmerModel farmer;
  final VoidCallback onTap;
  const _FarmerCard({required this.farmer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: DashboardTheme.surfaceCard,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.deepGreen,
                    child: Text(farmer.initials,
                        style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(farmer.fullName,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis),
                        Text(farmer.barangay,
                            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
                ],
              ),
              const SizedBox(height: 10),
              Text(farmer.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              const Spacer(),
              Row(
                children: [
                  _miniStat('Scans', '${farmer.totalScans}', AppColors.deepGreen),
                  const SizedBox(width: 8),
                  _miniStat('Diseased', '${farmer.diseasedScans}', AppColors.danger),
                ],
              ),
              const SizedBox(height: 8),
              Text('Joined ${DateFormat('MMM y').format(farmer.joinedAt)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(value,
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
