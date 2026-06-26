import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/constants.dart';
import '../utils/farming_tips.dart';

/// Weather & farming conditions — New Bataan.
class WeatherScreen extends StatelessWidget {
  static const route = '/weather';
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const days = [
      ('Mon', Icons.wb_sunny_outlined, '29°', '20%'),
      ('Tue', Icons.cloud_outlined, '27°', '45%'),
      ('Wed', Icons.grain, '26°', '70%'),
      ('Thu', Icons.wb_cloudy_outlined, '28°', '35%'),
      ('Fri', Icons.wb_sunny_outlined, '30°', '15%'),
      ('Sat', Icons.thunderstorm_outlined, '27°', '80%'),
      ('Sun', Icons.wb_sunny_outlined, '29°', '25%'),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Weather'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: AppTheme.greenGradient,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Bataan, Davao de Oro',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                const SizedBox(height: 8),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('28°',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.w300)),
                    Text('C',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 24)),
                  ],
                ),
                const Text('Partly Cloudy',
                    style: TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.98, 0.98)),
          const SizedBox(height: 16),
          Row(
            children: [
              _metric(Icons.water_drop_outlined, 'Humidity', '78%'),
              _metric(Icons.air, 'Wind', '12 km/h'),
              _metric(Icons.umbrella_outlined, 'Rain', '35%'),
            ],
          ),
          const SizedBox(height: 24),
          const Text('7-Day Forecast',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          ...days.map((d) {
            final (day, icon, temp, rain) = d;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  SizedBox(
                      width: 40,
                      child: Text(day,
                          style: const TextStyle(fontWeight: FontWeight.w600))),
                  Icon(icon, color: AppColors.primary),
                  const Spacer(),
                  Text('Rain $rain',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(width: 16),
                  Text(temp,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.agriculture, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Farming tip: ${FarmingTips.today()}',
                    style: const TextStyle(fontSize: 13, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
