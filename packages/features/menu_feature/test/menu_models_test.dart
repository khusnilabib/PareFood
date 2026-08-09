import 'package:menu_feature/menu_feature.dart';
import 'package:pare_core/pare_core.dart';
import 'package:test/test.dart';

void main() {
  group('MenuCategory', () {
    test('equality covers all fields', () {
      const a = MenuCategory(
        id: 'c1',
        restaurantId: 'r1',
        name: 'Main',
        sortOrder: 3,
      );
      const same = MenuCategory(
        id: 'c1',
        restaurantId: 'r1',
        name: 'Main',
        sortOrder: 3,
      );
      const different = MenuCategory(
        id: 'c2',
        restaurantId: 'r1',
        name: 'Main',
      );
      expect(a, same);
      expect(a.hashCode, same.hashCode);
      expect(a, isNot(different));
      expect(a == Object(), isFalse);
    });
  });

  group('MenuItem', () {
    MenuItem build({int price = 85000}) {
      return MenuItem(
        id: 'm1',
        restaurantId: 'r1',
        categoryId: 'c1',
        name: 'Rendang',
        description: 'd',
        price: Money.fromRupiah(price),
        imageUrl: 'i.png',
        isAvailable: false,
        isFeatured: true,
        sortOrder: 2,
      );
    }

    test('equality covers all fields', () {
      final base = build();
      final same = build();
      final different = MenuItem(
        id: 'm1',
        restaurantId: 'r1',
        categoryId: 'c1',
        name: 'Sate',
        price: Money.fromRupiah(85000),
      );
      expect(base, same);
      expect(base.hashCode, same.hashCode);
      expect(base, isNot(different));
    });

    test('copyWith keeps fields unless overridden', () {
      final base = build();
      final untouched = base.copyWith();
      expect(untouched, base);

      final toggled = base.copyWith(isAvailable: true);
      expect(toggled.isAvailable, isTrue);
      expect(toggled.name, base.name);

      final repriced = base.copyWith(price: 5000);
      expect(repriced.price, Money.fromRupiah(5000));
      expect(repriced.isAvailable, base.isAvailable);
      expect(repriced.name, base.name);
    });
  });

  group('MenuImportResult', () {
    test('exposes the created and skipped tallies', () {
      const result = MenuImportResult(created: 2, skipped: 3);
      expect(result.created, 2);
      expect(result.skipped, 3);
    });
  });
}
