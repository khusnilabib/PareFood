import 'package:cart_feature/cart_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: CartItemTile(item: item)),
        ),
      ),
    );

    expect(find.text('Nasi Goreng'), findsOneWidget);
    expect(find.text('Rp 25.000 / item'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Rp 75.000'), findsOneWidget);
  });

  testWidgets('decrement button removes the line when quantity hits zero', (
    tester,
  ) async {
    final item = CartItem(
      productId: 'p1',
      name: 'Nasi Goreng',
      unitPrice: Money.fromRupiah(25000),
      quantity: 1,
    );
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return CartItemTile(item: item);
              },
            ),
          ),
        ),
      ),
    );

    // Tap the decrement (remove) icon.
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();

    expect(capturedRef.read(cartProvider).isEmpty, isTrue);
  });
}
