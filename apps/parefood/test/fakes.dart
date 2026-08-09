/// Fake repositories for hermetic app tests (TS-R06: no network/Supabase).
library;

import 'dart:typed_data';

import 'package:discovery_feature/discovery_feature.dart';
import 'package:profile_feature/profile_feature.dart';

/// Empty discovery results; enough to exercise the FL-R07 empty state.
class FakeDiscoveryRepository implements DiscoveryRepository {
  @override
  Future<List<RestaurantSummary>> nearbyRestaurants({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async => const [];

  @override
  Future<RestaurantDetail?> restaurantDetail(String restaurantId) async => null;
}

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
