class ScanResult {
  final String? id;
  final String disease;
  final double confidence;
  final String severity;
  final String fertilizerTip;
  final String managementTip;
  final String? imageUrl;
  final String? localImagePath;
  final DateTime? createdAt;

  const ScanResult({
    this.id,
    required this.disease,
    required this.confidence,
    required this.severity,
    required this.fertilizerTip,
    required this.managementTip,
    this.imageUrl,
    this.localImagePath,
    this.createdAt,
  });

  String get displayName {
    switch (disease.toUpperCase()) {
      case 'BLB':
        return 'Bacterial Leaf Blight';
      case 'BLAST':
        return 'Rice Blast';
      case 'TUNGRO':
        return 'Tungro';
      default:
        return disease;
    }
  }

  bool get isSevere => severity.toLowerCase().contains('severe');

  Map<String, dynamic> toChatContext() => {
        'disease': displayName,
        'confidence': confidence,
        'severity': severity,
        'fertilizer_tip': fertilizerTip,
        'management_tip': managementTip,
      };

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'] as String?,
      disease: (json['disease'] ?? 'Healthy') as String,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.85,
      severity: (json['severity'] ?? 'Mild') as String,
      fertilizerTip: (json['fertilizer_tip'] ?? json['fertilizer_recommendations']?[0] ?? '') as String,
      managementTip: (json['management_tip'] ?? json['fertilizer_recommendations']?[1] ?? '') as String,
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toInsertJson(String userId) => {
        'user_id': userId,
        'disease': disease,
        'confidence': confidence,
        'severity': severity,
        'fertilizer_tip': fertilizerTip,
        'management_tip': managementTip,
        'image_url': imageUrl,
        'status': 'pending',
      };

  ScanResult copyWith({String? localImagePath}) => ScanResult(
        id: id,
        disease: disease,
        confidence: confidence,
        severity: severity,
        fertilizerTip: fertilizerTip,
        managementTip: managementTip,
        imageUrl: imageUrl,
        localImagePath: localImagePath ?? this.localImagePath,
        createdAt: createdAt,
      );
}
