import 'package:cart_feature/cart_feature.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pare_core/pare_core.dart';

void main() {
  CartItem item(String id, int price) {
    return CartItem(
      productId: id,
      name: 'Menu $id',
      unitPrice: Money.fromRupiah(price),
    );
  }

  group('Cart', () {
    test('adds a new item and accumulates quantity', () {
      final cart = const Cart.empty()
          .addItem(item('p1', 25000))
          .addItem(item('p1', 25000));
      expect(cart.items, hasLength(1));
      expect(cart.items.single.quantity, 2);
      expect(cart.subtotal, Money.fromRupiah(50000));
    });

    test('totals multiple lines', () {
      final cart = const Cart.empty()
          .addItem(item('p1', 25000))
          .addItem(item('p2', 10000));
      expect(cart.totalQuantity, 2);
      expect(cart.subtotal, Money.fromRupiah(35000));
    });

    test('removes a product and clears', () {
      final cart = const Cart.empty()
          .addItem(item('p1', 25000))
          .removeProduct('p1');
      expect(cart.isEmpty, isTrue);
      expect(const Cart.empty().clear().isEmpty, isTrue);
    });
  });

  group('AddToCart', () {
    test('rejects non-positive quantity', () {
      final zeroQty = CartItem(
        productId: 'p1',
        name: 'x',
        unitPrice: Money.fromRupiah(1),
        quantity: 0,
      );
      expect(
        () => const AddToCart().call(const Cart.empty(), zeroQty),
        throwsArgumentError,
      );
    });
  });

  group('CartNotifier', () {
    test('mutates state through the provider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(cartProvider.notifier).addItem(item('p1', 25000));
      container.read(cartProvider.notifier).addItem(item('p2', 10000));

      final cart = container.read(cartProvider);
      expect(cart.items, hasLength(2));
      expect(cart.subtotal, Money.fromRupiah(35000));

      container.read(cartProvider.notifier).clear();
      expect(container.read(cartProvider).isEmpty, isTrue);
    });

    test('removes a product through the provider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);
      notifier.addItem(item('p1', 25000));
      notifier.addItem(item('p2', 10000));
      notifier.removeProduct('p1');

      final cart = container.read(cartProvider);
      expect(cart.items, hasLength(1));
      expect(cart.items.single.productId, 'p2');
    });

    test('cartStoreProvider requires an override', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Riverpod 3 wraps build errors in a ProviderException on read(); the
      // listener seam surfaces the original UnimplementedError.
      Object? captured;
      container.listen(
        cartStoreProvider,
        (_, _) {},
        onError: (error, _) => captured = error,
        fireImmediately: true,
      );

      expect(captured, isA<UnimplementedError>());
    });
  });
}
