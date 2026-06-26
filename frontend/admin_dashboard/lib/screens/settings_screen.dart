import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/logout_dialog.dart';

/// AgriSmartAI :: Admin settings screen.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _emailAlerts = true;
  bool _autoVerifyHigh = false;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(adminNameProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section(context, 'Profile'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.deepGreen,
                          child: Text(name.isNotEmpty ? name[0] : 'A',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 22)),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style:
                                    Theme.of(context).textTheme.titleLarge),
                            const Text('admin@agrismartai.ph',
                                style: TextStyle(color: AppColors.muted)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: name,
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) =>
                          ref.read(adminNameProvider.notifier).state = v,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _section(context, 'Preferences'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    value: _emailAlerts,
                    activeThumbColor: AppColors.deepGreen,
                    title: const Text('Email alerts for new disease reports'),
                    onChanged: (v) => setState(() => _emailAlerts = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _autoVerifyHigh,
                    activeThumbColor: AppColors.deepGreen,
                    title: const Text('Auto-verify reports above 95% confidence'),
                    onChanged: (v) => setState(() => _autoVerifyHigh = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _darkMode,
                    activeThumbColor: AppColors.deepGreen,
                    title: const Text('Dark mode (coming soon)'),
                    onChanged: (v) => setState(() => _darkMode = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _section(context, 'About'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.eco, color: AppColors.deepGreen),
                title: const Text('AgriSmartAI Admin Console'),
                subtitle: const Text(
                    'v1.0.0 • Rice disease monitoring • New Bataan, Davao de Oro'),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () async {
                final ok = await AdminLogoutDialog.show(context);
                if (ok && context.mounted) {
                  ref.read(adminAuthProvider.notifier).signOut();
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
