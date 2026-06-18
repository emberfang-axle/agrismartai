class ScanReport {
  final String id;
  final String userId;
  final String farmerName;
  final String email;
  final String barangay;
  final String disease;
  final double confidence;
  final String severity;
  final String status;
  final String? imageUrl;
  final DateTime createdAt;

  const ScanReport({
    required this.id,
    required this.userId,
    required this.farmerName,
    required this.email,
    required this.barangay,
    required this.disease,
    required this.confidence,
    required this.severity,
    required this.status,
    this.imageUrl,
    required this.createdAt,
  });

  String get displayDisease {
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

  factory ScanReport.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return ScanReport(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      farmerName: profile?['full_name'] as String? ?? 'Unknown',
      email: profile?['email'] as String? ?? '',
      barangay: profile?['barangay'] as String? ?? '',
      disease: json['disease'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      severity: json['severity'] as String? ?? 'Mild',
      status: json['status'] as String? ?? 'pending',
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class FarmerProfile {
  final String id;
  final String fullName;
  final String email;
  final String barangay;
  final int totalScans;
  final DateTime joinDate;

  const FarmerProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.barangay,
    required this.totalScans,
    required this.joinDate,
  });
}

class DashboardStats {
  final int totalFarmers;
  final int totalReports;
  final int pendingVerifications;
  final Map<String, int> diseasesByType;

  const DashboardStats({
    required this.totalFarmers,
    required this.totalReports,
    required this.pendingVerifications,
    required this.diseasesByType,
  });
}
