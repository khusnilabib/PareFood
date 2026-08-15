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

  /// Adds [item] to the cart, binding it to [restaurantId]/[restaurantName].
  /// A different restaurant resets the cart (BR-CART-001); the UI confirms
  /// first, but the invariant is enforced here regardless.
  void addItem(CartItem item, {String? restaurantId, String? restaurantName}) {
    state = const AddToCart().call(
      state,
      item,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
    );
  }

  /// Sets the quantity for [productId]; removes the line when [quantity] ≤ 0.
  void updateQuantity(String productId, int quantity) {
    state = state.updateQuantity(productId, quantity);
  }

  /// Increments [productId] by one (no-op if the line does not exist).
  void increment(String productId) {
    final existing = _lineFor(productId);
    if (existing == null) return;
    state = state.updateQuantity(productId, existing.quantity + 1);
  }

  /// Decrements [productId] by one; removes the line at quantity 0.
  void decrement(String productId) {
    final existing = _lineFor(productId);
    if (existing == null) return;
    state = state.updateQuantity(productId, existing.quantity - 1);
  }

  CartItem? _lineFor(String productId) {
    for (final item in state.items) {
      if (item.productId == productId) return item;
    }
    return null;
  }

  void removeProduct(String productId) {
    state = state.removeProduct(productId);
  }

  void clear() {
    state = const Cart.empty();
  }
}
