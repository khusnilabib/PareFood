/// Fake repositories for hermetic app tests (TS-R06: no network/Supabase).
library;

import 'dart:typed_data';

import 'package:discovery_feature/discovery_feature.dart';
import 'package:orders_feature/orders_feature.dart';
import 'package:pare_core/pare_core.dart';
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

/// Empty orders; enough to exercise the FL-R07 empty state.
class FakeOrdersRepository implements OrdersRepository {
  @override
  Future<List<OrderSummary>> fetchForCustomer() async => const [];

  @override
  Future<List<OrderSummary>> fetchForRestaurant({
    String? restaurantId,
    Set<OrderStatus>? statuses,
  }) async => const [];

  @override
  Future<List<DeliveryJob>> fetchForDriver() async => const [];

  @override
  Future<List<OrderSummary>> fetchAll({
    Set<OrderStatus>? statuses,
    String? search,
  }) async => const [];

  @override
  Future<OrderSummary> fetchById(String id) async {
    throw PareNotFoundException('Order $id not found.');
  }

  @override
  Future<OrderDetail> fetchDetail(String id) async {
    throw PareNotFoundException('Order $id not found.');
  }
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
