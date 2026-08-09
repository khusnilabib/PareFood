/// Fake repositories for hermetic app tests (TS-R06: no network/Supabase).
library;

import 'dart:typed_data';

import 'package:profile_feature/profile_feature.dart';

/// Returns a fixed profile; other operations are not exercised here.
class FakeProfileRepository implements ProfileRepository {
  static const profile = UserProfile(
    id: 'u1',
    name: 'Budi Santoso',
    phone: '+6281200000001',
    email: 'budi@example.com',
  );

  @override
  Future<UserProfile> fetchProfile() async => profile;

  @override
  Future<UserProfile> updateProfile({
    required String name,
    String? phone,
    String? address,
  }) => throw UnimplementedError();

  @override
  Future<String> updateAvatar({
    required Uint8List bytes,
    required String fileName,
  }) => throw UnimplementedError();

  @override
  Future<void> requestPhoneChange(String newPhone) =>
      throw UnimplementedError();

  @override
  Future<void> resendPhoneChangeOtp(String newPhone) =>
      throw UnimplementedError();

  @override
  Future<UserProfile> verifyPhoneChange({
    required String newPhone,
    required String token,
  }) => throw UnimplementedError();
}
