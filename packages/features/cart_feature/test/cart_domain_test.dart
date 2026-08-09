import 'package:cart_feature/cart_feature.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pare_core/pare_core.dart';

void main() {
  CartItem item(String id, String name, int price, {int quantity = 1}) {
    return CartItem(
      productId: id,
      name: name,
      unitPrice: Money.fromRupiah(price),
      quantity: quantity,
    );
  }

  group('CartItem', () {
    test('computes line total from unit price and quantity', () {
      expect(
        item('p1', 'Nasi Goreng', 25000, quantity: 3).lineTotal,
        Money.fromRupiah(75000),
      );
    });

    test('copyWithQuantity replaces the quantity and keeps the rest', () {
      final updated = item('p1', 'Nasi Goreng', 25000).copyWithQuantity(5);
      expect(updated.productId, 'p1');
      expect(updated.name, 'Nasi Goreng');
      expect(updated.unitPrice, Money.fromRupiah(25000));
      expect(updated.quantity, 5);
    });

    test('is value-equal when fields match', () {
      final a = item('p1', 'Nasi Goreng', 25000, quantity: 2);
      final b = item('p1', 'Nasi Goreng', 25000, quantity: 2);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when any field changes', () {
      expect(
        item('p2', 'Nasi Goreng', 25000),
        isNot(equals(item('p1', 'Nasi Goreng', 25000))),
      );
      expect(
        item('p1', 'Es Teh', 25000),
        isNot(equals(item('p1', 'Nasi Goreng', 25000))),
      );
      expect(
        item('p1', 'Nasi Goreng', 5000),
        isNot(equals(item('p1', 'Nasi Goreng', 25000))),
      );
      expect(
        item('p1', 'Nasi Goreng', 25000, quantity: 3),
        isNot(equals(item('p1', 'Nasi Goreng', 25000))),
      );
    });
  });

  group('Cart', () {
    test('empty cart is empty with zero totals', () {
      const cart = Cart.empty();
      expect(cart.isEmpty, isTrue);
      expect(cart.totalQuantity, 0);
      expect(cart.subtotal, Money.fromRupiah(0));
    });

    test('totalQuantity sums units across lines', () {
      final cart = const Cart.empty()
          .addItem(item('p1', 'Nasi Goreng', 25000, quantity: 2))
          .addItem(item('p2', 'Es Teh', 5000, quantity: 3));
      expect(cart.totalQuantity, 5);
    });

    test('subtotal sums line totals', () {
      final cart = const Cart.empty()
          .addItem(item('p1', 'Nasi Goreng', 25000, quantity: 2))
          .addItem(item('p2', 'Es Teh', 5000, quantity: 3));
      expect(cart.subtotal, Money.fromRupiah(65000));
    });

    test('addItem appends a new product and merges an existing one', () {
      final cart = const Cart.empty()
          .addItem(item('p1', 'Nasi Goreng', 25000))
          .addItem(item('p2', 'Es Teh', 5000))
          .addItem(item('p1', 'Nasi Goreng', 25000, quantity: 2));
      expect(cart.items, hasLength(2));
      expect(cart.items.first.quantity, 3);
    });

    test('removeProduct removes every line for a product', () {
      final cart = const Cart.empty()
          .addItem(item('p1', 'Nasi Goreng', 25000, quantity: 2))
          .addItem(item('p2', 'Es Teh', 5000))
          .removeProduct('p1');
      expect(cart.items, hasLength(1));
      expect(cart.items.single.productId, 'p2');
    });

    test('clear returns an empty cart', () {
      final cart = const Cart.empty().addItem(item('p1', 'Nasi Goreng', 25000));
      expect(cart.clear().isEmpty, isTrue);
    });
  });
}
