/// The signed-in user's public profile.
library;

/// Immutable user profile. Equality is value-based.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? avatarUrl;

  @override
  bool operator ==(Object other) {
    return other is UserProfile &&
        other.id == id &&
        other.name == name &&
        other.phone == phone &&
        other.email == email &&
        other.address == address &&
        other.avatarUrl == avatarUrl;
  }

  @override
  int get hashCode => Object.hash(id, name, phone, email, address, avatarUrl);
}
