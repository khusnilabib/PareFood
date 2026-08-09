import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchant_feature/merchant_feature.dart';
import 'package:test/test.dart';

void main() {
  group('myRestaurantsProvider', () {
    test('exposes loading then data states', () async {
      final repo = _FakeRestaurantRepository(
        () async => const [
          Restaurant(id: 'r1', name: 'Warung Nusantara', slug: 'warung'),
        ],
      );
      final container = ProviderContainer(
        overrides: [restaurantRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final sub = container.listen(myRestaurantsProvider, (_, _) {});
      expect(sub.read().isLoading, isTrue);

      final restaurants = await container.read(myRestaurantsProvider.future);
      expect(restaurants.single.name, 'Warung Nusantara');
      final state = container.read(myRestaurantsProvider);
      expect(state.hasValue, isTrue);
      expect(state.value, hasLength(1));
    });

    test('surfaces repository errors', () async {
      final repo = _FakeRestaurantRepository(
        () async => throw StateError('db down'),
      );
      final container = ProviderContainer(
        overrides: [restaurantRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(myRestaurantsProvider.future),
        throwsA(isA<StateError>()),
      );
      final state = container.read(myRestaurantsProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<StateError>());
    });
  });
}

class _FakeRestaurantRepository implements RestaurantRepository {
  _FakeRestaurantRepository(this._my);

  final Future<List<Restaurant>> Function() _my;

  @override
  Future<List<Restaurant>> myRestaurants() => _my();

  @override
  Future<Restaurant> createRestaurant({
    required String name,
    required String description,
    required String slug,
    required double latitude,
    required double longitude,
    required int deliveryRadiusMeters,
  }) async {
    return Restaurant(id: 'r1', name: name, slug: slug);
  }

  @override
  Future<Restaurant> updateRestaurant({
    required String restaurantId,
    required String name,
    String? description,
    String? logoUrl,
    String? coverUrl,
  }) async {
    return Restaurant(id: restaurantId, name: name, slug: 's');
  }

  @override
  Future<void> setHours({
    required String restaurantId,
    required int dayOfWeek,
    required String openTime,
    required String closeTime,
    bool isClosed = false,
  }) async {}

  @override
  Future<void> uploadDocument({
    required String restaurantId,
    required String fileName,
    required Uint8List bytes,
  }) async {}

  @override
  Future<void> submitDocument({
    required String docType,
    required String storagePath,
  }) async {}
}
