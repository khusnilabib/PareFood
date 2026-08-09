import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:menu_feature/menu_feature.dart';
import 'package:pare_core/pare_core.dart';
import 'package:test/test.dart';

void main() {
  group('menuProvider family', () {
    test('exposes loading then data for the requested restaurant', () async {
      final repo = _FakeMenuRepository();
      final container = ProviderContainer(
        overrides: [menuRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final sub = container.listen(menuProvider('r1'), (_, _) {});
      expect(sub.read().isLoading, isTrue);

      final menu = await container.read(menuProvider('r1').future);
      expect(menu.categories.single.name, 'Main');
      expect(menu.items.single.name, 'Rendang');
      expect(repo.lastLoadMenu, 'r1');

      final state = container.read(menuProvider('r1'));
      expect(state.hasValue, isTrue);
      expect(container.read(menuProvider('r2')), isNot(same(state)));
    });

    test('surfaces repository errors', () async {
      final repo = _FakeMenuRepository()..failLoad = true;
      final container = ProviderContainer(
        overrides: [menuRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(menuProvider('r1').future),
        throwsA(isA<StateError>()),
      );
      final state = container.read(menuProvider('r1'));
      expect(state.hasError, isTrue);
      expect(state.error, isA<StateError>());
    });
  });
}

class _FakeMenuRepository implements MenuRepository {
  bool failLoad = false;
  String? lastLoadMenu;

  @override
  Future<({List<MenuCategory> categories, List<MenuItem> items})> loadMenu({
    required String restaurantId,
  }) async {
    lastLoadMenu = restaurantId;
    if (failLoad) throw StateError('db down');
    return (
      categories: const [
        MenuCategory(id: 'c1', restaurantId: 'r1', name: 'Main'),
      ],
      items: [
        MenuItem(
          id: 'm1',
          restaurantId: 'r1',
          categoryId: 'c1',
          name: 'Rendang',
          price: Money.fromRupiah(85000),
        ),
      ],
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
    return MenuItem(
      id: id ?? 'new',
      restaurantId: restaurantId,
      categoryId: categoryId,
      name: name,
      price: Money.fromRupiah(price),
    );
  }

  @override
  Future<MenuItem> setAvailability({
    required String restaurantId,
    required String itemId,
    required bool isAvailable,
  }) async {
    return MenuItem(
      id: itemId,
      restaurantId: restaurantId,
      name: 'Stub',
      price: Money.fromRupiah(0),
    );
  }

  @override
  Future<void> deleteItem(String itemId) async {}

  @override
  Future<MenuCategory> createCategory({
    required String restaurantId,
    required String name,
  }) async {
    return MenuCategory(id: 'c', restaurantId: restaurantId, name: name);
  }

  @override
  Future<void> updateCategory({
    required String categoryId,
    required String name,
  }) async {}

  @override
  Future<void> deleteCategory(String categoryId) async {}

  @override
  Future<MenuImportResult> importCsv({
    required String restaurantId,
    required List<Map<String, String>> rows,
  }) async {
    return const MenuImportResult(created: 0, skipped: 0);
  }
}
