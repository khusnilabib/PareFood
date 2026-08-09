/// Profile use cases (PF-DOC-11 §3.1 domain layer). Pure Dart; no Flutter.
library;

import 'package:pare_util/pare_util.dart';

import '../data/profile_repository.dart';
import 'user_profile.dart';

/// Validates and applies profile edits. Validation errors surface as
/// `String?` messages for the form, not exceptions.
class UpdateProfile {
  const UpdateProfile(this._repository);

  final ProfileRepository _repository;

  /// Returns an error message or `null` when valid.
  String? validate({required String name, String? phone}) {
    final nameError = requiredValidator(name);
    if (nameError != null) return nameError;
    return phoneValidator(phone);
  }

  Future<UserProfile> call({
    required String name,
    String? phone,
    String? address,
  }) {
    return _repository.updateProfile(
      name: name,
      phone: phone,
      address: address,
    );
  }
}

/// Starts a phone number change (FR-AUTH-005): validates the new number,
/// then asks the backend to send a confirmation OTP to it.
class RequestPhoneChange {
  const RequestPhoneChange(this._repository);

  final ProfileRepository _repository;

  /// Returns an error message or `null` when valid.
  String? validate(String phone) {
    if (phone.trim().isEmpty) return 'Nomor HP wajib diisi.';
    return phoneValidator(phone);
  }

  Future<void> call(String phone) => _repository.requestPhoneChange(phone);
}

/// Re-sends the phone-change confirmation OTP (FR-AUTH-005). No validation:
/// the number was already checked by [RequestPhoneChange].
class ResendPhoneChangeOtp {
  const ResendPhoneChangeOtp(this._repository);

  final ProfileRepository _repository;

  Future<void> call(String phone) => _repository.resendPhoneChangeOtp(phone);
}

/// Verifies the phone-change OTP and saves the new number (FR-AUTH-005).
class VerifyPhoneChange {
  const VerifyPhoneChange(this._repository);

  final ProfileRepository _repository;

  /// Returns an error message or `null` when valid.
  String? validate(String token) {
    if (token.trim().isEmpty) return 'Kode OTP wajib diisi.';
    return otpValidator(token);
  }

  Future<UserProfile> call({required String newPhone, required String token}) {
    return _repository.verifyPhoneChange(newPhone: newPhone, token: token);
  }
}
