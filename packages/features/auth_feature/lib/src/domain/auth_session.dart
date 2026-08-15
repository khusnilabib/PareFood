/// Auth session state (PF-DOC-11 §3.2 `authStateProvider`).
///
/// FR-AUTH-006 (multi-role): a user may hold several roles; [roles] is the
/// full set and [role] is the currently active one (mirrored into the JWT).
library;

/// Signed-in identity. Immutable; equality is value-based.
class AuthSession {
  const AuthSession({
    required this.userId,
    required this.email,
    this.displayName,
    this.phone = '',
    this.role = 'customer',
    this.roles = const ['customer'],
  });

  /// Stable user id (Supabase auth.uid()).
  final String userId;

  /// Verified email.
  final String email;

  /// Verified phone number in E.164 (`+62…`), empty when unset.
  final String phone;

  /// Display name, when the user has set one.
  final String? displayName;

  /// The currently active role (mirrored `profiles.role`, PF-DOC-12 §3.2).
  /// Drives role-based navigation guards (PF-DOC-17 §3.6).
  final String role;

  /// Every role the user holds (FR-AUTH-006). Defaults to `[role]` for
  /// backward compatibility with single-role accounts. When more than one,
  /// the UI offers a role switcher.
  final List<String> roles;

  bool get isSignedIn => userId.isNotEmpty;

  /// Whether the session carries the [required] role claim (guards, PF-DOC-17).
  bool hasRole(String required) => role == required;

  /// Whether the user can switch to additional roles (FR-AUTH-006).
  bool get canSwitchRole => roles.length > 1;

  AuthSession copyWith({String? role, List<String>? roles}) {
    return AuthSession(
      userId: userId,
      email: email,
      phone: phone,
      displayName: displayName,
      role: role ?? this.role,
      roles: roles ?? this.roles,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuthSession &&
        other.userId == userId &&
        other.email == email &&
        other.phone == phone &&
        other.displayName == displayName &&
        other.role == role &&
        _listEquals(other.roles, roles);
  }

  @override
  int get hashCode {
    // Order-insensitive: XOR the individual role hashCodes so ['customer',
    // 'driver'] and ['driver', 'customer'] collide (matches _listEquals).
    var rolesHash = 0;
    for (final r in roles) {
      rolesHash ^= r.hashCode;
    }
    return Object.hash(userId, email, phone, displayName, role, rolesHash);
  }

  // Order-insensitive list equality for the roles set.
  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }
}
