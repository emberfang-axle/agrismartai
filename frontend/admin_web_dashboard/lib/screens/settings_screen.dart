import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _daPhone = TextEditingController();
  final _daAddress = TextEditingController();
  final _daHours = TextEditingController();
  final _fertBlb = TextEditingController();
  final _fertBlast = TextEditingController();
  final _fertTungro = TextEditingController();
  final _fertHealthy = TextEditingController();
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _daPhone.dispose();
    _daAddress.dispose();
    _daHours.dispose();
    _fertBlb.dispose();
    _fertBlast.dispose();
    _fertTungro.dispose();
    _fertHealthy.dispose();
    super.dispose();
  }

  void _loadSettings(Map<String, dynamic> s) {
    if (_initialized) return;
    _daPhone.text = s['da_phone']?.toString() ?? '';
    _daAddress.text = s['da_address']?.toString() ?? '';
    _daHours.text = s['da_hours']?.toString() ?? '';
    _fertBlb.text = s['fertilizer_blb']?.toString() ?? '';
    _fertBlast.text = s['fertilizer_blast']?.toString() ?? '';
    _fertTungro.text = s['fertilizer_tungro']?.toString() ?? '';
    _fertHealthy.text = s['fertilizer_healthy']?.toString() ?? '';
    _initialized = true;
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(adminServiceProvider).saveSettings({
        'da_phone': _daPhone.text,
        'da_address': _daAddress.text,
        'da_hours': _daHours.text,
        'fertilizer_blb': _fertBlb.text,
        'fertilizer_blast': _fertBlast.text,
        'fertilizer_tungro': _fertTungro.text,
        'fertilizer_healthy': _fertHealthy.text,
      });
      ref.invalidate(settingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final user = Supabase.instance.client.auth.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader(
          title: 'Settings',
          subtitle: 'Fertilizer recommendations and DA contact info',
        ),
        Expanded(
          child: settingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (settings) {
              _loadSettings(settings);
              return SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    _SettingsCard(
                      title: 'Admin Profile',
                      children: [
                        ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.admin_panel_settings),
                          ),
                          title: Text(
                            user?.email ?? 'Admin',
                            style: AppTheme.button,
                          ),
                          subtitle: Text(
                            'DA Regional Field Office XI',
                            style: AppTheme.body,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SettingsCard(
                      title: 'DA Office Contact',
                      children: [
                        TextField(
                          controller: _daPhone,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _daAddress,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _daHours,
                          decoration: const InputDecoration(
                            labelText: 'Office Hours',
                            prefixIcon: Icon(Icons.access_time),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SettingsCard(
                      title: 'Fertilizer Recommendations (per disease)',
                      children: [
                        TextField(
                          controller: _fertBlb,
                          decoration: const InputDecoration(
                            labelText: 'Bacterial Leaf Blight (BLB)',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _fertBlast,
                          decoration: const InputDecoration(
                            labelText: 'Rice Blast',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _fertTungro,
                          decoration: const InputDecoration(labelText: 'Tungro'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _fertHealthy,
                          decoration: const InputDecoration(labelText: 'Healthy'),
                          maxLines: 2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GoldButton(
                        label: 'Save Settings',
                        icon: Icons.save_rounded,
                        loading: _loading,
                        onPressed: _save,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.heading2),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
