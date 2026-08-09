import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_feature/menu_feature.dart';
import 'package:pare_core/pare_core.dart';

void main() {
  late _FakeMenuRepository repo;

  setUp(() {
    repo = _FakeMenuRepository();
    FilePicker.platform = _FakeFilePicker(
      FilePickerResult([
        PlatformFile(
          name: 'menu.csv',
          size: 3,
          bytes: Uint8List.fromList(
            utf8.encode(
              'name,price,category_id\n'
              'Rendang,85000,c1\n'
              'Sate,25000,\n'
              ',5000\n',
            ),
          ),
        ),
      ]),
    );
  });

  Widget build() {
    return ProviderScope(
      overrides: [menuRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: MenuManagementPage(restaurantId: 'r1')),
    );
  }

  ({List<MenuCategory> categories, List<MenuItem> items}) menu({
    bool withMain = false,
  }) {
    return (
      categories: withMain
          ? const [MenuCategory(id: 'c1', restaurantId: 'r1', name: 'Main')]
          : const <MenuCategory>[],
      items: [
        MenuItem(
          id: 'm1',
          restaurantId: 'r1',
          categoryId: withMain ? 'c1' : null,
          name: 'Rendang',
          price: Money.fromRupiah(85000),
        ),
        MenuItem(
          id: 'm2',
          restaurantId: 'r1',
          name: 'Ayam',
          price: Money.fromRupiah(15000),
        ),
      ],
    );
  }

  testWidgets('loading state shows a spinner then the list', (tester) async {
    final gate =
        Completer<({List<MenuCategory> categories, List<MenuItem> items})>();
    repo.loadGate = gate;
    await tester.pumpWidget(build());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete(menu());
    await tester.pumpAndSettle();
    expect(find.text('Rendang'), findsOneWidget);
    expect(repo.loadCount, 1);
  });

  testWidgets('error state shows retry and reloads on tap', (tester) async {
    repo.failLoad = true;
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    expect(find.text('Gagal memuat menu.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);

    repo.failLoad = false;
    repo.loadResult = menu();
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Rendang'), findsOneWidget);
    expect(repo.loadCount, 2);
  });

  testWidgets('data state groups items under category headers', (tester) async {
    repo.loadResult = menu(withMain: true);
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    expect(find.text('Main'), findsOneWidget);
    expect(find.text('Tanpa kategori'), findsOneWidget);
    expect(find.text('Rendang'), findsOneWidget);
    expect(find.text('Ayam'), findsOneWidget);
    expect(find.text('Rp 85.000 · Main'), findsOneWidget);
    expect(find.text('Rp 15.000 · '), findsOneWidget);
  });

  testWidgets('availability switch calls the repository and reloads', (
    tester,
  ) async {
    repo.loadResult = menu();
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    expect(find.byType(Switch), findsNWidgets(2));
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(repo.setAvailabilityCalls, [
      (restaurantId: 'r1', itemId: 'm1', isAvailable: false),
    ]);
    final switchWidget = tester.widget<Switch>(find.byType(Switch).first);
    expect(switchWidget.value, isFalse);
    expect(repo.loadCount, 2);
  });

  testWidgets('empty state offers a CSV import', (tester) async {
    repo.loadResult = (categories: const [], items: const <MenuItem>[]);
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    expect(find.text('Belum ada item'), findsOneWidget);
    expect(
      find.text('Tambahkan item pertama Anda atau impor dari CSV.'),
      findsOneWidget,
    );
    expect(find.text('Impor CSV'), findsOneWidget);
  });

  testWidgets('CSV import parses rows and reports the tally', (tester) async {
    repo.loadResult = (categories: const [], items: const <MenuItem>[]);
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Impor CSV'));
    await tester.pumpAndSettle();

    expect(repo.lastImportRows, hasLength(3));
    expect(
      repo.lastImportRows![0],
      equals({'name': 'Rendang', 'price': '85000', 'category_id': 'c1'}),
    );
    expect(find.text('Impor selesai: 2 dibuat, 1 dilewati.'), findsOneWidget);
    expect(repo.loadCount, 2);
  });

  testWidgets('tapping an item opens the edit page', (tester) async {
    repo.loadResult = menu();
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rendang'));
    await tester.pumpAndSettle();
    expect(find.text('Edit item'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Menu'), findsOneWidget);
  });
}

class _FakeFilePicker extends FilePicker {
  _FakeFilePicker(this._result);

  final FilePickerResult _result;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    void Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    return _result;
  }
}

class _FakeMenuRepository implements MenuRepository {
  ({List<MenuCategory> categories, List<MenuItem> items})? loadResult;
  Completer<({List<MenuCategory> categories, List<MenuItem> items})>? loadGate;
  bool failLoad = false;
  int loadCount = 0;

  final setAvailabilityCalls =
      <({String restaurantId, String itemId, bool isAvailable})>[];
  List<Map<String, String>>? lastImportRows;
  MenuImportResult importResult = const MenuImportResult(
    created: 2,
    skipped: 1,
  );

  @override
  Future<({List<MenuCategory> categories, List<MenuItem> items})> loadMenu({
    required String restaurantId,
  }) async {
    loadCount++;
    if (loadGate != null) return loadGate!.future;
    if (failLoad) throw StateError('db down');
    return loadResult ??
        (categories: const <MenuCategory>[], items: const <MenuItem>[]);
  }

  @override
  Future<MenuItem> setAvailability({
    required String restaurantId,
    required String itemId,
    required bool isAvailable,
  }) async {
    setAvailabilityCalls.add((
      restaurantId: restaurantId,
      itemId: itemId,
      isAvailable: isAvailable,
    ));
    final current = loadResult;
    if (current != null) {
      loadResult = (
        categories: current.categories,
        items: current.items
            .map(
              (it) =>
                  it.id == itemId ? it.copyWith(isAvailable: isAvailable) : it,
            )
            .toList(),
      );
    }
    return MenuItem(
      id: itemId,
      restaurantId: restaurantId,
      name: 'Stub',
      price: Money.fromRupiah(0),
      isAvailable: isAvailable,
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
    lastImportRows = rows;
    return importResult;
  }
}
