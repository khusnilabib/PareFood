/// Fake repositories for hermetic app tests (TS-R06: no network/Supabase).
library;

import 'package:auth_feature/auth_feature.dart';

/// Records sign-out calls; the session stream is overridden separately.
class FakeAuthRepository implements AuthRepository {
  int signOutCount = 0;

  @override
  Stream<AuthSession?> watchSession() => const Stream.empty();

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<AuthOutcome> signUpWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> sendPhoneOtp(String phone) => throw UnimplementedError();

  @override
  Future<AuthSession> verifyPhoneOtp({
    required String phone,
    required String token,
  }) => throw UnimplementedError();

  @override
  Future<void> requestPasswordReset(String email) => throw UnimplementedError();

  @override
  Future<void> signOut() async {
    signOutCount++;
  }
}
