/// Profile data transfer object (PF-DOC-11 §3.3).
library;

/// Profile DTO backed by the `profiles` table (PF-DOC-13).
class ProfileDto {
  const ProfileDto({
    required this.id,
    required this.role,
    required this.fullName,
    required this.phone,
    this.avatarUrl,
    this.status = 'active',
  });

  final String id;
  final String role;
  final String fullName;
  final String phone;
  final String? avatarUrl;
  final String status;

  factory ProfileDto.fromMap(Map<String, dynamic> map) {
    return ProfileDto(
      id: map['id'] as String? ?? '',
      role: map['role'] as String? ?? 'customer',
      fullName: map['full_name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      status: map['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'role': role,
    'full_name': fullName,
    'phone': phone,
    'avatar_url': avatarUrl,
    'status': status,
  };
}
