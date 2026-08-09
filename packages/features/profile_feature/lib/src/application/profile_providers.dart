/// Profile providers (PF-DOC-11 §3.2).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_repository.dart';
import '../data/supabase_profile_repository.dart';
import '../domain/profile_use_cases.dart';
import '../domain/user_profile.dart';

/// Repository contract. Defaults to the `pare_data`-backed adapter; the app
/// composition root or tests may override it (FL-R04).
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository();
});

/// Loads the signed-in user's profile.
final profileProvider = FutureProvider<UserProfile>((ref) {
  return ref.watch(profileRepositoryProvider).fetchProfile();
});

/// Validates and applies profile edits.
final updateProfileProvider = Provider<UpdateProfile>((ref) {
  return UpdateProfile(ref.watch(profileRepositoryProvider));
});

/// Starts a phone number change with OTP confirmation (FR-AUTH-005).
final requestPhoneChangeProvider = Provider<RequestPhoneChange>((ref) {
  return RequestPhoneChange(ref.watch(profileRepositoryProvider));
});

/// Re-sends the phone-change confirmation OTP (FR-AUTH-005).
final resendPhoneChangeOtpProvider = Provider<ResendPhoneChangeOtp>((ref) {
  return ResendPhoneChangeOtp(ref.watch(profileRepositoryProvider));
});

/// Verifies the phone-change OTP and saves the new number (FR-AUTH-005).
final verifyPhoneChangeProvider = Provider<VerifyPhoneChange>((ref) {
  return VerifyPhoneChange(ref.watch(profileRepositoryProvider));
});
