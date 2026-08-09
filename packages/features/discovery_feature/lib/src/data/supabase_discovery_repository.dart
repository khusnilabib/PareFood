/// Default [DiscoveryRepository] backed by `pare_data` (PF-DOC-11 §3.1).
/// Overridable at the composition root / in tests (FL-R04).
library;

import 'package:pare_core/pare_core.dart';
import 'package:pare_data/pare_data.dart';

import '../domain/discovery_models.dart';
import 'discovery_repository.dart';

/// Adapts the feature-agnostic [SupabaseCatalogDataSource] to
/// [DiscoveryRepository]. Only touches `pare_data` (MO-R02a).
class SupabaseDiscoveryRepository implements DiscoveryRepository {
  SupabaseDiscoveryRepository({SupabaseCatalogDataSource? catalog})
    : _catalog = catalog ?? SupabaseCatalogDataSource();

  final SupabaseCatalogDataSource _catalog;

  @override
  Future<List<RestaurantSummary>> nearbyRestaurants({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async {
    final dtos = await _catalog.nearbyRestaurants(
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
    );
    return dtos.map(_toSummary).toList();
  }

  @override
  Future<RestaurantDetail?> restaurantDetail(String restaurantId) async {
    final dto = await _catalog.restaurantById(restaurantId);
    if (dto == null) return null;
    final menu = await _catalog.menuForRestaurant(restaurantId);

    final categoriesById = <String, String>{
      for (final c in menu.categories) c.id: c.name,
    };
    final items = menu.items.map((item) {
      final categoryId = item.categoryId;
      return DiscoveryMenuItem(
        id: item.id,
        name: item.name,
        price: Money.fromRupiah(item.price),
        categoryName: categoryId == null ? null : categoriesById[categoryId],
        description: item.description,
        imageUrl: item.imageUrl,
        isAvailable: item.isAvailable,
      );
    }).toList();

    return RestaurantDetail(restaurant: _toSummary(dto), menu: items);
  }

  RestaurantSummary _toSummary(RestaurantDto dto) {
    return RestaurantSummary(
      id: dto.id,
      name: dto.name,
      slug: dto.slug,
      logoUrl: dto.logoUrl,
      coverUrl: dto.coverUrl,
      description: dto.description,
      ratingAvg: dto.ratingAvg,
      reviewCount: dto.reviewCount,
      deliveryRadiusKm: dto.deliveryRadiusKm,
    );
  }
}
