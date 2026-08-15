/// Auth use cases (PF-DOC-11 §3.1 domain layer). Pure Dart; no Flutter.
library;

import 'package:pare_util/pare_util.dart';

import '../data/auth_repository.dart';
import 'auth_session.dart';

/// Validates credentials and delegates to [AuthRepository.signInWithEmail].
class SignInWithEmail {
  const SignInWithEmail(this._repository);

  final AuthRepository _repository;

  /// Returns `null` when [email]/[password] pass validation, else an error
  /// message surfaced by the form.
  String? validate({required String email, required String password}) {
    final emailError = emailValidator(email);
    if (emailError != null) return emailError;
    return minLengthValidator(password, minLength: 8);
  }

  Future<AuthSession> call({required String email, required String password}) {
    return _repository.signInWithEmail(email: email, password: password);
  }
}

/// Validates registration fields and creates a customer account
/// (FR-AUTH-001).
class SignUpWithEmail {
  const SignUpWithEmail(this._repository);

  final AuthRepository _repository;

  /// Returns an error message, or `null` when all fields pass validation.
  String? validate({
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    final emailError = emailValidator(email);
    if (emailError != null) return emailError;
    final passwordError = minLengthValidator(password, minLength: 8);
    if (passwordError != null) return passwordError;
    if (password != confirmPassword) {
      return 'Konfirmasi kata sandi tidak sama.';
    }
    return null;
  }

  Future<AuthOutcome> call({required String email, required String password}) {
    return _repository.signUpWithEmail(email: email, password: password);
  }
}

/// Validates the phone number and requests an SMS one-time code
/// (FR-AUTH-001).
class SendPhoneOtp {
  const SendPhoneOtp(this._repository);

  final AuthRepository _repository;

  /// Returns an error message, or `null` when [phone] is valid.
  String? validate({required String phone}) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return 'Nomor HP wajib diisi.';
    return phoneValidator(trimmed);
  }

  Future<void> call({required String phone}) {
    return _repository.sendPhoneOtp(phone);
  }
}

/// Validates the OTP code and completes phone sign-in (FR-AUTH-001).
class VerifyPhoneOtp {
  const VerifyPhoneOtp(this._repository);

  final AuthRepository _repository;

  /// Returns an error message, or `null` when [token] is a 6-digit code.
  String? validate({required String token}) {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return 'Kode OTP wajib diisi.';
    return otpValidator(trimmed);
  }

  Future<AuthSession> call({required String phone, required String token}) {
    return _repository.verifyPhoneOtp(phone: phone, token: token);
  }
}

/// Validates the email and requests a password reset link (FR-AUTH-005).
class RequestPasswordReset {
  const RequestPasswordReset(this._repository);

  final AuthRepository _repository;

  /// Returns an error message or `null` when valid.
  String? validate({required String email}) => emailValidator(email);

  Future<void> call({required String email}) {
    return _repository.requestPasswordReset(email);
  }
}

/// Fetches every role the signed-in user holds (FR-AUTH-006).
class FetchRoles {
  const FetchRoles(this._repository);
  final AuthRepository _repository;
  Future<List<String>> call() => _repository.fetchRoles();
}

/// Switches the active role (FR-AUTH-006). The role must be held by the user;
/// the repository throws `PareAuthException` otherwise.
class SwitchRole {
  const SwitchRole(this._repository);
  final AuthRepository _repository;
  Future<void> call(String role) => _repository.switchRole(role);
}
