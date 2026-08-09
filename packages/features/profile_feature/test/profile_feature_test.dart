import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile_feature/profile_feature.dart';

void main() {
  group('UserProfile', () {
    test('compares by value', () {
      const a = UserProfile(
        id: 'u1',
        name: 'Budi',
        phone: '081234567890',
        email: 'budi@example.com',
      );
      const b = UserProfile(
        id: 'u1',
        name: 'Budi',
        phone: '081234567890',
        email: 'budi@example.com',
      );
      const c = UserProfile(id: 'u1', name: 'Siti', phone: '081234567890');
      expect(a, b);
      expect(a == c, isFalse);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('UpdateProfile', () {
    test('rejects an empty name', () {
      final useCase = UpdateProfile(_FakeProfileRepository());
      expect(useCase.validate(name: ' '), isNotNull);
      expect(useCase.validate(name: 'Budi'), isNull);
    });

    test('rejects an invalid phone number', () {
      final useCase = UpdateProfile(_FakeProfileRepository());
      expect(useCase.validate(name: 'Budi', phone: '12345'), isNotNull);
      expect(useCase.validate(name: 'Budi', phone: '081234567890'), isNull);
    });

    test('applies valid edits through the repository', () async {
      final useCase = UpdateProfile(_FakeProfileRepository());
      final updated = await useCase(name: 'Budi', phone: '081234567890');
      expect(updated.name, 'Budi');
      expect(updated.phone, '081234567890');
    });

    test('forwards the address to the repository', () async {
      final repo = _FakeProfileRepository();
      final useCase = UpdateProfile(repo);
      final updated = await useCase(
        name: 'Budi',
        phone: '081234567890',
        address: 'Jl. Merdeka 1',
      );
      expect(repo.updatedAddress, 'Jl. Merdeka 1');
      expect(updated.address, 'Jl. Merdeka 1');
    });
  });

  group('RequestPhoneChange', () {
    test('rejects empty and invalid numbers', () {
      final useCase = RequestPhoneChange(_FakeProfileRepository());
      expect(useCase.validate(' '), 'Nomor HP wajib diisi.');
      expect(useCase.validate('12345'), isNotNull);
      expect(useCase.validate('081234567890'), isNull);
    });

    test('forwards a valid number to the repository', () async {
      final repo = _FakeProfileRepository();
      await RequestPhoneChange(repo)('081299998888');
      expect(repo.requestedPhone, '081299998888');
    });
  });

  group('ResendPhoneChangeOtp', () {
    test('forwards the number to the repository', () async {
      final repo = _FakeProfileRepository();
      await ResendPhoneChangeOtp(repo)('081299998888');
      expect(repo.resentPhone, '081299998888');
    });
  });

  group('VerifyPhoneChange', () {
    test('rejects empty and malformed tokens', () {
      final useCase = VerifyPhoneChange(_FakeProfileRepository());
      expect(useCase.validate(' '), 'Kode OTP wajib diisi.');
      expect(useCase.validate('12345'), isNotNull);
      expect(useCase.validate('123456'), isNull);
    });

    test('returns the updated profile from the repository', () async {
      final repo = _FakeProfileRepository();
      final updated = await VerifyPhoneChange(repo)(
        newPhone: '081299998888',
        token: '123456',
      );
      expect(repo.verifiedPhone, '081299998888');
      expect(repo.verifiedToken, '123456');
      expect(updated.phone, '081299998888');
    });
  });

  group('profile providers', () {
    test('default to the Supabase-backed repository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(profileRepositoryProvider),
        isA<SupabaseProfileRepository>(),
      );
    });

    test('resolve the update use case from the repository override', () {
      final container = ProviderContainer(
        overrides: [
          profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(updateProfileProvider), isA<UpdateProfile>());
    });

    test('resolve the phone-change use cases from the repository override', () {
      final container = ProviderContainer(
        overrides: [
          profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(requestPhoneChangeProvider),
        isA<RequestPhoneChange>(),
      );
      expect(
        container.read(resendPhoneChangeOtpProvider),
        isA<ResendPhoneChangeOtp>(),
      );
      expect(
        container.read(verifyPhoneChangeProvider),
        isA<VerifyPhoneChange>(),
      );
    });

    test('profileProvider surfaces the fetched profile', () async {
      final repo = _FakeProfileRepository();
      final container = ProviderContainer(
        overrides: [profileRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final profile = await container.read(profileProvider.future);
      expect(profile.name, 'Budi');
      expect(repo.fetchCount, 1);
    });
  });
}

class _FakeProfileRepository implements ProfileRepository {
  int fetchCount = 0;
  String? updatedAddress;
  String? requestedPhone;
  String? resentPhone;
  String? verifiedPhone;
  String? verifiedToken;

  @override
  Future<UserProfile> fetchProfile() async {
    fetchCount++;
    return const UserProfile(
      id: 'u1',
      name: 'Budi',
      phone: '081234567890',
      email: 'budi@example.com',
    );
  }

  @override
  Future<UserProfile> updateProfile({
    required String name,
    String? phone,
    String? address,
  }) async {
    updatedAddress = address;
    return UserProfile(
      id: 'u1',
      name: name,
      phone: phone ?? '081234567890',
      address: address,
    );
  }

  @override
  Future<String> updateAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    return 'https://example.com/avatars/$fileName';
  }

  @override
  Future<void> requestPhoneChange(String newPhone) async {
    requestedPhone = newPhone;
  }

  @override
  Future<void> resendPhoneChangeOtp(String newPhone) async {
    resentPhone = newPhone;
  }

  @override
  Future<UserProfile> verifyPhoneChange({
    required String newPhone,
    required String token,
  }) async {
    verifiedPhone = newPhone;
    verifiedToken = token;
    return const UserProfile(
      id: 'u1',
      name: 'Budi',
      phone: '081299998888',
      email: 'budi@example.com',
    );
  }
}
