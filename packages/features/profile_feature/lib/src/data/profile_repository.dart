/// Profile repository contract (PF-DOC-11 §3.1 data layer).
///
/// Concrete implementations live in the app composition root and delegate to
/// `pare_data`; features never import the SDKs directly (MO-R02a). Overrides
/// of [profileRepositoryProvider] are the only test seam (FL-R04).
library;

import 'dart:typed_data';

import '../domain/user_profile.dart';

/// Contract implemented by the composition root.
abstract interface class ProfileRepository {
  /// Loads the signed-in user's profile.
  Future<UserProfile> fetchProfile();

  /// Applies a profile edit and returns the saved state.
  Future<UserProfile> updateProfile({
    required String name,
    String? phone,
    String? address,
  });

  /// Uploads an avatar image and returns its public URL (F2).
  Future<String> updateAvatar({
    required Uint8List bytes,
    required String fileName,
  });

  /// Starts a phone number change (FR-AUTH-005): a confirmation OTP is sent
  /// to [newPhone]. The number is only applied once [verifyPhoneChange]
  /// succeeds.
  Future<void> requestPhoneChange(String newPhone);

  /// Re-sends the phone-change confirmation OTP to [newPhone] (FR-AUTH-005).
  Future<void> resendPhoneChangeOtp(String newPhone);

  /// Verifies the phone-change [token], saves the new number and returns the
  /// updated profile (FR-AUTH-005).
  Future<UserProfile> verifyPhoneChange({
    required String newPhone,
    required String token,
  });
}
