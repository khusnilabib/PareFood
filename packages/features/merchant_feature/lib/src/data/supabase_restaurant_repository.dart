/// Default [RestaurantRepository] backed by `pare_data` (PF-DOC-11 §3.1).
/// Overridable at the composition root / in tests (FL-R04).
library;

import 'dart:typed_data';

import 'package:pare_data/pare_data.dart';

import '../domain/restaurant.dart';
import 'restaurant_repository.dart';

/// Adapts the feature-agnostic [SupabaseCatalogDataSource] to
/// [RestaurantRepository]. Only touches `pare_data` (MO-R02a).
class SupabaseRestaurantRepository implements RestaurantRepository {
  SupabaseRestaurantRepository({
    SupabaseAuthDataSource? auth,
    SupabaseCatalogDataSource? catalog,
  }) : _auth = auth ?? SupabaseAuthDataSource(),
       _catalog = catalog ?? SupabaseCatalogDataSource();

  final SupabaseAuthDataSource _auth;
  final SupabaseCatalogDataSource _catalog;

  @override
  Future<List<Restaurant>> myRestaurants() async {
    final dtos = await _catalog.restaurantsForOwner(_auth.currentUserId);
    return dtos.map(_toRestaurant).toList();
  }

  @override
  Future<Restaurant> createRestaurant({
    required String name,
    required String description,
    required String slug,
    required double latitude,
    required double longitude,
    required int deliveryRadiusMeters,
  }) async {
    final dto = await _catalog.createRestaurant(
      name: name,
      description: description,
      slug: slug,
      latitude: latitude,
      longitude: longitude,
      deliveryRadiusMeters: deliveryRadiusMeters,
    );
    return _toRestaurant(dto);
  }

  @override
  Future<Restaurant> updateRestaurant({
    required String restaurantId,
    required String name,
    String? description,
    String? logoUrl,
    String? coverUrl,
  }) async {
    final dto = await _catalog.updateRestaurant(
      restaurantId: restaurantId,
      name: name,
      description: description,
      logoUrl: logoUrl,
      coverUrl: coverUrl,
    );
    return _toRestaurant(dto);
  }

  @override
  Future<void> setHours({
    required String restaurantId,
    required int dayOfWeek,
    required String openTime,
    required String closeTime,
    bool isClosed = false,
  }) {
    return _catalog.setRestaurantHours(
      restaurantId: restaurantId,
      dayOfWeek: dayOfWeek,
      openTime: openTime,
      closeTime: closeTime,
      isClosed: isClosed,
    );
  }

  @override
  Future<void> uploadDocument({
    required String restaurantId,
    required String fileName,
    required Uint8List bytes,
  }) {
    return _catalog.uploadMerchantDocument(
      restaurantId: restaurantId,
      fileName: fileName,
      bytes: bytes,
    );
  }

  @override
  Future<void> submitDocument({
    required String docType,
    required String storagePath,
  }) {
    return _catalog.submitMerchantDocument(
      userId: _auth.currentUserId,
      docType: docType,
      storagePath: storagePath,
    );
  }

  Restaurant _toRestaurant(RestaurantDto dto) {
    return Restaurant(
      id: dto.id,
      name: dto.name,
      slug: dto.slug,
      description: dto.description,
      logoUrl: dto.logoUrl,
      coverUrl: dto.coverUrl,
      status: RestaurantStatusX.fromDb(dto.status),
      deliveryRadiusKm: dto.deliveryRadiusKm,
    );
  }
}
