import 'package:cart_feature/cart_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Widget build(Cart cart) {
    return ProviderScope(
      overrides: [cartProvider.overrideWith(() => _SeededCartNotifier(cart))],
      child: const MaterialApp(home: CartPage()),
    );
  }

  testWidgets('empty cart shows the empty state', (tester) async {
    await tester.pumpWidget(build(const Cart.empty()));
    expect(find.text('Keranjang masih kosong'), findsOneWidget);
  });

  testWidgets('populated cart lists items and shows the total', (tester) async {
    final cart = const Cart.empty()
        .addItem(item('p1', 'Nasi Goreng', 25000, quantity: 2))
        .addItem(item('p2', 'Es Teh', 5000));
    await tester.pumpWidget(build(cart));

    expect(find.text('Nasi Goreng'), findsOneWidget);
    // CartItemTile shows unit price per item and a separate quantity stepper.
    expect(find.text('Rp 25.000 / item'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Rp 50.000'), findsOneWidget);
    expect(find.text('Es Teh'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Rp 55.000'), findsOneWidget);
    expect(find.text('Pesan Sekarang'), findsOneWidget);
  });

  testWidgets('checkout confirmation clears the cart', (tester) async {
    final cart = const Cart.empty().addItem(
      item('p1', 'Nasi Goreng', 25000, quantity: 1),
    );
    await tester.pumpWidget(build(cart));

    await tester.tap(find.text('Pesan Sekarang'));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi pesanan'), findsOneWidget);

    await tester.tap(find.text('Pesan'));
    await tester.pumpAndSettle();

    // Cart is cleared → empty state is shown.
    expect(find.text('Keranjang masih kosong'), findsOneWidget);
  });
}

class _SeededCartNotifier extends CartNotifier {
  _SeededCartNotifier(this._initial);

  final Cart _initial;

  @override
  Cart build() => _initial;
}
