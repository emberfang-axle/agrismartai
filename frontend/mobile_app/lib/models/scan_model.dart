/// AgriSmartAI :: Scan + detection models (mirrors supabase `scans` table).
library;

class DiseaseInfo {
  final String code;
  final String name;
  final String scientificName;
  final String description;
  final String symptoms;
  final String treatment;
  final String fertilizer;
  final String prevention;
  final String daDirective;
  final String severity;

  const DiseaseInfo({
    required this.code,
    required this.name,
    this.scientificName = '',
    this.description = '',
    this.symptoms = '',
    this.treatment = '',
    this.fertilizer = '',
    this.prevention = '',
    this.daDirective = '',
    this.severity = 'Moderate',
  });

  factory DiseaseInfo.fromMap(Map<String, dynamic> map) => DiseaseInfo(
        code: map['code']?.toString() ?? 'healthy',
        name: map['name']?.toString() ?? 'Healthy',
        scientificName: map['scientific_name']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        symptoms: map['symptoms']?.toString() ?? '',
        treatment: map['treatment']?.toString() ?? '',
        fertilizer: map['fertilizer']?.toString() ?? '',
        prevention: map['prevention']?.toString() ?? '',
        daDirective: map['da_directive']?.toString() ?? '',
        severity: map['severity_label']?.toString() ?? 'Moderate',
      );
}

class ScanModel {
  final String id;
  final String userId;
  final String? diseaseId;
  final String diseaseCode;
  final String diseaseName;
  final double confidence;
  final String modelVersion;
  final bool isRiceLeaf;
  final String? imagePath;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String barangay;
  final DateTime createdAt;

  const ScanModel({
    required this.id,
    required this.userId,
    this.diseaseId,
    required this.diseaseCode,
    required this.diseaseName,
    required this.confidence,
    this.modelVersion = 'mobilenetv2-sim-1.0',
    this.isRiceLeaf = true,
    this.imagePath,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.barangay = 'New Bataan',
    required this.createdAt,
  });

  bool get isHealthy => diseaseCode == 'healthy';

  ScanModel copyWith({String? diseaseId, String? imageUrl}) => ScanModel(
        id: id,
        userId: userId,
        diseaseId: diseaseId ?? this.diseaseId,
        diseaseCode: diseaseCode,
        diseaseName: diseaseName,
        confidence: confidence,
        modelVersion: modelVersion,
        isRiceLeaf: isRiceLeaf,
        imagePath: imagePath,
        imageUrl: imageUrl ?? this.imageUrl,
        latitude: latitude,
        longitude: longitude,
        barangay: barangay,
        createdAt: createdAt,
      );

  factory ScanModel.fromMap(Map<String, dynamic> map) => ScanModel(
        id: map['id']?.toString() ?? '',
        userId: map['user_id']?.toString() ?? '',
        diseaseId: map['disease_id']?.toString(),
        diseaseCode: map['disease_code']?.toString() ??
            _codeFromLabel(map['disease_label']?.toString()),
        diseaseName: map['disease_name']?.toString() ??
            map['disease_label']?.toString() ??
            'Healthy',
        confidence: double.tryParse(
              map['confidence']?.toString() ??
                  map['confidence_score']?.toString() ??
                  '0',
            ) ??
            0,
        modelVersion:
            map['model_version']?.toString() ?? 'mobilenetv2-sim-1.0',
        isRiceLeaf: map['is_rice_leaf'] == null
            ? true
            : map['is_rice_leaf'] == true,
        imageUrl: map['image_url']?.toString(),
        latitude: map['latitude'] == null
            ? null
            : double.tryParse(map['latitude'].toString()),
        longitude: map['longitude'] == null
            ? null
            : double.tryParse(map['longitude'].toString()),
        barangay: map['barangay']?.toString() ?? 'New Bataan',
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );

  static String _codeFromLabel(String? label) {
    if (label == null) return 'healthy';
    final l = label.toLowerCase();
    if (l.contains('blight')) return 'bacterial_leaf_blight';
    if (l.contains('blast')) return 'rice_blast';
    if (l.contains('tungro')) return 'tungro';
    return 'healthy';
  }

  Map<String, dynamic> toInsertMap() => {
        'disease_id': diseaseId,
        'user_id': userId,
        'disease_code': diseaseCode,
        'disease_name': diseaseName,
        'confidence': confidence,
        'model_version': modelVersion,
        'is_rice_leaf': isRiceLeaf,
        'image_url': imageUrl,
        'latitude': latitude,
        'longitude': longitude,
        'barangay': barangay,
      };
}

class DetectionResult {
  final String diseaseCode;
  final String diseaseName;
  final double confidence;
  final bool isRiceLeaf;
  final String modelVersion;
  final String message;
  final DiseaseInfo? diseaseInfo;
  final String? scanId;

  const DetectionResult({
    required this.diseaseCode,
    required this.diseaseName,
    required this.confidence,
    required this.isRiceLeaf,
    this.modelVersion = 'mobilenetv2-visual-1.0',
    this.message = '',
    this.diseaseInfo,
    this.scanId,
  });

  factory DetectionResult.fromMap(Map<String, dynamic> map) => DetectionResult(
        diseaseCode: map['disease_code']?.toString() ?? 'healthy',
        diseaseName: map['disease_name']?.toString() ?? 'Healthy',
        confidence:
            double.tryParse(map['confidence']?.toString() ?? '0') ?? 0,
        isRiceLeaf: map['is_rice_leaf'] == true,
        modelVersion:
            map['model_version']?.toString() ?? 'mobilenetv2-sim-1.0',
        message: map['message']?.toString() ?? '',
        diseaseInfo: map['disease_info'] is Map<String, dynamic>
            ? DiseaseInfo.fromMap(map['disease_info'] as Map<String, dynamic>)
            : null,
        scanId: map['scan_id']?.toString(),
      );
}
