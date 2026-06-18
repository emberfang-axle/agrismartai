import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../scan/domain/scan_result.dart';
import '../../../core/di/providers.dart';
import '../../../shared/branding/app_brand.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_card.dart';
import 'camera_screen.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../da_locator/presentation/da_locator_screen.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final ScanResult result;
  final File imageFile;

  const ResultScreen({
    super.key,
    required this.result,
    required this.imageFile,
  });

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _save() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(scanRepositoryProvider).saveScan(
            userId: user.id,
            result: widget.result,
            imageFile: widget.imageFile,
          );
      ref.invalidate(scansProvider);
      ref.invalidate(userStatsProvider);
      setState(() => _saved = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to history!')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save — check connection')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _askAi() {
    ref.read(scanContextProvider.notifier).state = widget.result;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final gradient = AppBrand.diseaseGradient(r.displayName);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Text(
                      'Detection Result',
                      style: AppBrand.button.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  widget.imageFile,
                  height: 140,
                  width: 140,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                r.displayName,
                style: AppBrand.heading1.copyWith(
                  color: Colors.white,
                  fontSize: 32,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ConfidenceRing(confidence: r.confidence),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Text(
                  r.isSevere ? '⚠️ SEVERE' : '✅ MILD',
                  style: AppBrand.button.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppBrand.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Treatment Plan', style: AppBrand.heading2),
                              const SizedBox(height: 20),
                              _StepRow(
                                number: '①',
                                title: 'Fertilizer',
                                body: r.fertilizerTip,
                              ),
                              const Divider(height: 28),
                              _StepRow(
                                number: '②',
                                title: 'Management',
                                body: r.managementTip,
                              ),
                              const Divider(height: 28),
                              GreenButton(
                                label: 'Consult DA Office',
                                icon: Icons.location_on_rounded,
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const DaLocatorScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GoldButton(
                          label: _saved ? 'Saved ✓' : 'Save to History',
                          loading: _saving,
                          onPressed: _saved ? null : _save,
                        ),
                        const SizedBox(height: 12),
                        OutlineButton(
                          label: 'New Scan',
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CameraScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GreenButton(
                          label: '💬 Ask AI About This',
                          onPressed: _askAi,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _StepRow({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(number, style: AppBrand.heading2.copyWith(color: AppBrand.secondary)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppBrand.button),
              const SizedBox(height: 4),
              Text(body, style: AppBrand.body),
            ],
          ),
        ),
      ],
    );
  }
}
