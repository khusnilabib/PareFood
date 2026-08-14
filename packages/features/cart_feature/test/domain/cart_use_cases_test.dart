/// Unit tests for cart use cases (PF-DOC-20 §3.2).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pare_core/pare_core.dart';
import 'package:cart_feature/src/domain/cart.dart';
import 'package:cart_feature/src/domain/cart_item.dart';
import 'package:cart_feature/src/domain/cart_use_cases.dart';

void main() {
  group('AddToCart', () {
    const useCase = AddToCart();

    test('adds item to empty cart', () {
      final item = CartItem(
        cartItemId: '1',
        menuItemId: 'menu-1',
        name: 'Nasi Padang',
        unitPrice: Money.fromRupiah(25000),
        quantity: 1,
        selectedOptions: [],
        addedAt: DateTime.now().toUtc(),
      );
      final emptyCart = Cart(
        restaurantId: '',
        restaurantName: '',
        items: [],
        lastModifiedAt: DateTime.now().toUtc(),
      );

      final result = useCase(
        emptyCart,
        'rest-1',
        'Rumah Makan Padang',
        item,
      );

      expect(result.items.length, 1);
      expect(result.restaurantId, 'rest-1');
    });

    test('throws on restaurant mismatch (FR-CART-001)', () {
      final item1 = CartItem(
        cartItemId: '1',
        menuItemId: 'menu-1',
        name: 'Nasi Padang',
        unitPrice: Money.fromRupiah(25000),
        quantity: 1,
        selectedOptions: [],
        addedAt: DateTime.now().toUtc(),
      );
      final cart = Cart(
        restaurantId: 'rest-1',
        restaurantName: 'Rumah Makan Padang',
        items: [item1],
        lastModifiedAt: DateTime.now().toUtc(),
      );

      final item2 = CartItem(
        cartItemId: '2',
        menuItemId: 'menu-2',
        name: 'Gado-gado',
        unitPrice: Money.fromRupiah(15000),
        quantity: 1,
        selectedOptions: [],
        addedAt: DateTime.now().toUtc(),
      );

      expect(
        () => useCase(cart, 'rest-2', 'Warung Soto', item2),
        throwsA(isA<BusinessRuleException>()),
      );
    });
  });
}
