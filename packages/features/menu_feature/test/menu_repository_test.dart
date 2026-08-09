import 'package:menu_feature/menu_feature.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_data/pare_data.dart';
import 'package:test/test.dart';

void main() {
  group('SupabaseMenuRepository', () {
    test('loadMenu maps items to domain Money prices', () async {
      final fake = _FakeCatalog()
        ..categories = [
          const MenuCategoryDto(
            id: 'c1',
            restaurantId: 'r1',
            name: 'Main',
            sortOrder: 1,
          ),
        ]
        ..items = [
          const MenuItemDto(
            id: 'm1',
            restaurantId: 'r1',
            categoryId: 'c1',
            name: 'Rendang',
            description: 'Daging sapi',
            imageUrl: 'rendang.png',
            price: 85000,
            isAvailable: false,
            isFeatured: true,
            sortOrder: 2,
          ),
        ];

      final repo = SupabaseMenuRepository(catalog: fake);
      final menu = await repo.loadMenu(restaurantId: 'r1');

      final category = menu.categories.single;
      expect(category.id, 'c1');
      expect(category.restaurantId, 'r1');
      expect(category.name, 'Main');
      expect(category.sortOrder, 1);

      final item = menu.items.single;
      expect(item.name, 'Rendang');
      expect(item.description, 'Daging sapi');
      expect(item.imageUrl, 'rendang.png');
      expect(item.categoryId, 'c1');
      expect(item.price, Money.fromRupiah(85000));
      expect(item.isAvailable, isFalse);
      expect(item.isFeatured, isTrue);
      expect(item.sortOrder, 2);
    });

    test('upsertItem delegates and maps the created item', () async {
      final fake = _FakeCatalog();
      final repo = SupabaseMenuRepository(catalog: fake);

      final item = await repo.upsertItem(
        restaurantId: 'r1',
        id: 'm9',
        categoryId: 'c1',
        name: 'Sate',
        description: 'Empat tusuk',
        price: 25000,
        imageUrl: 'sate.png',
        isAvailable: false,
      );

      expect(item.id, 'm9');
      expect(item.price, Money.fromRupiah(25000));
      expect(fake.lastUpsert, isNotNull);
      expect(fake.lastUpsert!.id, 'm9');
      expect(fake.lastUpsert!.categoryId, 'c1');
      expect(fake.lastUpsert!.description, 'Empat tusuk');
      expect(fake.lastUpsert!.imageUrl, 'sate.png');
      expect(fake.lastUpsert!.isAvailable, isFalse);
    });

    test('setAvailability delegates and returns the updated item', () async {
      final fake = _FakeCatalog();
      final repo = SupabaseMenuRepository(catalog: fake);
      final item = await repo.setAvailability(
        restaurantId: 'r1',
        itemId: 'm1',
        isAvailable: false,
      );
      expect(item.isAvailable, isFalse);
      expect(fake.lastAvailabilityUpdate, (itemId: 'm1', available: false));
    });

    test('deleteItem delegates the item id', () async {
      final fake = _FakeCatalog();
      final repo = SupabaseMenuRepository(catalog: fake);
      await repo.deleteItem('m1');
      expect(fake.deletedItems, ['m1']);
    });

    test('createCategory delegates and maps the category', () async {
      final fake = _FakeCatalog();
      final repo = SupabaseMenuRepository(catalog: fake);

      final category = await repo.createCategory(
        restaurantId: 'r1',
        name: 'Minuman',
      );
      expect(category.name, 'Minuman');
      expect(fake.lastCreatedCategory, (restaurantId: 'r1', name: 'Minuman'));
    });

    test('updateCategory delegates the new name', () async {
      final fake = _FakeCatalog();
      final repo = SupabaseMenuRepository(catalog: fake);

      await repo.updateCategory(categoryId: 'c1', name: 'Makanan Utama');
      expect(fake.lastUpdatedCategory, (
        categoryId: 'c1',
        name: 'Makanan Utama',
      ));
    });

    test('deleteCategory delegates the category id', () async {
      final fake = _FakeCatalog();
      final repo = SupabaseMenuRepository(catalog: fake);

      await repo.deleteCategory('c1');
      expect(fake.deletedCategories, ['c1']);
    });

    test('importCsv creates valid rows and skips malformed ones', () async {
      final fake = _FakeCatalog();
      final repo = SupabaseMenuRepository(catalog: fake);
      final result = await repo.importCsv(
        restaurantId: 'r1',
        rows: [
          {'name': 'Rendang', 'price': '85000'},
          {'name': 'Sate', 'price': '25000', 'description': 'Empat tusuk'},
          {'name': 'Gratis', 'price': '0', 'category_id': 'c1'},
          {'name': '', 'price': '5000'},
          {'name': 'Free', 'price': '-1'},
          {'name': 'NoPrice', 'price': 'abc'},
        ],
      );
      expect(result.created, 3);
      expect(result.skipped, 3);

      expect(fake.upserted, hasLength(3));
      expect(fake.upserted[0], (
        name: 'Rendang',
        price: 85000,
        description: null,
        categoryId: null,
      ));
      expect(fake.upserted[1], (
        name: 'Sate',
        price: 25000,
        description: 'Empat tusuk',
        categoryId: null,
      ));
      expect(fake.upserted[2], (
        name: 'Gratis',
        price: 0,
        description: null,
        categoryId: 'c1',
      ));
    });

    test('importCsv with no rows returns a zero tally', () async {
      final fake = _FakeCatalog();
      final repo = SupabaseMenuRepository(catalog: fake);
      final result = await repo.importCsv(restaurantId: 'r1', rows: const []);
      expect(result.created, 0);
      expect(result.skipped, 0);
    });

    test('can be constructed with the default data source', () {
      expect(SupabaseMenuRepository(), isA<SupabaseMenuRepository>());
    });

    test('catalog errors propagate to the caller', () async {
      final fake = _FakeCatalog()..throwOnRead = true;
      final repo = SupabaseMenuRepository(catalog: fake);
      await expectLater(
        repo.loadMenu(restaurantId: 'r1'),
        throwsA(isA<StateError>()),
      );
    });
  });
}

class _FakeCatalog extends SupabaseCatalogDataSource {
  List<MenuCategoryDto> categories = const [];
  List<MenuItemDto> items = const [];
  bool throwOnRead = false;

  ({String itemId, bool available})? lastAvailabilityUpdate;

  final deletedItems = <String>[];
  final deletedCategories = <String>[];
  final upserted =
      <({String name, int price, String? description, String? categoryId})>[];

  ({
    String? id,
    String? categoryId,
    String name,
    String? description,
    int price,
    String? imageUrl,
    bool isAvailable,
  })?
  lastUpsert;

  ({String restaurantId, String name})? lastCreatedCategory;
  ({String categoryId, String name})? lastUpdatedCategory;

  @override
  Future<({List<MenuCategoryDto> categories, List<MenuItemDto> items})>
  menuForRestaurant(String restaurantId) async {
    if (throwOnRead) throw StateError('db down');
    return (categories: categories, items: items);
  }

  @override
  Future<MenuItemDto> upsertMenuItem({
    required String restaurantId,
    String? id,
    String? categoryId,
    required String name,
    String? description,
    required int priceMinor,
    String? imageUrl,
    bool isAvailable = true,
    bool isFeatured = false,
    int sortOrder = 0,
  }) async {
    lastUpsert = (
      id: id,
      categoryId: categoryId,
      name: name,
      description: description,
      price: priceMinor,
      imageUrl: imageUrl,
      isAvailable: isAvailable,
    );
    upserted.add((
      name: name,
      price: priceMinor,
      description: description,
      categoryId: categoryId,
    ));
    return MenuItemDto(
      id: id ?? 'new-$name',
      restaurantId: restaurantId,
      categoryId: categoryId,
      name: name,
      description: description,
      price: priceMinor,
      imageUrl: imageUrl,
      isAvailable: isAvailable,
      isFeatured: isFeatured,
      sortOrder: sortOrder,
    );
  }

  @override
  Future<MenuItemDto> setMenuItemAvailability({
    required String itemId,
    required bool isAvailable,
  }) async {
    lastAvailabilityUpdate = (itemId: itemId, available: isAvailable);
    return MenuItemDto(
      id: itemId,
      restaurantId: 'r1',
      name: 'Stub',
      price: 0,
      isAvailable: isAvailable,
    );
  }

  @override
  Future<void> deleteMenuItem(String id) async {
    deletedItems.add(id);
  }

  @override
  Future<MenuCategoryDto> createCategory({
    required String restaurantId,
    required String name,
    required int sortOrder,
  }) async {
    lastCreatedCategory = (restaurantId: restaurantId, name: name);
    return MenuCategoryDto(
      id: 'new-cat',
      restaurantId: restaurantId,
      name: name,
      sortOrder: sortOrder,
    );
  }

  @override
  Future<MenuCategoryDto> updateCategory({
    required String categoryId,
    required String name,
    required int sortOrder,
  }) async {
    lastUpdatedCategory = (categoryId: categoryId, name: name);
    return MenuCategoryDto(
      id: categoryId,
      restaurantId: 'r1',
      name: name,
      sortOrder: sortOrder,
    );
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    deletedCategories.add(categoryId);
  }
}
