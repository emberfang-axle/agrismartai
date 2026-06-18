class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String barangay;
  final String? avatarUrl;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.barangay,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: (json['full_name'] ?? 'Farmer') as String,
      email: (json['email'] ?? '') as String,
      barangay: (json['barangay'] ?? 'Batinao') as String,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
