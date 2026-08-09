/// Discovery repository contract (PF-DOC-11 §3.1 data layer).
///
/// Concrete implementations live in the composition root or a default
/// feature-local adapter over `pare_data`; features never import the Supabase
/// SDK directly (MO-R02a). Overrides of [discoveryRepositoryProvider] are the
/// FL-R04 test seam.
library;

import '../domain/discovery_models.dart';

/// Contract implemented by the data layer.
abstract interface class DiscoveryRepository {
  /// Active restaurants nearest to [lat]/[lng], ordered by distance
  /// (FR-DISC-001, NFR-003).
  Future<List<RestaurantSummary>> nearbyRestaurants({
    required double lat,
    required double lng,
    double radiusKm = 5,
  });

  /// Restaurant detail with its available menu items (FR-DISC-004).
  Future<RestaurantDetail?> restaurantDetail(String restaurantId);
}
