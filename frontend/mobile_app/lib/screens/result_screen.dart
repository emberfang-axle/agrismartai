import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/scan_model.dart';
import '../providers/scan_provider.dart';
import '../services/validation_service.dart';
import '../utils/constants.dart';
import '../widgets/app_decoration.dart';
import '../widgets/confidence_meter.dart';
import '../widgets/da_directive_card.dart';
import '../widgets/premium_ui.dart';
import 'chatbot_screen.dart';
import 'da_locator_screen.dart';
import 'main_shell.dart';

/// AgriSmartAI v2.0 — Enterprise detection result screen.
class ResultScreen extends ConsumerWidget {
  static const route = '/result';
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scanProvider);
    final result = state.lastResult;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: EmptyStateView(
          icon: Icons.error_outline,
          title: 'No result',
          message: 'No detection result available.',
          actionLabel: 'Go Home',
          onAction: () => Navigator.pushNamedAndRemoveUntil(
              context, MainShell.route, (r) => false),
        ),
      );
    }

    final knowledge = DiseaseData.byCode(result.diseaseCode);
    final info = result.diseaseInfo ??
        DiseaseInfo(
          code: knowledge.code,
          name: knowledge.name,
          scientificName: knowledge.scientificName,
          description: knowledge.description,
          symptoms: knowledge.symptoms,
          treatment: knowledge.treatment,
          fertilizer: knowledge.fertilizer,
          prevention: knowledge.prevention,
          daDirective: knowledge.daDirective,
          severity: knowledge.severity,
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('AI Diagnosis Report'),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context, MainShell.route, (r) => false),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Result',
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Hero result card
            _ResultHeroCard(
              result: result,
              knowledge: knowledge,
              imageBytes: state.lastImageBytes,
            ).animate().fadeIn().slideY(begin: 0.04, end: 0),
            const SizedBox(height: 16),
            // Confidence
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI Confidence Score',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.ink)),
                  const SizedBox(height: 14),
                  ConfidenceMeter(
                      confidence: result.confidence,
                      color: knowledge.color),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 14),
            DiagnosisSection(
              title: 'RISK ASSESSMENT',
              content: result.isRiceLeaf
                  ? (result.diseaseCode == 'healthy'
                      ? 'No disease detected — leaf appears healthy.'
                      : '${knowledge.severity} severity — ${knowledge.description}')
                  : 'Image did not pass rice leaf validation.',
              icon: Icons.shield_outlined,
              accent: knowledge.color,
            ).animate().fadeIn(delay: 120.ms),
            if (result.diseaseCode != 'healthy') ...[
              DiagnosisSection(
                title: 'TREATMENT PLAN',
                content: info.treatment,
                icon: Icons.medical_services_outlined,
                accent: AppColors.primary,
              ).animate().fadeIn(delay: 140.ms),
              _TreatmentSteps(steps: _treatmentSteps(info.treatment))
                  .animate()
                  .fadeIn(delay: 150.ms),
            ] else ...[
              DiagnosisSection(
                title: 'CROP STATUS',
                content: info.description,
                icon: Icons.eco_outlined,
                accent: AppColors.success,
              ).animate().fadeIn(delay: 140.ms),
            ],
            DiagnosisSection(
              title: 'EXPECTED RECOVERY',
              content: info.prevention,
              icon: Icons.trending_up_outlined,
              accent: AppColors.success,
            ).animate().fadeIn(delay: 160.ms),
            DiagnosisSection(
              title: 'FERTILIZER PROTOCOL',
              content: info.fertilizer,
              icon: Icons.grass_outlined,
              accent: AppColors.accent,
            ).animate().fadeIn(delay: 180.ms),
            const SizedBox(height: 4),
            if (result.diseaseCode != 'healthy')
              DaDirectiveCard(
                directive: info.daDirective,
                onLocate: () =>
                    Navigator.pushNamed(context, DaLocatorScreen.route),
              ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 20),
            // Action buttons
            _ActionButtons(
              onAskAI: () =>
                  Navigator.pushNamed(context, ChatbotScreen.route),
              onScanAgain: () {
                ref.read(scanProvider.notifier).clear();
                Navigator.pushNamedAndRemoveUntil(
                    context, MainShell.route, (r) => false);
              },
            ).animate().fadeIn(delay: 250.ms),
          ],
        ),
      ),
    );
  }
}

// ─── Hero card ────────────────────────────────────────────────────────────────
class _ResultHeroCard extends StatelessWidget {
  final DetectionResult result;
  final DiseaseKnowledge knowledge;
  final Uint8List? imageBytes;

  const _ResultHeroCard({
    required this.result,
    required this.knowledge,
    required this.imageBytes,
  });

  Color get _severityColor => switch (knowledge.severity.toLowerCase()) {
        'high' || 'severe' => AppColors.error,
        'moderate' || 'medium' => AppColors.warning,
        _ => AppColors.success,
      };

  bool get _isHealthy => result.diseaseCode == 'healthy';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Disease color header bar
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: knowledge.color,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Image
                if (imageBytes != null && imageBytes!.isNotEmpty) ...[
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ScanImagePreview(
                          bytes: imageBytes!,
                          height: 180,
                          width: double.infinity,
                        ),
                      ),
                      // Overlay badge
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome,
                                  size: 12,
                                  color: _isHealthy
                                      ? AppColors.success
                                      : AppColors.error),
                              const SizedBox(width: 4),
                              Text(
                                _isHealthy
                                    ? 'Healthy Crop'
                                    : 'Disease Detected',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                // Status chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _StatusChip(
                      label: _isHealthy ? 'HEALTHY' : 'DISEASE DETECTED',
                      color: knowledge.color,
                      icon: _isHealthy
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_rounded,
                    ),
                    _StatusChip(
                      label: knowledge.severity.toUpperCase(),
                      color: _severityColor,
                      icon: Icons.speed_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Disease name
                Text(
                  result.diseaseName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  '${result.confidence.toStringAsFixed(1)}% AI Confidence',
                  style: TextStyle(
                      color: knowledge.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusChip(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── Action buttons ───────────────────────────────────────────────────────────
class _TreatmentSteps extends StatelessWidget {
  final List<String> steps;
  const _TreatmentSteps({required this.steps});

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.format_list_numbered, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Treatment Steps',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Text('${e.key + 1}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AppColors.primary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(e.value,
                          style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: AppColors.muted)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

List<String> _treatmentSteps(String treatment) {
  final parts = treatment
      .split(RegExp(r'[.;]\s+'))
      .map((s) => s.trim())
      .where((s) => s.length > 8)
      .toList();
  if (parts.length >= 2) return parts.take(5).toList();
  return [
    'Identify affected plants and isolate the area',
    treatment,
    'Monitor field every 5–7 days and consult DA if symptoms spread',
  ];
}

// ─── Action buttons ───────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final VoidCallback onAskAI;
  final VoidCallback onScanAgain;
  const _ActionButtons(
      {required this.onAskAI, required this.onScanAgain});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onAskAI,
                icon: const Icon(Icons.smart_toy_outlined, size: 18),
                label: const Text('Ask AI'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onScanAgain,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Scan Again'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: AppColors.deepGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, DaLocatorScreen.route),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.account_balance_outlined, color: Colors.white),
            label: const Text('Request DA Assistance',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
