/// Discovery providers (PF-DOC-11 §3.2).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/discovery_repository.dart';
import '../data/supabase_discovery_repository.dart';
import '../domain/discovery_models.dart';

/// Repository contract. Defaults to the `pare_data`-backed adapter; the app
/// composition root or tests may override it (FL-R04).
final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return SupabaseDiscoveryRepository();
});

/// Restaurants nearest to the given location (FR-DISC-001).
final nearbyRestaurantsProvider =
    FutureProvider.family<
      List<RestaurantSummary>,
      ({double lat, double lng, double radiusKm})
    >((ref, location) {
      return ref
          .watch(discoveryRepositoryProvider)
          .nearbyRestaurants(
            lat: location.lat,
            lng: location.lng,
            radiusKm: location.radiusKm,
          );
    });

/// Restaurant detail with menu (FR-DISC-004).
final restaurantDetailProvider =
    FutureProvider.family<RestaurantDetail?, String>((ref, restaurantId) {
      return ref
          .watch(discoveryRepositoryProvider)
          .restaurantDetail(restaurantId);
    });
