import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/constants.dart';

/// AgriSmartAI :: Department of Agriculture referral card (SPECIAL FEATURE 4).
/// OBJECTIVE 3: shown on EVERY detection result with a one-tap call/locate.
class DaDirectiveCard extends StatelessWidget {
  final String directive;
  final VoidCallback? onLocate;

  const DaDirectiveCard({
    super.key,
    required this.directive,
    this.onLocate,
  });

  Future<void> _call() async {
    // DA - New Bataan Municipal Agriculture Office (sample hotline).
    final uri = Uri(scheme: 'tel', path: '+63822345678');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deepGreen, AppColors.leafGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance, color: AppColors.warmGold),
              const SizedBox(width: 8),
              Text(
                'DA Referral Directive',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            directive,
            style: const TextStyle(color: Colors.white, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _call,
                  icon: const Icon(Icons.call, size: 18),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  label: const Text('Call DA'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onLocate,
                  icon: const Icon(Icons.location_on, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warmGold,
                    foregroundColor: AppColors.deepGreen,
                    minimumSize: const Size.fromHeight(46),
                  ),
                  label: const Text('Locate Office'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
