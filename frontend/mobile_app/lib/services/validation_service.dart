import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ValidationResult {
  final bool isRiceLeaf;
  final String reason;
  final double greenRatio;
  final double aspectRatio;

  const ValidationResult({
    required this.isRiceLeaf,
    required this.reason,
    required this.greenRatio,
    required this.aspectRatio,
  });
}

/// Rice-leaf validation + image prep for detection pipeline.
class ValidationService {
  /// Minimum fraction of green-toned pixels (relaxed for field photos).
  static const double _minGreenRatio = 0.06;

  /// Rice leaves photographed close-up are usually elongated (not square).
  static const double _minAspectRatio = 1.1;

  /// Compress/resize before upload (max width 1280, JPEG 85%).
  Uint8List prepareImageForScan(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;
      final resized = decoded.width > 1280
          ? img.copyResize(decoded, width: 1280)
          : decoded;
      return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    } catch (_) {
      return bytes;
    }
  }

  ValidationResult validateBytes(Uint8List bytes, {bool fromCamera = false}) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const ValidationResult(
        isRiceLeaf: false,
        reason: 'Could not read the image. Please retake the photo.',
        greenRatio: 0,
        aspectRatio: 0,
      );
    }

    if (decoded.width < 64 || decoded.height < 64) {
      return const ValidationResult(
        isRiceLeaf: false,
        reason: 'Image is too small. Move closer to the rice leaf and retake.',
        greenRatio: 0,
        aspectRatio: 0,
      );
    }

    final aspectRatio = decoded.width >= decoded.height
        ? decoded.width / decoded.height
        : decoded.height / decoded.width;

    final small = img.copyResize(decoded, width: 128);
    int greenPixels = 0;
    final total = small.width * small.height;

    for (final p in small) {
      if (_isGreenPixel(p.r.toInt(), p.g.toInt(), p.b.toInt())) {
        greenPixels++;
      }
    }

    final greenRatio = total == 0 ? 0.0 : greenPixels / total;

    if (greenRatio < _minGreenRatio) {
      return ValidationResult(
        isRiceLeaf: false,
        reason:
            'This does not look like a rice leaf (not enough green). Frame a single green leaf and try again.',
        greenRatio: greenRatio,
        aspectRatio: aspectRatio,
      );
    }

    // Camera close-ups may be nearly square; gallery uploads should be elongated.
    final needsElongated = !fromCamera;
    if (needsElongated && aspectRatio < _minAspectRatio) {
      return ValidationResult(
        isRiceLeaf: false,
        reason:
            'Image shape does not match a rice leaf. Use a close-up of one elongated green leaf.',
        greenRatio: greenRatio,
        aspectRatio: aspectRatio,
      );
    }

    return ValidationResult(
      isRiceLeaf: true,
      reason: 'Valid rice leaf detected.',
      greenRatio: greenRatio,
      aspectRatio: aspectRatio,
    );
  }

  /// HSV-based green detection — more accurate than simple RGB threshold.
  bool _isGreenPixel(int r, int g, int b) {
    final maxC = [r, g, b].reduce((a, c) => a > c ? a : c);
    final minC = [r, g, b].reduce((a, c) => a < c ? a : c);
    if (maxC < 30) return false;

    final delta = maxC - minC;
    if (delta < 8) return false;

    double hue;
    if (maxC == r) {
      hue = 60 * (((g - b) / delta) % 6);
    } else if (maxC == g) {
      hue = 60 * (((b - r) / delta) + 2);
    } else {
      hue = 60 * (((r - g) / delta) + 4);
    }
    if (hue < 0) hue += 360;

    final saturation = maxC == 0 ? 0.0 : delta / maxC;
    final value = maxC / 255.0;

    // Green hue range with moderate saturation (field + indoor lighting).
    final inGreenHue = hue >= 55 && hue <= 165;
    final vividGreen = g > r && g > b && g > 40 && saturation > 0.12;

    return (inGreenHue && saturation > 0.10 && value > 0.12) || vividGreen;
  }
}

/// Cross-platform image preview (Web + Mobile).
class ScanImagePreview extends StatelessWidget {
  final Uint8List? bytes;
  final String? path;
  final BoxFit fit;
  final double? height;
  final double? width;

  const ScanImagePreview({
    super.key,
    required this.bytes,
    this.path,
    this.fit = BoxFit.cover,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (bytes != null && bytes!.isNotEmpty) {
      return Image.memory(bytes!, fit: fit, height: height, width: width);
    }
    return Container(
      height: height,
      width: width,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported_outlined),
    );
  }
}
