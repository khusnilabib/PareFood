/// Input validators used across PareFood forms (sign-up, addresses, checkout).
library;

final RegExp _emailPattern = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
);

/// Indonesian phone number formats, e.g. `081234567890`, `+62 812-3456-7890`.
final RegExp _phonePattern = RegExp(r'^(\+62|0)8[0-9]{8,12}$');

/// Returns an error message when [value] is empty, otherwise `null`.
String? requiredValidator(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return 'Field wajib diisi.';
  return null;
}

/// Returns an error message when [value] is not a valid email, else `null`.
String? emailValidator(String? value) {
  final candidate = value?.trim() ?? '';
  if (candidate.isEmpty) {
    return null;
  }
  if (!_emailPattern.hasMatch(candidate)) return 'Format email tidak valid.';
  return null;
}

/// Returns an error message when [value] is not a valid Indonesian phone
/// number, else `null`.
String? phoneValidator(String? value) {
  final candidate = value?.trim() ?? '';
  if (candidate.isEmpty) {
    return null;
  }
  final normalized = candidate.replaceAll(RegExp(r'[\s\-]'), '');
  if (!_phonePattern.hasMatch(normalized)) {
    return 'Format nomor HP tidak valid.';
  }
  return null;
}

/// Returns an error message when [value] is not a 6-digit OTP code, else
/// `null`. Empty values pass; combine with [requiredValidator] when mandatory.
String? otpValidator(String? value) {
  final candidate = value?.trim() ?? '';
  if (candidate.isEmpty) {
    return null;
  }
  if (!RegExp(r'^[0-9]{6}$').hasMatch(candidate)) {
    return 'Kode OTP harus 6 digit.';
  }
  return null;
}

/// Returns an error message when [value] is less than [minLength] chars.
String? minLengthValidator(String? value, {int minLength = 6}) {
  final candidate = value?.trim() ?? '';
  if (candidate.isEmpty) {
    return null;
  }
  if (candidate.length < minLength) {
    return 'Minimal $minLength karakter.';
  }
  return null;
}
