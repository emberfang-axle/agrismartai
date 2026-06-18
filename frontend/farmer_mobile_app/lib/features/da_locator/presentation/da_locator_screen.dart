import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants.dart';
import '../../../shared/branding/app_brand.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_card.dart';

class DaLocatorScreen extends StatelessWidget {
  const DaLocatorScreen({super.key});

  Future<void> _openMaps() async {
    final uri = Uri.parse(AppStrings.daMapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _call() async {
    final uri = Uri.parse('tel:${AppStrings.daPhone.replaceAll(RegExp(r'[^\d+]'), '')}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DA Office Locator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AppCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF81C784), Color(0xFF388E3C)],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.map_rounded,
                        size: 80,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_pin,
                              color: Colors.white, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'DA Compound, Davao City',
                            style: AppBrand.button.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.daName, style: AppBrand.heading2),
                  const SizedBox(height: 20),
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    text: AppStrings.daAddress,
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: Icons.phone_rounded,
                    text: AppStrings.daPhone,
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: Icons.access_time_rounded,
                    text: AppStrings.daHours,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GoldButton(
              label: 'Get Directions',
              icon: Icons.directions_rounded,
              onPressed: _openMaps,
            ),
            const SizedBox(height: 12),
            GreenButton(
              label: 'Call Now',
              icon: Icons.call_rounded,
              onPressed: _call,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppBrand.secondary, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: AppBrand.body)),
      ],
    );
  }
}
