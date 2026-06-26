/// AgriSmartAI :: User model (mirrors supabase `profiles` table).
/// OBJECTIVE 3 & 4: identifies farmers/technicians for referral + evaluation.
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role; // 'farmer' | 'technician' | 'admin'
  final String barangay;
  final String municipality;
  final String province;
  final double? farmSizeHa;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.role = 'farmer',
    this.barangay = 'New Bataan',
    this.municipality = 'New Bataan',
    this.province = 'Davao de Oro',
    this.farmSizeHa,
    this.avatarUrl,
  });

  bool get isFarmer => role == 'farmer';
  bool get isStaff => role == 'technician' || role == 'admin';

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ??
          map['name']?.toString() ??
          '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString(),
      role: map['role']?.toString() ?? 'farmer',
      barangay: map['barangay']?.toString() ?? 'New Bataan',
      municipality: map['municipality']?.toString() ?? 'New Bataan',
      province: map['province']?.toString() ?? 'Davao de Oro',
      farmSizeHa: map['farm_size_ha'] == null
          ? null
          : double.tryParse(map['farm_size_ha'].toString()),
      avatarUrl: map['avatar_url']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'barangay': barangay,
        'municipality': municipality,
        'province': province,
        'farm_size_ha': farmSizeHa,
        'avatar_url': avatarUrl,
      };

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? barangay,
    double? farmSizeHa,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      barangay: barangay ?? this.barangay,
      municipality: municipality,
      province: province,
      farmSizeHa: farmSizeHa ?? this.farmSizeHa,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
