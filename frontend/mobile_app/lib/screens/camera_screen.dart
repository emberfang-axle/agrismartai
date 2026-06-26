import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:permission_handler/permission_handler.dart';

import '../models/scan_payload.dart';
import '../services/validation_service.dart';
import '../utils/constants.dart';
import 'loading_screen.dart';

/// AgriSmartAI — Rice leaf capture: live camera preview (mobile) + gallery backup.
class CameraScreen extends ConsumerStatefulWidget {
  static const route = '/camera';
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _imagePicker = picker.ImagePicker();
  final _validator = ValidationService();

  CameraController? _cameraController;
  bool _liveCameraActive = false;
  bool _cameraInitializing = false;
  String? _cameraError;

  Uint8List? _bytes;
  String? _path;
  bool _fromCamera = false;
  bool _busy = false;

  late final AnimationController _scanLineCtrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanLineCtrl.dispose();
    _disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed && _liveCameraActive) {
      _startLiveCamera();
    }
  }

  Future<void> _disposeCamera() async {
    final c = _cameraController;
    _cameraController = null;
    _liveCameraActive = false;
    if (c != null) {
      try {
        await c.dispose();
      } catch (_) {}
    }
  }

  // ─── Permissions ───────────────────────────────────────────────────────────

  Future<bool> _ensureCameraPermission() async {
    if (kIsWeb) return true;
    var status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      if (!mounted) return false;
      final open = await _showPermissionDialog(
        'Camera Permission',
        'Allow camera access to photograph rice leaves, or use Gallery upload instead.',
      );
      if (open) await openAppSettings();
      return false;
    }
    status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> _ensureGalleryPermission() async {
    if (kIsWeb) return true;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final photos = await Permission.photos.request();
      return photos.isGranted || photos.isLimited;
    }
    // Android 13+ system photo picker does not need storage permission.
    final photos = await Permission.photos.status;
    if (photos.isGranted || photos.isLimited) return true;
    final requested = await Permission.photos.request();
    if (requested.isGranted || requested.isLimited) return true;
    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  Future<bool> _showPermissionDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ─── Image loading ─────────────────────────────────────────────────────────

  Future<void> _applyImage(Uint8List raw, String? filePath, bool fromCamera) async {
    final prepared = _validator.prepareImageForScan(raw);
    if (!mounted) return;
    setState(() {
      _bytes = prepared;
      _path = filePath;
      _fromCamera = fromCamera;
      _cameraError = null;
    });
  }

  Future<void> _pickFromGallery() async {
    if (_busy) return;
    await _disposeCamera();
    setState(() {
      _busy = true;
      _cameraError = null;
    });

    try {
      picker.XFile? file;
      try {
        file = await _imagePicker.pickImage(
          source: picker.ImageSource.gallery,
          maxWidth: 1920,
          imageQuality: 90,
          requestFullMetadata: false,
        );
      } catch (_) {
        if (await _ensureGalleryPermission()) {
          file = await _imagePicker.pickImage(
            source: picker.ImageSource.gallery,
            maxWidth: 1920,
            imageQuality: 90,
            requestFullMetadata: false,
          );
        }
      }

      if (file == null) return;
      final raw = await file.readAsBytes();
      if (raw.isEmpty) throw Exception('Empty image file');
      await _applyImage(raw, file.path, false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gallery failed: $e. Tap Upload from Gallery to retry.'),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Web + fallback: image_picker opens browser / system camera UI.
  Future<void> _pickFromSystemCamera() async {
    if (_busy) return;
    await _disposeCamera();
    setState(() => _busy = true);
    try {
      if (!kIsWeb && !await _ensureCameraPermission()) return;
      final file = await _imagePicker.pickImage(
        source: picker.ImageSource.camera,
        maxWidth: 1920,
        imageQuality: 90,
        preferredCameraDevice: picker.CameraDevice.rear,
        requestFullMetadata: false,
      );
      if (file == null) return;
      final raw = await file.readAsBytes();
      await _applyImage(raw, file.path, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera failed: $e. Try Gallery upload instead.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Mobile: live camera preview via camera package.
  Future<void> _startLiveCamera() async {
    if (kIsWeb) {
      await _pickFromSystemCamera();
      return;
    }
    if (_cameraInitializing) return;
    if (!await _ensureCameraPermission()) {
      if (mounted) {
        setState(() => _cameraError = 'Camera permission denied. Use Gallery upload.');
      }
      return;
    }

    setState(() {
      _busy = true;
      _cameraInitializing = true;
      _cameraError = null;
      _bytes = null;
    });

    try {
      await _disposeCamera();
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('No camera found on this device');

      final lens = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        lens,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      _cameraController = controller;
      setState(() {
        _liveCameraActive = true;
        _cameraInitializing = false;
        _busy = false;
      });
    } catch (e) {
      await _disposeCamera();
      if (!mounted) return;
      setState(() {
        _cameraError = 'Live camera unavailable. Use Gallery or system camera.';
        _cameraInitializing = false;
        _busy = false;
      });
      await _pickFromSystemCamera();
    }
  }

  Future<void> _captureFromLivePreview() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() => _busy = true);
    try {
      final file = await controller.takePicture();
      final raw = await file.readAsBytes();
      await _applyImage(raw, file.path, true);
      await _disposeCamera();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Capture failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onTakePhotoPressed() async {
    if (_liveCameraActive && _cameraController?.value.isInitialized == true) {
      await _captureFromLivePreview();
    } else {
      await _startLiveCamera();
    }
  }

  void _analyze() {
    if (_bytes == null) return;
    Navigator.pushReplacementNamed(
      context,
      LoadingScreen.route,
      arguments: ScanPayload(
        bytes: _bytes!,
        path: _path,
        capturedAt: DateTime.now(),
        fromCamera: _fromCamera,
      ),
    );
  }

  void _clear() async {
    await _disposeCamera();
    if (!mounted) return;
    setState(() {
      _bytes = null;
      _path = null;
      _fromCamera = false;
      _cameraError = null;
    });
  }

  // ─── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasImage = _bytes != null;
    final showLivePreview = _liveCameraActive &&
        _cameraController != null &&
        _cameraController!.value.isInitialized &&
        !hasImage;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Row(
          children: [
            _BadgeLabel(),
            SizedBox(width: 10),
            Text('Scan Rice Leaf',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          if (hasImage || _liveCameraActive)
            TextButton.icon(
              onPressed: _busy ? null : _clear,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _ScanViewport(
                  bytes: _bytes,
                  scanLineCtrl: _scanLineCtrl,
                  fromCamera: _fromCamera,
                  hasImage: hasImage,
                  showLivePreview: showLivePreview,
                  cameraController: _cameraController,
                  cameraInitializing: _cameraInitializing,
                  cameraError: _cameraError,
                  onCapture: _busy ? null : _captureFromLivePreview,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                hasImage
                    ? 'Image ready — tap Analyze to run AI detection'
                    : showLivePreview
                        ? 'Frame the rice leaf, then tap the capture button'
                        : 'Upload from Gallery (recommended) or open live camera',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Upload from Gallery',
                      color: AppColors.deepGreen,
                      onTap: _busy ? null : _pickFromGallery,
                      loading: _busy && !_fromCamera && !_liveCameraActive,
                      primary: true,
                    ),
                    const SizedBox(height: 10),
                    _ActionButton(
                      icon: showLivePreview
                          ? Icons.camera
                          : Icons.camera_alt_rounded,
                      label: showLivePreview ? 'Capture Photo' : 'Take Photo',
                      color: AppColors.primary,
                      onTap: _busy ? null : _onTakePhotoPressed,
                      loading: _busy && (_fromCamera || _cameraInitializing),
                    ),
                    const SizedBox(height: 10),
                    _ActionButton(
                      icon: Icons.biotech_outlined,
                      label: 'Analyze Image',
                      color: hasImage ? AppColors.info : AppColors.caption,
                      onTap: hasImage && !_busy ? _analyze : null,
                    ),
                    const SizedBox(height: 12),
                    const _DiseaseTargetStrip(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _BadgeLabel extends StatelessWidget {
  const _BadgeLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'AI SCANNER',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _ScanViewport extends StatelessWidget {
  final Uint8List? bytes;
  final AnimationController scanLineCtrl;
  final bool fromCamera;
  final bool hasImage;
  final bool showLivePreview;
  final CameraController? cameraController;
  final bool cameraInitializing;
  final String? cameraError;
  final VoidCallback? onCapture;

  const _ScanViewport({
    required this.bytes,
    required this.scanLineCtrl,
    required this.fromCamera,
    required this.hasImage,
    required this.showLivePreview,
    required this.cameraController,
    required this.cameraInitializing,
    required this.cameraError,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasImage || showLivePreview
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.border,
          width: 1.5,
        ),
        color: Colors.black,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.memory(bytes!, fit: BoxFit.cover)
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 400))
          else if (showLivePreview && cameraController != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: cameraController!.value.previewSize?.height ?? 1,
                height: cameraController!.value.previewSize?.width ?? 1,
                child: CameraPreview(cameraController!),
              ),
            )
          else if (cameraInitializing)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 12),
                  Text('Starting camera...',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          else
            _EmptyViewport(error: cameraError),

          if (!hasImage && !showLivePreview && !cameraInitializing)
            AnimatedBuilder(
              animation: scanLineCtrl,
              builder: (_, __) => Positioned(
                top: scanLineCtrl.value *
                    (MediaQuery.sizeOf(context).height * 0.28),
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.primary.withValues(alpha: 0.5),
                        AppColors.aiAccent.withValues(alpha: 0.6),
                        AppColors.primary.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

          ..._corners(),

          if (showLivePreview && onCapture != null)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: onCapture,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: const Icon(Icons.circle, color: Colors.white, size: 56),
                  ),
                ),
              ),
            ),

          if (hasImage)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      fromCamera ? 'Camera' : 'Gallery',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            bottom: showLivePreview ? 100 : 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 12, color: Color(0xFF00E676)),
                  SizedBox(width: 4),
                  Text(
                    'MobileNetV2 Ready',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _corners() {
    const size = 20.0;
    const thick = 2.5;
    const color = AppColors.primary;
    const m = 12.0;

    Widget c(bool top, bool left) => Positioned(
          top: top ? m : null,
          bottom: top ? null : m,
          left: left ? m : null,
          right: left ? null : m,
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _CornerPainter(
                  top: top, left: left, thick: thick, color: color),
            ),
          ),
        );

    return [c(true, true), c(true, false), c(false, true), c(false, false)];
  }
}

class _CornerPainter extends CustomPainter {
  final bool top, left;
  final double thick;
  final Color color;
  const _CornerPainter({
    required this.top,
    required this.left,
    required this.thick,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = thick
      ..strokeCap = StrokeCap.round;

    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final dx = left ? size.width : -size.width;
    final dy = top ? size.height : -size.height;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), p);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _EmptyViewport extends StatelessWidget {
  final String? error;
  const _EmptyViewport({this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_library_outlined,
                  size: 52, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text('No image selected',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white)),
            const SizedBox(height: 6),
            Text(
              error ??
                  'Tap Upload from Gallery or Take Photo below',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;
  final bool primary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.loading = false,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final effectiveColor = disabled ? AppColors.caption : color;

    return SizedBox(
      height: primary ? 52 : 44,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? AppColors.border : effectiveColor,
          foregroundColor: Colors.white,
          elevation: disabled ? 0 : (primary ? 3 : 1),
          shadowColor: effectiveColor.withValues(alpha: 0.3),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: TextStyle(
              fontWeight: FontWeight.w600, fontSize: primary ? 15 : 13),
        ),
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, size: primary ? 20 : 17),
        label: Text(label),
      ),
    );
  }
}

class _DiseaseTargetStrip extends StatelessWidget {
  const _DiseaseTargetStrip();

  @override
  Widget build(BuildContext context) {
    const targets = [
      ('BLB', AppColors.warning),
      ('Rice Blast', AppColors.error),
      ('Tungro', Color(0xFF7B1FA2)),
      ('Healthy', AppColors.success),
    ];

    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: targets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final (name, color) = targets[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Text(name,
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.w600)),
          );
        },
      ),
    );
  }
}
