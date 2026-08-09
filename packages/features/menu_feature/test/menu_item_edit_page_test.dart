import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_feature/menu_feature.dart';
import 'package:pare_core/pare_core.dart';

void main() {
  late _FakeMenuRepository repo;

  setUp(() {
    repo = _FakeMenuRepository();
  });

  Future<void> pumpEdit(WidgetTester tester, {MenuItem? item}) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [menuRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container.read(menuProvider('r1').future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          MenuItemEditPage(restaurantId: 'r1', item: item),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  MenuItem sampleItem({int price = 85000, bool isAvailable = true}) {
    return MenuItem(
      id: 'm1',
      restaurantId: 'r1',
      categoryId: 'c1',
      name: 'Rendang',
      description: 'Daging sapi',
      price: Money.fromRupiah(price),
      isAvailable: isAvailable,
    );
  }

  testWidgets('add mode prefills the no-category selection', (tester) async {
    await pumpEdit(tester);
    expect(find.text('Tambah item'), findsOneWidget);
    expect(find.text('Nama item'), findsOneWidget);
    expect(find.text('Tanpa kategori'), findsOneWidget);
    expect(find.text('Harga (Rp)'), findsOneWidget);
    expect(find.text('Tambah'), findsOneWidget);
    expect(find.text('Hapus item'), findsNothing);
  });

  testWidgets('validates empty name and invalid price', (tester) async {
    await pumpEdit(tester);

    await tester.enterText(find.byType(TextFormField).at(1), 'abc');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    expect(find.text('Field wajib diisi.'), findsOneWidget);
    expect(find.text('Masukkan harga yang valid.'), findsOneWidget);
    expect(repo.lastUpsert, isNull);
  });

  testWidgets('rejects a negative price', (tester) async {
    await pumpEdit(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Nasi');
    await tester.enterText(find.byType(TextFormField).at(1), '-5');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    expect(find.text('Masukkan harga yang valid.'), findsOneWidget);
    expect(repo.lastUpsert, isNull);
  });

  testWidgets('saving a new item calls upsert and pops', (tester) async {
    await pumpEdit(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Nasi Goreng');
    await tester.enterText(find.byType(TextFormField).at(1), '15000');
    await tester.tap(find.text('Tanpa kategori'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    expect(repo.lastUpsert, isNotNull);
    expect(repo.lastUpsert!.restaurantId, 'r1');
    expect(repo.lastUpsert!.id, isNull);
    expect(repo.lastUpsert!.categoryId, 'c1');
    expect(repo.lastUpsert!.name, 'Nasi Goreng');
    expect(repo.lastUpsert!.price, 15000);
    expect(find.text('open'), findsOneWidget);
    expect(find.text('Tambah item'), findsNothing);
  });

  testWidgets('save failure shows the error snackbar and stays', (
    tester,
  ) async {
    repo.failUpsert = true;
    await pumpEdit(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Nasi Goreng');
    await tester.enterText(find.byType(TextFormField).at(1), '15000');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    expect(find.text('Gagal menyimpan. Coba lagi.'), findsOneWidget);
    expect(find.text('Tambah item'), findsOneWidget);
  });

  testWidgets('edit mode prefills the item fields', (tester) async {
    await pumpEdit(tester, item: sampleItem());
    expect(find.text('Edit item'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);
    expect(find.text('Rendang'), findsOneWidget);
    expect(find.text('85000'), findsOneWidget);
    expect(find.text('Main'), findsOneWidget);
    expect(find.text('Hapus item'), findsOneWidget);
  });

  testWidgets('saving an edit sends the id and new price', (tester) async {
    await pumpEdit(tester, item: sampleItem());

    await tester.enterText(find.byType(TextFormField).at(1), '90000');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(repo.lastUpsert, isNotNull);
    expect(repo.lastUpsert!.id, 'm1');
    expect(repo.lastUpsert!.price, 90000);
    expect(repo.lastUpsert!.name, 'Rendang');
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('delete calls the repository and pops', (tester) async {
    await pumpEdit(tester, item: sampleItem());

    await tester.tap(find.text('Hapus item'));
    await tester.pumpAndSettle();

    expect(repo.deletedItems, ['m1']);
    expect(find.text('open'), findsOneWidget);
    expect(find.text('Edit item'), findsNothing);
  });
}

class _FakeMenuRepository implements MenuRepository {
  bool failUpsert = false;
  final deletedItems = <String>[];

  ({
    String restaurantId,
    String? id,
    String? categoryId,
    String name,
    String? description,
    int price,
    String? imageUrl,
    bool isAvailable,
  })?
  lastUpsert;

  @override
  Future<({List<MenuCategory> categories, List<MenuItem> items})> loadMenu({
    required String restaurantId,
  }) async {
    return (
      categories: const [
        MenuCategory(id: 'c1', restaurantId: 'r1', name: 'Main'),
      ],
      items: const <MenuItem>[],
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
    if (failUpsert) throw StateError('db down');
    lastUpsert = (
      restaurantId: restaurantId,
      id: id,
      categoryId: categoryId,
      name: name,
      description: description,
      price: price,
      imageUrl: imageUrl,
      isAvailable: isAvailable,
    );
    return MenuItem(
      id: id ?? 'new',
      restaurantId: restaurantId,
      categoryId: categoryId,
      name: name,
      description: description,
      price: Money.fromRupiah(price),
      imageUrl: imageUrl,
      isAvailable: isAvailable,
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
  Future<void> deleteItem(String itemId) async {
    deletedItems.add(itemId);
  }

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
