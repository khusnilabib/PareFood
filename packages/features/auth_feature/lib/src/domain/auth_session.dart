/// Auth session state (PF-DOC-11 §3.2 `authStateProvider`).
library;

/// Signed-in identity. Immutable; equality is value-based.
class AuthSession {
  const AuthSession({
    required this.userId,
    required this.email,
    this.displayName,
    this.phone = '',
  });

  /// Stable user id (Supabase auth.uid()).
  final String userId;

  /// Verified email.
  final String email;

  /// Verified phone number in E.164 (`+62…`), empty when unset.
  final String phone;

  /// Display name, when the user has set one.
  final String? displayName;

  bool get isSignedIn => userId.isNotEmpty;

  @override
  bool operator ==(Object other) {
    return other is AuthSession &&
        other.userId == userId &&
        other.email == email &&
        other.phone == phone &&
        other.displayName == displayName;
  }

  @override
  int get hashCode => Object.hash(userId, email, phone, displayName);
}
