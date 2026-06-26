import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/scan_provider.dart';
import '../utils/constants.dart';
import '../widgets/app_decoration.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/logout_dialog.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

/// Profile, edit, evaluation, and sign-out (OBJECTIVE 4).
class ProfileScreen extends ConsumerWidget {
  static const route = '/profile';
  final bool showAppBar;

  const ProfileScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final summary = ref.watch(scanSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: showAppBar ? AppBar(title: const Text('Profile')) : null,
      body: AgricultureBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, showAppBar ? 20 : 52, 20, 110),
          children: [
            if (!showAppBar)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('Profile',
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppDecoration.card(border: true),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.deepGreen,
                    child: Text(
                      _initials(user?.fullName ?? 'F'),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(user?.fullName.isNotEmpty == true ? user!.fullName : 'Farmer',
                      style: Theme.of(context).textTheme.headlineSmall),
                  Text(user?.email ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.muted)),
                  const SizedBox(height: 10),
                  StatusBadge(
                    label: (user?.role ?? 'farmer').toUpperCase(),
                    color: AppColors.warmGold,
                    icon: Icons.verified_user_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    context,
                    icon: Icons.qr_code_scanner,
                    label: 'Total Scans',
                    value: '${summary['total'] ?? 0}',
                    color: AppColors.aiBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    context,
                    icon: Icons.warning_amber_rounded,
                    label: 'Diseased',
                    value: '${summary['diseased'] ?? 0}',
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _infoCard(Icons.location_on_outlined, 'Barangay', user?.barangay ?? 'New Bataan'),
            _infoCard(Icons.map_outlined, 'Location',
                '${user?.municipality ?? 'New Bataan'}, ${user?.province ?? 'Davao de Oro'}'),
            if ((user?.phone ?? '').isNotEmpty)
              _infoCard(Icons.phone_outlined, 'Phone', user!.phone!),
            const SizedBox(height: 20),
            _settingsCard(context, ref),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: AppColors.primary),
              title: const Text('App Settings',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Theme, notifications, privacy'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, SettingsScreen.route),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                side: const BorderSide(color: AppColors.border),
              ),
              tileColor: AppColors.card,
            ),
            ElevatedButton.icon(
              onPressed: () => _showEditProfile(context, ref, user),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Profile'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _showEvaluation(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.deepGreen,
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: AppColors.warmGold, width: 1.5),
              ),
              icon: const Icon(Icons.star_outline_rounded, color: AppColors.warmGold),
              label: const Text('Rate AgriSmartAI'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => LogoutDialog.confirmAndRun(
                context,
                onConfirm: () async {
                  await ref.read(authProvider.notifier).signOut();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.route, (r) => false);
                },
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => _confirmDeleteAccount(context, ref),
              icon: const Icon(Icons.person_remove_outlined, size: 18),
              label: const Text('Delete Account'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.danger.withValues(alpha: 0.8),
                minimumSize: const Size.fromHeight(44),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '${AppConfig.appName} v1.0.0\n${AppConfig.location}',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'F';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _statCard(BuildContext context,
      {required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecoration.card(border: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _settingsCard(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: AppDecoration.card(border: true),
      child: SwitchListTile(
        title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Easier on the eyes at night'),
        secondary: Icon(
          isDark ? Icons.dark_mode : Icons.light_mode,
          color: AppColors.warmGold,
        ),
        value: isDark,
        activeThumbColor: AppColors.primary,
        onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppDecoration.card(border: true),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.deepGreen, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(BuildContext context, WidgetRef ref, user) {
    if (user == null) return;
    final name = TextEditingController(text: user.fullName);
    final phone = TextEditingController(text: user.phone ?? '');
    final barangay = TextEditingController(text: user.barangay);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit Profile', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 12),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 12),
            TextField(controller: barangay, decoration: const InputDecoration(labelText: 'Barangay')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final updated = user.copyWith(
                  fullName: name.text.trim(),
                  phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
                  barangay: barangay.text.trim(),
                );
                await ref.read(authProvider.notifier).updateProfile(updated);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEvaluation(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EvaluationSheet(userId: ref.read(currentUserProvider)?.id),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    ConfirmationDialog.confirmAndRun(
      context,
      title: 'Delete Account',
      message: 'Are you sure you want to permanently delete your account?',
      warning:
          'All your data including scan history will be permanently deleted.',
      confirmText: 'Delete Account',
      icon: Icons.person_remove_outlined,
      confirmColor: AppColors.danger,
      onConfirm: () async {
        await ref.read(authProvider.notifier).deleteAccount();
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(
            context, LoginScreen.route, (r) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully.')),
        );
      },
    );
  }
}

class _EvaluationSheet extends ConsumerStatefulWidget {
  final String? userId;
  const _EvaluationSheet({this.userId});

  @override
  ConsumerState<_EvaluationSheet> createState() => _EvaluationSheetState();
}

class _EvaluationSheetState extends ConsumerState<_EvaluationSheet> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final uid = widget.userId;
    if (uid != null) {
      await ref.read(postgresqlServiceProvider).saveEvaluation(
            userId: uid,
            rating: _rating,
            comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
          );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    final isDemo = uid != null && uid.startsWith('demo-');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isDemo
            ? 'Thank you! Your feedback will sync when the backend is online.'
            : 'Salamat! Your evaluation was submitted.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rate AgriSmartAI', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text('Help us improve detection for New Bataan farmers.',
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _rating;
              return IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: AppColors.warmGold,
                  size: 40,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _comment,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Share your experience (optional)'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit Evaluation'),
          ),
        ],
      ),
    );
  }
}
