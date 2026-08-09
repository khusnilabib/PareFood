/// Menu repository contract (PF-DOC-11 §3.1 data layer).
///
/// Concrete implementations live in the composition root or a default
/// feature-local adapter over `pare_data`; features never import the Supabase
/// SDK directly (MO-R02a). Overrides of [menuRepositoryProvider] are the FL-R04
/// test seam.
library;

import '../domain/menu_models.dart';

/// Contract implemented by the data layer.
abstract interface class MenuRepository {
  /// Categories and items for the merchant's restaurant.
  Future<({List<MenuCategory> categories, List<MenuItem> items})> loadMenu({
    required String restaurantId,
  });

  /// Creates or updates an item (upsert by [id] when editing).
  Future<MenuItem> upsertItem({
    required String restaurantId,
    String? id,
    String? categoryId,
    required String name,
    String? description,
    required int price,
    String? imageUrl,
    bool isAvailable = true,
  });

  /// Flips availability (out-of-stock) state (FR-MENU-002).
  Future<MenuItem> setAvailability({
    required String restaurantId,
    required String itemId,
    required bool isAvailable,
  });

  Future<void> deleteItem(String itemId);

  Future<MenuCategory> createCategory({
    required String restaurantId,
    required String name,
  });

  Future<void> updateCategory({
    required String categoryId,
    required String name,
  });

  Future<void> deleteCategory(String categoryId);

  /// Bulk-imports items from CSV rows and returns a tally (FR-MENU-003).
  Future<MenuImportResult> importCsv({
    required String restaurantId,
    required List<Map<String, String>> rows,
  });
}
