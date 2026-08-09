import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_data/pare_data.dart';
import 'package:profile_feature/profile_feature.dart';

void main() {
  final avatarBytes = Uint8List.fromList(<int>[1, 2, 3, 4]);

  group('SupabaseProfileRepository.fetchProfile', () {
    test('maps the profile DTO and the auth email', () async {
      final fake = _FakeProfileDataSource(
        profile: const ProfileDto(
          id: 'u1',
          role: 'customer',
          fullName: 'Budi Santoso',
          phone: '081234567890',
          avatarUrl: 'https://example.com/avatars/u1.png',
        ),
      );
      final repo = SupabaseProfileRepository(
        auth: _FakeAuthDataSource(),
        profiles: fake,
      );

      final profile = await repo.fetchProfile();

      expect(
        profile,
        const UserProfile(
          id: 'u1',
          name: 'Budi Santoso',
          phone: '081234567890',
          email: 'budi@example.com',
          avatarUrl: 'https://example.com/avatars/u1.png',
        ),
      );
      expect(fake.fetchedUserId, 'u1');
    });

    test('propagates data source errors', () async {
      final fake = _FakeProfileDataSource(
        fetchError: const PareNotFoundException('Profile not found.'),
      );
      final repo = SupabaseProfileRepository(
        auth: _FakeAuthDataSource(),
        profiles: fake,
      );

      expect(repo.fetchProfile(), throwsA(isA<PareNotFoundException>()));
    });
  });

  group('SupabaseProfileRepository.updateProfile', () {
    test('maps the updated DTO and the auth email', () async {
      final fake = _FakeProfileDataSource(
        profile: const ProfileDto(
          id: 'u1',
          role: 'customer',
          fullName: 'Budi Baru',
          phone: '082211112222',
        ),
      );
      final repo = SupabaseProfileRepository(
        auth: _FakeAuthDataSource(),
        profiles: fake,
      );

      final profile = await repo.updateProfile(
        name: 'Budi Baru',
        phone: '082211112222',
      );

      expect(profile.name, 'Budi Baru');
      expect(profile.phone, '082211112222');
      expect(profile.email, 'budi@example.com');
      expect(fake.updatedUserId, 'u1');
      expect(fake.updatedFullName, 'Budi Baru');
      expect(fake.updatedPhone, '082211112222');
    });
  });

  group('SupabaseProfileRepository.updateAvatar', () {
    test(
      'forwards the bytes and file name and returns the public URL',
      () async {
        final fake = _FakeProfileDataSource(
          avatarUrl: 'https://example.com/avatars/u1/avatar.png',
        );
        final repo = SupabaseProfileRepository(
          auth: _FakeAuthDataSource(),
          profiles: fake,
        );

        final url = await repo.updateAvatar(
          bytes: avatarBytes,
          fileName: 'avatar.png',
        );

        expect(url, 'https://example.com/avatars/u1/avatar.png');
        expect(fake.uploadedUserId, 'u1');
        expect(fake.uploadedBytes, avatarBytes);
        expect(fake.uploadedFileName, 'avatar.png');
      },
    );

    test('propagates data source errors', () async {
      final fake = _FakeProfileDataSource(
        uploadError: Exception('upload failed'),
      );
      final repo = SupabaseProfileRepository(
        auth: _FakeAuthDataSource(),
        profiles: fake,
      );

      expect(
        repo.updateAvatar(bytes: avatarBytes, fileName: 'avatar.png'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('SupabaseProfileRepository phone change (FR-AUTH-005)', () {
    const profile = ProfileDto(
      id: 'u1',
      role: 'customer',
      fullName: 'Budi Santoso',
      phone: '081234567890',
    );

    test(
      'requestPhoneChange forwards the number to the auth data source',
      () async {
        final auth = _FakeAuthDataSource();
        final repo = SupabaseProfileRepository(
          auth: auth,
          profiles: _FakeProfileDataSource(profile: profile),
        );

        await repo.requestPhoneChange('081299998888');

        expect(auth.requestedPhone, '081299998888');
      },
    );

    test('requestPhoneChange propagates auth errors', () {
      final auth = _FakeAuthDataSource(
        phoneChangeError: const PareAuthException(
          'The phone number could not be verified.',
        ),
      );
      final repo = SupabaseProfileRepository(
        auth: auth,
        profiles: _FakeProfileDataSource(profile: profile),
      );

      expect(
        repo.requestPhoneChange('081299998888'),
        throwsA(isA<PareAuthException>()),
      );
    });

    test('resendPhoneChangeOtp forwards the number', () async {
      final auth = _FakeAuthDataSource();
      final repo = SupabaseProfileRepository(
        auth: auth,
        profiles: _FakeProfileDataSource(profile: profile),
      );

      await repo.resendPhoneChangeOtp('081299998888');

      expect(auth.resentPhone, '081299998888');
    });

    test(
      'verifyPhoneChange verifies then mirrors the verified number',
      () async {
        final auth = _FakeAuthDataSource();
        final profiles = _FakeProfileDataSource(profile: profile);
        final repo = SupabaseProfileRepository(auth: auth, profiles: profiles);

        final updated = await repo.verifyPhoneChange(
          newPhone: '081299998888',
          token: '123456',
        );

        expect(auth.verifiedPhone, '081299998888');
        expect(auth.verifiedToken, '123456');
        // Keeps the saved name while overwriting the phone.
        expect(profiles.updatedFullName, 'Budi Santoso');
        expect(profiles.updatedPhone, '+6281299998888');
        expect(updated.name, 'Budi Santoso');
        expect(updated.email, 'budi@example.com');
      },
    );

    test(
      'verifyPhoneChange falls back to the entered number when the session has none',
      () async {
        final auth = _FakeAuthDataSource(sessionPhone: '');
        final profiles = _FakeProfileDataSource(profile: profile);
        final repo = SupabaseProfileRepository(auth: auth, profiles: profiles);

        await repo.verifyPhoneChange(newPhone: '081299998888', token: '123456');

        expect(profiles.updatedPhone, '081299998888');
      },
    );

    test(
      'verifyPhoneChange propagates auth errors before touching the profile',
      () async {
        final auth = _FakeAuthDataSource(
          phoneChangeError: const PareAuthException(
            'The OTP code is incorrect. Please try again.',
          ),
        );
        final profiles = _FakeProfileDataSource(profile: profile);
        final repo = SupabaseProfileRepository(auth: auth, profiles: profiles);

        expect(
          repo.verifyPhoneChange(newPhone: '081299998888', token: '123456'),
          throwsA(isA<PareAuthException>()),
        );
        expect(profiles.updatedPhone, isNull);
      },
    );
  });
}

class _FakeAuthDataSource extends SupabaseAuthDataSource {
  _FakeAuthDataSource({
    this.phoneChangeError,
    this.sessionPhone = '+6281299998888',
  });

  final Object? phoneChangeError;
  final String sessionPhone;

  String? requestedPhone;
  String? resentPhone;
  String? verifiedPhone;
  String? verifiedToken;

  @override
  String get currentUserId => 'u1';

  @override
  String get currentUserEmail => 'budi@example.com';

  @override
  Future<void> requestPhoneChange(String newPhone) async {
    requestedPhone = newPhone;
    final error = phoneChangeError;
    if (error != null) throw error;
  }

  @override
  Future<void> resendPhoneChangeOtp(String newPhone) async {
    resentPhone = newPhone;
    final error = phoneChangeError;
    if (error != null) throw error;
  }

  @override
  Future<AuthSessionDto> verifyPhoneChange({
    required String newPhone,
    required String token,
  }) async {
    verifiedPhone = newPhone;
    verifiedToken = token;
    final error = phoneChangeError;
    if (error != null) throw error;
    return AuthSessionDto(
      userId: 'u1',
      email: 'budi@example.com',
      role: 'customer',
      phone: sessionPhone,
    );
  }
}

class _FakeProfileDataSource extends SupabaseProfileDataSource {
  _FakeProfileDataSource({
    this.profile,
    this.fetchError,
    this.uploadError,
    this.avatarUrl,
  });

  final ProfileDto? profile;
  final Object? fetchError;
  final Object? uploadError;
  final String? avatarUrl;

  String? fetchedUserId;
  String? updatedUserId;
  String? updatedFullName;
  String? updatedPhone;
  String? uploadedUserId;
  Uint8List? uploadedBytes;
  String? uploadedFileName;

  @override
  Future<ProfileDto> fetchProfile({required String userId}) async {
    fetchedUserId = userId;
    final error = fetchError;
    if (error != null) throw error;
    return profile!;
  }

  @override
  Future<ProfileDto> updateProfile({
    required String userId,
    required String fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    updatedUserId = userId;
    updatedFullName = fullName;
    updatedPhone = phone;
    return profile!;
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    uploadedUserId = userId;
    uploadedBytes = bytes;
    uploadedFileName = fileName;
    final error = uploadError;
    if (error != null) throw error;
    return avatarUrl!;
  }
}
