import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/constants.dart';
import '../widgets/app_decoration.dart';

/// DA office locator with professional cards and map/call actions.
class DaOffice {
  final String name;
  final String address;
  final String phone;
  final double lat;
  final double lng;
  final String tag;
  const DaOffice(this.name, this.address, this.phone, this.lat, this.lng, this.tag);
}

class DaLocatorScreen extends StatelessWidget {
  static const route = '/da-locator';
  const DaLocatorScreen({super.key});

  static const List<DaOffice> _offices = [
    DaOffice(
      'Municipal Agriculture Office',
      'Poblacion (Cabinuangan), New Bataan, Davao de Oro',
      '+63 82 234 5678',
      7.5500,
      126.2400,
      'Nearest to you',
    ),
    DaOffice(
      'Provincial Agriculture Office',
      'Capitol Compound, Nabunturan, Davao de Oro',
      '+63 84 376 0123',
      7.6050,
      125.9650,
      'Provincial',
    ),
    DaOffice(
      'DA Regional Field Office XI',
      'Bago Oshiro, Tugbok District, Davao City',
      '+63 82 293 0136',
      7.0731,
      125.5300,
      'Regional',
    ),
  ];

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openMap(DaOffice o) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${o.lat},${o.lng}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('DA Office Locator'),
        elevation: 0,
      ),
      body: AgricultureBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppDecoration.hero(radius: 20),
              child: const Row(
                children: [
                  Icon(Icons.account_balance_rounded, color: Colors.white, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Contact the Department of Agriculture for field inspection, '
                      'subsidies, and resistant seed varieties.',
                      style: TextStyle(color: Colors.white, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader(
              title: 'Nearby offices',
              subtitle: 'New Bataan and Davao de Oro region',
            ),
            const SizedBox(height: 12),
            ..._offices.map((o) => _officeCard(context, o)),
          ],
        ),
      ),
    );
  }

  Widget _officeCard(BuildContext context, DaOffice o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppDecoration.card(border: true),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(o.name, style: Theme.of(context).textTheme.titleMedium),
                ),
                StatusBadge(label: o.tag, color: AppColors.aiBlue, icon: Icons.place_outlined),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow(Icons.location_on_outlined, o.address),
            const SizedBox(height: 6),
            _infoRow(Icons.phone_outlined, o.phone),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _call(o.phone),
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.deepGreen,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openMap(o),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: AppColors.muted, height: 1.35))),
      ],
    );
  }
}
