/// Restaurant repository contract (PF-DOC-11 §3.1 data layer).
///
/// Concrete implementations live in the composition root or a default
/// feature-local adapter over `pare_data`; features never import the Supabase
/// SDK directly (MO-R02a). Overrides of [restaurantRepositoryProvider] are the
/// FL-R04 test seam.
library;

import 'dart:typed_data';

import '../domain/restaurant.dart';

/// Contract implemented by the data layer.
abstract interface class RestaurantRepository {
  /// Restaurants owned by the signed-in business user.
  Future<List<Restaurant>> myRestaurants();

  /// Creates the merchant's restaurant; status starts `pending` until an admin
  /// activates it (FR-ONB-001/002).
  Future<Restaurant> createRestaurant({
    required String name,
    required String description,
    required String slug,
    required double latitude,
    required double longitude,
    required int deliveryRadiusMeters,
  });

  /// Applies an edit to the restaurant profile.
  Future<Restaurant> updateRestaurant({
    required String restaurantId,
    required String name,
    String? description,
    String? logoUrl,
    String? coverUrl,
  });

  /// Sets opening hours for one day of the week (0=Monday .. 6=Sunday).
  Future<void> setHours({
    required String restaurantId,
    required int dayOfWeek,
    required String openTime,
    required String closeTime,
    bool isClosed = false,
  });

  /// Uploads a verification document to the `merchant-docs` bucket.
  Future<void> uploadDocument({
    required String restaurantId,
    required String fileName,
    required Uint8List bytes,
  });

  /// Registers a submitted verification document row (`docType`: ktp | nib).
  /// Status starts `submitted` (FR-ONB-001/002).
  Future<void> submitDocument({
    required String docType,
    required String storagePath,
  });
}
