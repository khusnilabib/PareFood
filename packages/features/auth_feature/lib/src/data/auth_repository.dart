/// Auth repository contract (PF-DOC-11 §3.1 data layer).
///
/// Concrete implementations live in the app composition root and delegate to
/// `pare_data` (Supabase sessions); features never import the Supabase SDK
/// directly (MO-R02a). Overrides of [authRepositoryProvider] are the only test
/// seam (FL-R04).
library;

import '../domain/auth_session.dart';

/// Result of a password sign-up attempt.
enum AuthOutcome { success, emailInUse, invalidCredentials, failure }

/// Contract implemented by the composition root.
abstract interface class AuthRepository {
  /// Stream of the current session; emits `null` while signed out.
  Stream<AuthSession?> watchSession();

  /// Authenticates with email + password. Throws `PareException` subtypes
  /// (`auth/invalid_credentials`) on failure (PF-DOC-11 §3.5).
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  });

  /// Creates an account. Returns [AuthOutcome] for expected collisions.
  Future<AuthOutcome> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Sends an SMS one-time code to [phone] (FR-AUTH-001). Throws
  /// `PareException` subtypes on failure.
  Future<void> sendPhoneOtp(String phone);

  /// Verifies the SMS [token] for [phone] and returns the session
  /// (FR-AUTH-001). Throws `PareException` subtypes when rejected.
  Future<AuthSession> verifyPhoneOtp({
    required String phone,
    required String token,
  });

  /// Sends a password reset email (FR-AUTH-005). Throws `PareException`
  /// subtypes on failure.
  Future<void> requestPasswordReset(String email);

  /// Ends the session.
  Future<void> signOut();
}
