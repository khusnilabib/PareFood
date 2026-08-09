/// Auth data transfer objects (PF-DOC-11 §3.3).
library;

/// Session DTO backed by a Supabase auth session.
class AuthSessionDto {
  const AuthSessionDto({
    required this.userId,
    required this.email,
    required this.role,
    this.phone = '',
  });

  final String userId;
  final String email;

  /// Verified phone number in E.164 (`+62…`), empty when unset.
  final String phone;

  /// Mirrored `profiles.role` claim (PF-DOC-12 §3.2).
  final String role;

  factory AuthSessionDto.fromMap(Map<String, dynamic> map) {
    return AuthSessionDto(
      userId: map['sub'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: _readRole(map),
    );
  }

  static String _readRole(Map<String, dynamic> map) {
    final meta = map['app_metadata'];
    if (meta is Map<String, dynamic>) {
      final role = meta['role'];
      if (role is String && role.isNotEmpty) return role;
    }
    return 'customer';
  }
}

/// User DTO from the auth user object.
class AuthUserDto {
  const AuthUserDto({required this.id, required this.email, this.role});

  final String id;
  final String email;
  final String? role;
}
