import 'package:cart_feature/cart_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pare_core/pare_core.dart';

void main() {
  testWidgets('renders name, unit price, quantity and line total', (
    tester,
  ) async {
    final item = CartItem(
      productId: 'p1',
      name: 'Nasi Goreng',
      unitPrice: Money.fromRupiah(25000),
      quantity: 3,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CartItemTile(item: item)),
      ),
    );

    expect(find.text('Nasi Goreng'), findsOneWidget);
    expect(find.text('3 × Rp 25.000'), findsOneWidget);
    expect(find.text('Rp 75.000'), findsOneWidget);
  });
}
