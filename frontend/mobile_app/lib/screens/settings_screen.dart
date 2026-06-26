import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/agri_brand_logo.dart';
import '../widgets/confirmation_dialog.dart';
import 'login_screen.dart';

/// App settings — theme, notifications, about.
class SettingsScreen extends ConsumerWidget {
  static const route = '/settings';
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                const AgriBrandLogo(size: 72, showGlow: true),
                const SizedBox(height: 12),
                Text(AppConfig.appName,
                    style: Theme.of(context).textTheme.titleLarge),
                Text(AppConfig.tagline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _section('Appearance', [
            SwitchListTile(
              title: const Text('Dark mode'),
              subtitle: const Text('Deep forest green theme'),
              value: isDark,
              activeThumbColor: AppColors.accentLime,
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
            ),
          ]),
          _section('Notifications', [
            SwitchListTile(
              title: const Text('Push notifications'),
              subtitle: const Text('Disease alerts & DA advisories'),
              value: true,
              onChanged: (_) {},
            ),
          ]),
          _section('Security', [
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: const Text('Biometric login'),
              subtitle: const Text('Fingerprint / Face ID (device support)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined,
                  color: AppColors.danger),
              title: const Text('Delete account',
                  style: TextStyle(color: AppColors.danger)),
              subtitle: const Text('Permanently remove your account and data'),
              onTap: () => _confirmDeleteAccount(context, ref),
            ),
          ]),
          _section('Support', [
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help center'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy policy'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About AGRISMARTAI'),
              subtitle: const Text('Version 1.0.0'),
              onTap: () {},
            ),
          ]),
        ],
      ),
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
      },
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
          child: Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.muted)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
