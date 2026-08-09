/// Merchant providers (PF-DOC-11 §3.2).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/restaurant_repository.dart';
import '../data/supabase_restaurant_repository.dart';
import '../domain/restaurant.dart';

/// Repository contract. Defaults to the `pare_data`-backed adapter; the app
/// composition root or tests may override it (FL-R04).
final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  return SupabaseRestaurantRepository();
});

/// Restaurants owned by the signed-in business user.
final myRestaurantsProvider = FutureProvider<List<Restaurant>>((ref) async {
  return ref.watch(restaurantRepositoryProvider).myRestaurants();
});
