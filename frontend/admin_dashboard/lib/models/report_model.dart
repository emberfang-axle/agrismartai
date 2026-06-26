// AgriSmartAI :: Report + analytics models for the admin dashboard.
// OBJECTIVE 4: reports are verified/rejected by technicians/admins.

enum ReportStatus { pending, verified, rejected }

extension ReportStatusX on ReportStatus {
  String get label => switch (this) {
        ReportStatus.pending => 'Pending',
        ReportStatus.verified => 'Verified',
        ReportStatus.rejected => 'Rejected',
      };

  static ReportStatus fromString(String? v) => switch (v) {
        'verified' => ReportStatus.verified,
        'rejected' => ReportStatus.rejected,
        _ => ReportStatus.pending,
      };
}

class ReportModel {
  final String id;
  final String farmerName;
  final String barangay;
  final String diseaseCode;
  final String diseaseName;
  final double confidence; // OBJECTIVE 2
  final ReportStatus status;
  final String? imageUrl;
  final DateTime createdAt;
  final String? reviewerNote;

  const ReportModel({
    required this.id,
    required this.farmerName,
    required this.barangay,
    required this.diseaseCode,
    required this.diseaseName,
    required this.confidence,
    this.status = ReportStatus.pending,
    this.imageUrl,
    required this.createdAt,
    this.reviewerNote,
  });

  bool get isHealthy => diseaseCode == 'healthy';

  ReportModel copyWith({ReportStatus? status, String? reviewerNote}) =>
      ReportModel(
        id: id,
        farmerName: farmerName,
        barangay: barangay,
        diseaseCode: diseaseCode,
        diseaseName: diseaseName,
        confidence: confidence,
        status: status ?? this.status,
        imageUrl: imageUrl,
        createdAt: createdAt,
        reviewerNote: reviewerNote ?? this.reviewerNote,
      );

  factory ReportModel.fromMap(Map<String, dynamic> map) => ReportModel(
        id: map['id']?.toString() ?? '',
        farmerName: map['farmer_name']?.toString() ?? 'Unknown',
        barangay: map['barangay']?.toString() ?? 'New Bataan',
        diseaseCode: map['disease_code']?.toString() ?? 'healthy',
        diseaseName: map['disease_name']?.toString() ?? 'Healthy',
        confidence:
            double.tryParse(map['confidence']?.toString() ?? '0') ?? 0,
        status: ReportStatusX.fromString(map['status']?.toString()),
        imageUrl: map['image_url']?.toString(),
        createdAt:
            DateTime.tryParse(map['created_at']?.toString() ?? '') ??
                DateTime.now(),
        reviewerNote: map['reviewer_note']?.toString(),
      );
}

/// Aggregated count per disease (powers analytics charts).
class DiseaseStat {
  final String code;
  final String name;
  final int count;
  final double avgConfidence;

  const DiseaseStat({
    required this.code,
    required this.name,
    required this.count,
    required this.avgConfidence,
  });
}
