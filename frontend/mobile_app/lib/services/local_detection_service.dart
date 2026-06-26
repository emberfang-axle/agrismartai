import 'dart:typed_data';

import '../models/scan_model.dart';
import '../utils/constants.dart';
import 'visual_detection_service.dart';

/// Offline detection — uses visual analysis when backend is unreachable.
class LocalDetectionService {
  static DetectionResult simulate(Uint8List imageBytes) {
    final classified = VisualDetectionService.classify(imageBytes);
    final code = classified.code;
    final confidence = classified.confidence;
    final knowledge = DiseaseData.byCode(code);

    return DetectionResult(
      diseaseCode: code,
      diseaseName: knowledge.name,
      confidence: confidence,
      isRiceLeaf: true,
      modelVersion: 'mobilenetv2-visual-local',
      message: code == 'healthy'
          ? 'No disease detected. Leaf appears healthy (${confidence.toStringAsFixed(1)}% confidence).'
          : 'Detected ${knowledge.name} with ${confidence.toStringAsFixed(1)}% confidence.',
      diseaseInfo: DiseaseInfo(
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
      ),
    );
  }
}
