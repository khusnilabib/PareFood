/// Default [MenuRepository] backed by `pare_data` (PF-DOC-11 §3.1).
/// Overridable at the composition root / in tests (FL-R04).
library;

import 'package:pare_core/pare_core.dart';
import 'package:pare_data/pare_data.dart';

import '../domain/menu_models.dart';
import 'menu_repository.dart';

/// Adapts the feature-agnostic [SupabaseCatalogDataSource] to [MenuRepository].
/// Only touches `pare_data` (MO-R02a).
class SupabaseMenuRepository implements MenuRepository {
  SupabaseMenuRepository({SupabaseCatalogDataSource? catalog})
    : _catalog = catalog ?? SupabaseCatalogDataSource();

  final SupabaseCatalogDataSource _catalog;

  @override
  Future<({List<MenuCategory> categories, List<MenuItem> items})> loadMenu({
    required String restaurantId,
  }) async {
    final dto = await _catalog.menuForRestaurant(restaurantId);
    return (
      categories: dto.categories.map(_toCategory).toList(),
      items: dto.items.map(_toItem).toList(),
    );
  }

  @override
  Future<MenuItem> upsertItem({
    required String restaurantId,
    String? id,
    String? categoryId,
    required String name,
    String? description,
    required int price,
    String? imageUrl,
    bool isAvailable = true,
  }) async {
    final dto = await _catalog.upsertMenuItem(
      restaurantId: restaurantId,
      id: id,
      categoryId: categoryId,
      name: name,
      description: description,
      priceMinor: price,
      imageUrl: imageUrl,
      isAvailable: isAvailable,
    );
    return _toItem(dto);
  }

  @override
  Future<MenuItem> setAvailability({
    required String restaurantId,
    required String itemId,
    required bool isAvailable,
  }) async {
    final dto = await _catalog.setMenuItemAvailability(
      itemId: itemId,
      isAvailable: isAvailable,
    );
    return _toItem(dto);
  }

  @override
  Future<void> deleteItem(String itemId) => _catalog.deleteMenuItem(itemId);

  @override
  Future<MenuCategory> createCategory({
    required String restaurantId,
    required String name,
  }) async {
    final dto = await _catalog.createCategory(
      restaurantId: restaurantId,
      name: name,
      sortOrder: 0,
    );
    return _toCategory(dto);
  }

  @override
  Future<void> updateCategory({
    required String categoryId,
    required String name,
  }) async {
    await _catalog.updateCategory(
      categoryId: categoryId,
      name: name,
      sortOrder: 0,
    );
  }

  @override
  Future<void> deleteCategory(String categoryId) =>
      _catalog.deleteCategory(categoryId);

  @override
  Future<MenuImportResult> importCsv({
    required String restaurantId,
    required List<Map<String, String>> rows,
  }) async {
    var created = 0;
    for (final row in rows) {
      final name = row['name'] ?? '';
      final price = int.tryParse(row['price'] ?? '');
      if (name.isEmpty || price == null || price < 0) continue;
      await upsertItem(
        restaurantId: restaurantId,
        name: name,
        description: row['description'],
        categoryId: row['category_id'],
        price: price,
      );
      created++;
    }
    return MenuImportResult(created: created, skipped: rows.length - created);
  }

  MenuCategory _toCategory(MenuCategoryDto dto) {
    return MenuCategory(
      id: dto.id,
      restaurantId: dto.restaurantId,
      name: dto.name,
      sortOrder: dto.sortOrder,
    );
  }

  MenuItem _toItem(MenuItemDto dto) {
    return MenuItem(
      id: dto.id,
      restaurantId: dto.restaurantId,
      categoryId: dto.categoryId,
      name: dto.name,
      description: dto.description,
      price: Money.fromRupiah(dto.price),
      imageUrl: dto.imageUrl,
      isAvailable: dto.isAvailable,
      isFeatured: dto.isFeatured,
      sortOrder: dto.sortOrder,
    );
  }
}
