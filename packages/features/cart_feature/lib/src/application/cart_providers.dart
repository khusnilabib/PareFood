/// Cart providers (PF-DOC-11 §3.2). The cart is client-side mutable state;
/// every mutation replaces the immutable [Cart] snapshot.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cart_store.dart';
import '../domain/cart.dart';
import '../domain/cart_item.dart';
import '../domain/cart_use_cases.dart';

/// Mutable cart state.
final cartProvider = NotifierProvider<CartNotifier, Cart>(CartNotifier.new);

/// Persistence seam; override at the composition root when wired to drift.
final cartStoreProvider = Provider<CartStore>((ref) {
  throw UnimplementedError(
    'cartStoreProvider must be overridden in the composition root.',
  );
});

class CartNotifier extends Notifier<Cart> {
  @override
  Cart build() => const Cart.empty();

  void addItem(CartItem item) {
    state = const AddToCart().call(state, item);
  }

  void removeProduct(String productId) {
    state = state.removeProduct(productId);
  }

  void clear() {
    state = const Cart.empty();
  }
}
