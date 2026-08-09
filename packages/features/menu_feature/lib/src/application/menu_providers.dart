/// Menu providers (PF-DOC-11 §3.2).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/menu_repository.dart';
import '../data/supabase_menu_repository.dart';
import '../domain/menu_models.dart';

/// Repository contract. Defaults to the `pare_data`-backed adapter; the app
/// composition root or tests may override it (FL-R04).
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return SupabaseMenuRepository();
});

/// Loads categories and items for a restaurant.
final menuProvider =
    FutureProvider.family<
      ({List<MenuCategory> categories, List<MenuItem> items}),
      String
    >((ref, restaurantId) {
      return ref
          .watch(menuRepositoryProvider)
          .loadMenu(restaurantId: restaurantId);
    });
