import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/di/providers.dart';
import '../../../shared/branding/app_brand.dart';
import '../../../shared/widgets/app_buttons.dart';
import 'analyzing_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final _picker = ImagePicker();
  File? _image;
  bool _flashOn = false;
  String? _validationMsg;
  bool? _isValid;

  Future<void> _capture(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final validation = ref.read(detectionRepositoryProvider).validateRiceLeaf(file);

    setState(() {
      _image = file;
      _isValid = validation.isValid;
      _validationMsg = validation.isValid
          ? validation.message
          : validation.message;
    });

    if (validation.isValid && mounted) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AnalyzingScreen(imageFile: file),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_image != null) {
      return _PreviewView(
        image: _image!,
        isValid: _isValid ?? false,
        message: _validationMsg ?? '',
        onRetake: () => setState(() {
          _image = null;
          _isValid = null;
          _validationMsg = null;
        }),
        onUse: _isValid == true
            ? () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnalyzingScreen(imageFile: _image!),
                  ),
                )
            : null,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1B4332), Color(0xFF081C15)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.eco_rounded,
                    size: 80,
                    color: AppBrand.accent.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Position rice leaf in frame',
                    style: AppBrand.body.copyWith(color: Colors.white60),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.height * 0.45,
              decoration: BoxDecoration(
                border: Border.all(color: AppBrand.secondary, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                      const Spacer(),
                      Text(
                        'Scan Rice Leaf',
                        style: AppBrand.button.copyWith(color: Colors.white),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _CircleBtn(
                        icon: Icons.photo_library_rounded,
                        onTap: () => _capture(ImageSource.gallery),
                      ),
                      GestureDetector(
                        onTap: () => _capture(ImageSource.camera),
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.08, 1.08),
                              duration: 1000.ms,
                            ),
                      ),
                      _CircleBtn(
                        icon: _flashOn
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        onTap: () => setState(() => _flashOn = !_flashOn),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _PreviewView extends StatelessWidget {
  final File image;
  final bool isValid;
  final String message;
  final VoidCallback onRetake;
  final VoidCallback? onUse;

  const _PreviewView({
    required this.image,
    required this.isValid,
    required this.message,
    required this.onRetake,
    this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(image, fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AppBrand.button.copyWith(
                  color: isValid ? AppBrand.accent : Colors.red.shade300,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlineButton(
                      label: 'Retake',
                      color: Colors.white,
                      onPressed: onRetake,
                    ),
                  ),
                  if (onUse != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: GoldButton(label: 'Use Photo', onPressed: onUse),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
