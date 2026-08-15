/// Auth providers (PF-DOC-11 §3.2). Widgets consume these only; presentation
/// never imports `data` directly.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/auth_session.dart';
import '../domain/auth_use_cases.dart';

/// Repository contract. Defaults to the `pare_data`-backed adapter; the app
/// composition root or tests may override it (FL-R04).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

/// Current session or `null` while signed out.
final authSessionProvider = StreamProvider<AuthSession?>((ref) {
  return ref.watch(authRepositoryProvider).watchSession();
});

/// Validates credentials and signs in.
final signInUseCaseProvider = Provider<SignInWithEmail>((ref) {
  return SignInWithEmail(ref.watch(authRepositoryProvider));
});

/// Validates registration fields and creates a customer account.
final signUpUseCaseProvider = Provider<SignUpWithEmail>((ref) {
  return SignUpWithEmail(ref.watch(authRepositoryProvider));
});

/// Requests an SMS one-time code for phone sign-in (FR-AUTH-001).
final sendPhoneOtpProvider = Provider<SendPhoneOtp>((ref) {
  return SendPhoneOtp(ref.watch(authRepositoryProvider));
});

/// Verifies an SMS one-time code and completes phone sign-in (FR-AUTH-001).
final verifyPhoneOtpProvider = Provider<VerifyPhoneOtp>((ref) {
  return VerifyPhoneOtp(ref.watch(authRepositoryProvider));
});

/// Sends a password reset email (FR-AUTH-005).
final requestPasswordResetProvider = Provider<RequestPasswordReset>((ref) {
  return RequestPasswordReset(ref.watch(authRepositoryProvider));
});

/// Fetches every role the signed-in user holds (FR-AUTH-006).
final fetchRolesUseCaseProvider = Provider<FetchRoles>((ref) {
  return FetchRoles(ref.watch(authRepositoryProvider));
});

/// Switches the active role (FR-AUTH-006).
final switchRoleUseCaseProvider = Provider<SwitchRole>((ref) {
  return SwitchRole(ref.watch(authRepositoryProvider));
});

/// The full set of roles the signed-in user holds. Hydrated after sign-in
/// by the app shell; falls back to the active role until populated.
final userRolesProvider = FutureProvider<List<String>>((ref) {
  // Re-run when the session changes.
  ref.watch(authSessionProvider);
  return ref.watch(fetchRolesUseCaseProvider).call();
});

/// Ends the current session (FR-AUTH-006). Returns a callable (not a cached
/// [FutureProvider]) so sign-out can be retried after transient failures.
final signOutProvider = Provider<Future<void> Function()>((ref) {
  return () => ref.read(authRepositoryProvider).signOut();
});
