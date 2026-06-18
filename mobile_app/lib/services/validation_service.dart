// OBJECTIVE 1: Rice leaf validation ensures only rice leaf images are analyzed

import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

class ValidationResult {
  final bool isValid;
  final String message;
  final bool hasGreen;
  final bool hasElongatedShape;
  final bool hasLeafTexture;
  final double greenRatio;
  final double edgeRatio;
  final double aspectRatio;

  const ValidationResult({
    required this.isValid,
    required this.message,
    this.hasGreen = false,
    this.hasElongatedShape = false,
    this.hasLeafTexture = false,
    this.greenRatio = 0,
    this.edgeRatio = 0,
    this.aspectRatio = 1,
  });
}

class ValidationService {
  /// Validates that an image likely contains a rice leaf.
  ///
  /// Rules:
  /// 1. GREEN color — rice leaves are green (G > R and G > B)
  /// 2. ELONGATED shape — width/height > 2:1 OR < 0.67
  /// 3. LEAF texture — simple edge detection on grayscale
  static Future<ValidationResult> validateRiceLeaf(File file) async {
    const failMsg = '❌ Not a rice leaf. Please take a photo of a rice leaf only.';

    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      return const ValidationResult(isValid: false, message: failMsg);
    }

    final greenRatio = _greenRatio(image);
    final hasGreen = greenRatio >= 0.18;

    final aspect = image.width / image.height;
    // Elongated: wider than 2:1 OR taller than 1:0.67
    final hasElongated = aspect > 2.0 || aspect < 0.67;
    // Phone photos of leaves often fill frame with green — accept high green as leaf-in-frame
    final hasElongatedShape = hasElongated || greenRatio >= 0.32;

    final edgeRatio = _edgeDensity(image);
    final hasLeafTexture = edgeRatio >= 0.04;

    if (!hasGreen || !hasElongatedShape || !hasLeafTexture) {
      return ValidationResult(
        isValid: false,
        message: failMsg,
        hasGreen: hasGreen,
        hasElongatedShape: hasElongatedShape,
        hasLeafTexture: hasLeafTexture,
        greenRatio: greenRatio,
        edgeRatio: edgeRatio,
        aspectRatio: aspect,
      );
    }

    return ValidationResult(
      isValid: true,
      message: '✓ Rice leaf detected! Analyzing...',
      hasGreen: true,
      hasElongatedShape: true,
      hasLeafTexture: true,
      greenRatio: greenRatio,
      edgeRatio: edgeRatio,
      aspectRatio: aspect,
    );
  }

  static double _greenRatio(img.Image image) {
    var green = 0;
    var sampled = 0;
    const step = 4;

    for (var y = 0; y < image.height; y += step) {
      for (var x = 0; x < image.width; x += step) {
        final p = image.getPixel(x, y);
        final r = p.r.toInt();
        final g = p.g.toInt();
        final b = p.b.toInt();
        sampled++;
        if (g > r + 12 && g > b + 12 && g > 45) green++;
      }
    }
    return sampled == 0 ? 0 : green / sampled;
  }

  static double _edgeDensity(img.Image image) {
    var edges = 0;
    var sampled = 0;
    const step = 3;
    final gray = img.grayscale(image);

    for (var y = step; y < gray.height - step; y += step) {
      for (var x = step; x < gray.width - step; x += step) {
        final c = gray.getPixel(x, y).r.toInt();
        final r = gray.getPixel(x + step, y).r.toInt();
        final d = gray.getPixel(x, y + step).r.toInt();
        sampled++;
        if ((c - r).abs() > 26 || (c - d).abs() > 26) edges++;
      }
    }
    return sampled == 0 ? 0 : edges / sampled;
  }
}

/// OBJECTIVE 2: Simulated disease detection (replace with TFLite model for final defense)
class DetectionService {
  static const diseases = [
    'Bacterial Leaf Blight',
    'Rice Blast',
    'Tungro',
    'Healthy',
  ];

  static Map<String, dynamic> simulateDetection() {
    final r = Random();
    final disease = diseases[r.nextInt(diseases.length)];
    final confidence = 0.70 + r.nextDouble() * 0.28;
    return {
      'disease': disease,
      'confidence': confidence,
      'fertilizer': _fertilizerFor(disease),
    };
  }

  static List<String> _fertilizerFor(String disease) {
    switch (disease) {
      case 'Bacterial Leaf Blight':
        return [
          'Reduce nitrogen fertilizer by 30% immediately',
          'Apply muriate of potash (MOP) at 40 kg/ha',
          'Drain flooded fields and consult DA for copper-based bactericide',
        ];
      case 'Rice Blast':
        return [
          'Apply silicon-based fertilizer (calcium silicate) at 200 kg/ha',
          'Reduce nitrogen — use balanced NPK 14-14-14',
          'Spray tricyclazole fungicide per DA RFO XI recommendation',
        ];
      case 'Tungro':
        return [
          'Apply balanced NPK with extra potassium',
          'Control green leafhoppers with recommended insecticide',
          'Replant with tungro-resistant variety (NSIC Rc 222)',
        ];
      default:
        return [
          'Continue regular NPK schedule (14-14-14 at tillering)',
          'Apply zinc sulfate if leaves show yellowing',
          'Monitor weekly and maintain proper water level',
        ];
    }
  }
}
