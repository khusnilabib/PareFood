/// Supabase-backed auth data source (PF-DOC-11 §3.3).
///
/// Feature-agnostic: returns DTOs and maps SDK errors to `pare_core`
/// exceptions. Does not know any feature contract.
library;

import 'package:pare_core/pare_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_bootstrap.dart';
import 'dto/auth_dto.dart';

/// Result of a password sign-up attempt (expected collisions).
enum AuthSignUpResult { success, emailInUse, failure }

/// Concrete Supabase implementation of the auth surface.
class SupabaseAuthDataSource {
  SupabaseAuthDataSource({SupabaseClient? client}) : _override = client;

  /// Injected client, resolved lazily so constructing a data source does not
  /// require [SupabaseBootstrap] to be initialised (test seam).
  final SupabaseClient? _override;

  SupabaseClient get _client => _override ?? SupabaseBootstrap.client;

  /// Stream of signed-in sessions; emits `null` on sign-out.
  Stream<AuthSessionDto?> watchSession() {
    return _client.auth.onAuthStateChange.map(
      (state) => state.session == null ? null : _sessionFrom(state.session!),
    );
  }

  /// Signs in with email + password (FR-AUTH-001).
  Future<AuthSessionDto> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final session = res.session;
      if (session == null) {
        throw const PareAuthException(
          'Your credentials could not be verified.',
        );
      }
      return _sessionFrom(session);
    } on AuthException catch (e) {
      throw PareAuthException(_message(e), e);
    }
  }

  /// Creates an account (FR-AUTH-002). [role] mirrors the app entry point;
  /// the signup trigger creates the `profiles` row (migration 0002).
  Future<AuthSignUpResult> signUpWithEmail({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: <String, dynamic>{'role': role},
      );
      return AuthSignUpResult.success;
    } on AuthException catch (e) {
      if (_isEmailInUse(e)) return AuthSignUpResult.emailInUse;
      throw PareAuthException(_message(e), e);
    }
  }

  /// Sends a one-time code to [phone] via SMS (FR-AUTH-001). The number is
  /// normalised to E.164 (`08…` → `+628…`) before hitting GoTrue.
  Future<void> sendPhoneOtp(String phone) async {
    try {
      await _client.auth.signInWithOtp(phone: _toE164(phone));
    } on AuthException catch (e) {
      throw PareAuthException(_message(e), e);
    }
  }

  /// Verifies the SMS [token] for [phone] and returns the session
  /// (FR-AUTH-001). Throws [PareAuthException] when the code is rejected or
  /// no session is established.
  Future<AuthSessionDto> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    try {
      final res = await _client.auth.verifyOTP(
        phone: _toE164(phone),
        token: token,
        type: OtpType.sms,
      );
      final session = res.session;
      if (session == null) {
        throw const PareAuthException('The OTP code could not be verified.');
      }
      return _sessionFrom(session);
    } on AuthException catch (e) {
      throw PareAuthException(_message(e), e);
    }
  }

  /// Requests a phone number change for the signed-in user (FR-AUTH-005).
  /// GoTrue sends a confirmation OTP to [newPhone]; the number is applied
  /// only after [verifyPhoneChange] succeeds.
  Future<void> requestPhoneChange(String newPhone) async {
    try {
      await _client.auth.updateUser(UserAttributes(phone: _toE164(newPhone)));
    } on AuthException catch (e) {
      throw PareAuthException(_message(e), e);
    }
  }

  /// Verifies the phone-change [token] sent to [newPhone] and returns the
  /// refreshed session (FR-AUTH-005). Throws [PareAuthException] when the
  /// code is rejected or no session is returned.
  Future<AuthSessionDto> verifyPhoneChange({
    required String newPhone,
    required String token,
  }) async {
    try {
      final res = await _client.auth.verifyOTP(
        phone: _toE164(newPhone),
        token: token,
        type: OtpType.phoneChange,
      );
      final session = res.session;
      if (session == null) {
        throw const PareAuthException('The OTP code could not be verified.');
      }
      return _sessionFrom(session);
    } on AuthException catch (e) {
      throw PareAuthException(_message(e), e);
    }
  }

  /// Re-sends the phone-change confirmation OTP to [newPhone] (FR-AUTH-005).
  Future<void> resendPhoneChangeOtp(String newPhone) async {
    try {
      await _client.auth.resend(
        phone: _toE164(newPhone),
        type: OtpType.phoneChange,
      );
    } on AuthException catch (e) {
      throw PareAuthException(_message(e), e);
    }
  }

  /// Sends a password reset email (FR-AUTH-005). Reset link expires in 24 h
  /// (PF-DOC-19 §3.2).
  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw PareAuthException(_message(e), e);
    }
  }

  /// Ends the session (FR-AUTH-004).
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw PareAuthException(_message(e), e);
    }
  }

  /// The id of the signed-in user, or throws [PareAuthException] when signed out.
  String get currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const PareAuthException('Not signed in.');
    }
    return user.id;
  }

  /// The email of the signed-in user, or empty when signed out.
  String get currentUserEmail => _client.auth.currentUser?.email ?? '';

  AuthSessionDto _sessionFrom(Session session) {
    final user = session.user;
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final appMetadata = user.appMetadata;
    return AuthSessionDto(
      userId: user.id,
      email: user.email ?? '',
      phone: user.phone ?? '',
      role:
          appMetadata['role'] as String? ??
          metadata['role'] as String? ??
          'customer',
    );
  }

  /// Normalises Indonesian input (`08…`, `62…`, `+62…`, with spaces/dashes)
  /// to the E.164 form GoTrue expects.
  String _toE164(String phone) {
    final digits = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (digits.startsWith('+')) return digits;
    if (digits.startsWith('0')) return '+62${digits.substring(1)}';
    if (digits.startsWith('62')) return '+$digits';
    return digits;
  }

  bool _isEmailInUse(AuthException e) {
    final msg = e.message.toLowerCase();
    return msg.contains('already registered') ||
        msg.contains('already been registered') ||
        msg.contains('duplicate key') ||
        msg.contains('email');
  }

  String _message(AuthException e) {
    final raw = e.message;
    final lower = raw.toLowerCase();
    if (lower.contains('token has expired') || lower.contains('expired')) {
      return 'The OTP code has expired. Request a new one.';
    }
    if (lower.contains('token not found') ||
        lower.contains('invalid otp') ||
        lower.contains('otp invalid') ||
        lower.contains('token is invalid')) {
      return 'The OTP code is incorrect. Please try again.';
    }
    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (lower.contains('invalid phone') || lower.contains('phone')) {
      return 'The phone number could not be verified.';
    }
    if (lower.contains('invalid login') ||
        lower.contains('invalid credentials')) {
      return 'The email or password you entered is incorrect.';
    }
    return 'Sign-in failed. Please try again.';
  }
}
