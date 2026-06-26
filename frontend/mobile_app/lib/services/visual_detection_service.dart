import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Visual rice disease classification (mirrors backend visual_detection.py).
class VisualDetectionService {
  static const _classes = [
    'bacterial_leaf_blight',
    'rice_blast',
    'tungro',
    'healthy',
  ];

  static ({String code, double confidence}) classify(Uint8List imageBytes) {
    if (imageBytes.isEmpty) {
      return (code: 'healthy', confidence: 0);
    }

    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      return (code: 'healthy', confidence: 0);
    }

    final rgb = img.copyResize(decoded, width: 256, height: 256);
    final w = rgb.width;
    final h = rgb.height;
    final total = w * h;

    var greenCount = 0;
    var yellowCount = 0;
    var orangeCount = 0;
    var brownCount = 0;
    var grayCount = 0;

    final greenMask = List.generate(h, (_) => List<bool>.filled(w, false));
    final yellowMask = List.generate(h, (_) => List<bool>.filled(w, false));
    final lesionMask = List.generate(h, (_) => List<bool>.filled(w, false));

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final p = rgb.getPixel(x, y);
        final r = p.r.toInt();
        final g = p.g.toInt();
        final b = p.b.toInt();

        final isGreen = _isGreen(r, g, b);
        final isYellow = _isYellow(r, g, b);
        final isOrange = _isOrange(r, g, b);
        final isBrown = _isBrown(r, g, b);
        final isGray = _isGray(r, g, b);

        if (isGreen) {
          greenCount++;
          greenMask[y][x] = true;
        }
        if (isYellow) {
          yellowCount++;
          yellowMask[y][x] = true;
        }
        if (isOrange) orangeCount++;
        if (isBrown) brownCount++;
        if (isGray) grayCount++;

        if (isBrown || isGray) {
          lesionMask[y][x] = true;
        }
      }
    }

    final greenRatio = greenCount / total;
    final yellowRatio = yellowCount / total;
    final orangeRatio = orangeCount / total;
    final brownRatio = brownCount / total;
    final grayRatio = grayCount / total;
    final lesionRatio = (brownCount + grayCount) / total;

    final stripe = _stripeScore(yellowMask, greenMask);
    final spots = _spotScore(lesionMask, greenMask, lesionRatio, greenRatio);
    final uniformity = _uniformityScore(greenMask);

    final scores = <String, double>{
      'healthy': 0.35 +
          greenRatio * 2.4 +
          uniformity * 1.2 -
          lesionRatio * 2.0 -
          yellowRatio * 1.0 -
          orangeRatio * 1.3,
      'bacterial_leaf_blight':
          0.12 + yellowRatio * 2.6 + stripe * 2.0 + greenRatio * 0.35,
      'rice_blast':
          0.10 + spots * 2.4 + brownRatio * 2.4 + grayRatio * 1.5,
      'tungro': 0.08 + orangeRatio * 3.0 + yellowRatio * 1.4 - greenRatio * 0.7,
    };

    if (greenRatio > 0.45 &&
        lesionRatio < 0.025 &&
        yellowRatio < 0.07 &&
        orangeRatio < 0.06) {
      scores['healthy'] = scores['healthy']! + 1.4;
    }
    if (orangeRatio > 0.10 || (yellowRatio > 0.16 && greenRatio < 0.28)) {
      scores['tungro'] = scores['tungro']! + 1.1;
    }
    if (stripe > 0.30 && yellowRatio > 0.05 && greenRatio > 0.15) {
      scores['bacterial_leaf_blight'] = scores['bacterial_leaf_blight']! + 1.2;
    }
    if (spots > 0.16 && greenRatio > 0.16) {
      scores['rice_blast'] = scores['rice_blast']! + 1.5;
    }
    if (spots > 0.32) {
      scores['rice_blast'] = scores['rice_blast']! + 0.9;
    }

    final probs = _softmax(scores);
    var predicted = _classes.first;
    var best = -1.0;
    for (final c in _classes) {
      if (probs[c]! > best) {
        best = probs[c]!;
        predicted = c;
      }
    }

    return (code: predicted, confidence: _displayConfidence(probs, predicted));
  }

  static bool _isGreen(int r, int g, int b) =>
      (g > r + 8) && (g > b + 8) && (g > 45);

  static bool _isYellow(int r, int g, int b) =>
      r > 95 && g > 95 && b < 130 && (r + g) > (b + 80);

  static bool _isOrange(int r, int g, int b) =>
      r > 140 && g > 90 && g < 185 && b < 110 && r > g;

  static bool _isBrown(int r, int g, int b) =>
      r > 65 && g < 120 && b < 95 && r > g && (r - g) < 95;

  static bool _isGray(int r, int g, int b) =>
      (r - g).abs() < 32 && (g - b).abs() < 32 && r < 170 && r > 50;

  static double _stripeScore(List<List<bool>> yellow, List<List<bool>> green) {
    final h = yellow.length;
    final w = yellow[0].length;
    if (h < 8 || w < 8) return 0;

    final rowYellow = List<double>.generate(h, (y) {
      var c = 0;
      for (var x = 0; x < w; x++) {
        if (yellow[y][x]) c++;
      }
      return c / w;
    });
    final rowGreen = List<double>.generate(h, (y) {
      var c = 0;
      for (var x = 0; x < w; x++) {
        if (green[y][x]) c++;
      }
      return c / w;
    });

    final active = <double>[];
    for (var i = 0; i < h; i++) {
      if (rowGreen[i] > 0.08) active.add(rowYellow[i]);
    }
    if (active.length < 4) return 0;

    final mean = active.reduce((a, b) => a + b) / active.length;
    var variance = 0.0;
    for (final v in active) {
      variance += (v - mean) * (v - mean);
    }
    variance /= active.length;

    final peakRatio = active.reduce(max) / max(mean, 1e-6);
    return min(1.0, variance * 16.0 + max(0.0, peakRatio - 1.15) * 0.4);
  }

  static double _spotScore(
    List<List<bool>> lesion,
    List<List<bool>> green,
    double lesionRatio,
    double greenRatio,
  ) {
    if (greenRatio < 0.12 || lesionRatio < 0.004) {
      return lesionRatio * 8.0;
    }

    final h = lesion.length;
    final w = lesion[0].length;
    const block = 12;
    final blockHits = <double>[];

    for (var y = 0; y < h - block; y += block ~/ 2) {
      for (var x = 0; x < w - block; x += block ~/ 2) {
        var patchGreen = 0;
        var patchLesion = 0;
        for (var dy = 0; dy < block; dy++) {
          for (var dx = 0; dx < block; dx++) {
            if (green[y + dy][x + dx]) patchGreen++;
            if (lesion[y + dy][x + dx]) patchLesion++;
          }
        }
        final gMean = patchGreen / (block * block);
        final lMean = patchLesion / (block * block);
        if (gMean > 0.20 && lMean > 0.03) blockHits.add(lMean);
      }
    }

    final clusterBonus = min(1.0, blockHits.length * 0.15);
    final maxBlock = blockHits.isEmpty ? lesionRatio : blockHits.reduce(max);
    return min(1.0, lesionRatio * 10.0 + clusterBonus + maxBlock * 2.5);
  }

  static double _uniformityScore(List<List<bool>> green) {
    final h = green.length;
    final w = green[0].length;
    if (h < 16 || w < 16) return 0;

    const block = 16;
    final means = <double>[];
    for (var y = 0; y < h - block; y += block) {
      for (var x = 0; x < w - block; x += block) {
        var c = 0;
        for (var dy = 0; dy < block; dy++) {
          for (var dx = 0; dx < block; dx++) {
            if (green[y + dy][x + dx]) c++;
          }
        }
        final m = c / (block * block);
        if (m > 0.25) means.add(m);
      }
    }
    if (means.length < 4) return 0;

    final avg = means.reduce((a, b) => a + b) / means.length;
    var variance = 0.0;
    for (final m in means) {
      variance += (m - avg) * (m - avg);
    }
    variance /= means.length;
    return 1.0 - min(1.0, sqrt(variance) * 4.0);
  }

  static Map<String, double> _softmax(Map<String, double> scores) {
    final maxVal = scores.values.reduce(max);
    final weights = <String, double>{};
    var total = 0.0;
    for (final e in scores.entries) {
      final v = exp(e.value - maxVal);
      weights[e.key] = v;
      total += v;
    }
    return {
      for (final e in weights.entries) e.key: e.value / (total == 0 ? 1 : total)
    };
  }

  static double _displayConfidence(Map<String, double> probs, String predicted) {
    final raw = probs[predicted] ?? 0;
    final sorted = probs.values.toList()..sort((a, b) => b.compareTo(a));
    final margin = sorted.length > 1 ? sorted[0] - sorted[1] : sorted[0];
    final base = raw * 100.0;

    if (margin < 0.06) {
      return double.parse(min(base, 38.0 + margin * 350.0).toStringAsFixed(2));
    }
    if (margin < 0.15) {
      return double.parse(min(base, 52.0 + margin * 220.0).toStringAsFixed(2));
    }
    if (margin >= 0.40 && raw >= 0.50) {
      return double.parse(
        min(98.5, max(85.0, 80.0 + raw * 18.0)).toStringAsFixed(2),
      );
    }
    return double.parse(min(98.5, max(55.0, base)).toStringAsFixed(2));
  }
}
