/// AgriSmartAI :: Farmer/user model for the admin dashboard.
/// OBJECTIVE 4: lists registered farmers and their scan activity.
class FarmerModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String barangay;
  final int totalScans;
  final int diseasedScans;
  final DateTime joinedAt;

  const FarmerModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.role = 'farmer',
    this.barangay = 'New Bataan',
    this.totalScans = 0,
    this.diseasedScans = 0,
    required this.joinedAt,
  });

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory FarmerModel.fromMap(Map<String, dynamic> map) => FarmerModel(
        id: map['id']?.toString() ?? '',
        fullName: map['full_name']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        phone: map['phone']?.toString(),
        role: map['role']?.toString() ?? 'farmer',
        barangay: map['barangay']?.toString() ?? 'New Bataan',
        totalScans: int.tryParse(map['total_scans']?.toString() ?? '0') ?? 0,
        diseasedScans:
            int.tryParse(map['diseased_scans']?.toString() ?? '0') ?? 0,
        joinedAt:
            DateTime.tryParse(map['created_at']?.toString() ?? '') ??
                DateTime.now(),
      );
}
