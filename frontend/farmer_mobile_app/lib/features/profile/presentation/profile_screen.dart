import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/user_profile.dart';
import '../../../core/di/providers.dart';
import '../../../shared/branding/app_brand.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_card.dart';
import '../../auth/presentation/login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final UserProfile user;
  const ProfileScreen({super.key, required this.user});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(userStatsProvider);
    final darkMode = ref.watch(darkModeProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppBrand.accent.withValues(alpha: 0.2),
                    child: Text(
                      widget.user.fullName.isNotEmpty
                          ? widget.user.fullName[0].toUpperCase()
                          : 'F',
                      style: AppBrand.heading1.copyWith(
                        color: AppBrand.primary,
                        fontSize: 36,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppBrand.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 16, color: AppBrand.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(widget.user.fullName, style: AppBrand.heading2),
              Text(widget.user.barangay, style: AppBrand.body),
              const SizedBox(height: 24),
              statsAsync.when(
                loading: () => const Row(
                  children: [
                    Expanded(child: ShimmerBox(height: 80)),
                    SizedBox(width: 12),
                    Expanded(child: ShimmerBox(height: 80)),
                    SizedBox(width: 12),
                    Expanded(child: ShimmerBox(height: 80)),
                  ],
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) => Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Total Scans',
                        value: '${stats['totalScans']}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Accuracy',
                        value: '${(stats['accuracyRate'] as double).toStringAsFixed(0)}%',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Streak',
                        value: '${stats['streak']}d',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _SettingsSection(
                title: 'Account',
                children: [
                  _SettingsTile(
                    icon: Icons.person_outline,
                    title: 'Name',
                    subtitle: widget.user.fullName,
                  ),
                  _SettingsTile(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    subtitle: widget.user.email,
                  ),
                  _SettingsTile(
                    icon: Icons.location_on_outlined,
                    title: 'Barangay',
                    subtitle: widget.user.barangay,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: 'Preferences',
                children: [
                  SwitchListTile(
                    title: Text('Dark Mode', style: AppBrand.button),
                    subtitle: Text('Coming soon', style: AppBrand.body),
                    value: darkMode,
                    activeColor: AppBrand.accent,
                    onChanged: (v) =>
                        ref.read(darkModeProvider.notifier).state = v,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: 'Data',
                children: [
                  ListTile(
                    leading: const Icon(Icons.download_outlined),
                    title: Text('Export History', style: AppBrand.button),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export coming soon')),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: Text(
                      'Clear History',
                      style: AppBrand.button.copyWith(color: Colors.red),
                    ),
                    onTap: () async {
                      final user = ref.read(authRepositoryProvider).currentUser;
                      if (user != null) {
                        await ref.read(scanRepositoryProvider).clearHistory(user.id);
                        ref.invalidate(scansProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('History cleared')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: 'Support',
                children: [
                  ListTile(
                    leading: const Icon(Icons.school_outlined),
                    title: Text('Tutorial', style: AppBrand.button),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.feedback_outlined),
                    title: Text('Feedback', style: AppBrand.button),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text('About AgriSmartAI v1.0', style: AppBrand.button),
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                },
                child: Text(
                  'Logout',
                  style: AppBrand.button.copyWith(color: Colors.red),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Text(
            value,
            style: AppBrand.heading2.copyWith(
              color: AppBrand.primary,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppBrand.body.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              title,
              style: AppBrand.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppBrand.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppBrand.primary),
      title: Text(title, style: AppBrand.button),
      subtitle: Text(subtitle, style: AppBrand.body),
    );
  }
}
