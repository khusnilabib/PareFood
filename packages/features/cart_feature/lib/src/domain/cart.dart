/// Cart aggregate root (PF-DOC-11 §3.2 mutable UI state via Notifier).
///
/// Tracks the single-restaurant constraint (BR-CART-001): a cart is bound to
/// at most one restaurant. Adding an item from a different restaurant resets
/// the cart to that restaurant (the UI asks for confirmation first).
library;

import 'package:pare_core/pare_core.dart';

import 'cart_item.dart';

/// Immutable cart snapshot. Mutations return new instances.
class Cart {
  const Cart({
    this.items = const <CartItem>[],
    this.restaurantId,
    this.restaurantName,
  });

  const Cart.empty() : this();

  final List<CartItem> items;

  /// The restaurant this cart is currently bound to (BR-CART-001).
  /// `null` when the cart is empty.
  final String? restaurantId;
  final String? restaurantName;

  bool get isEmpty => items.isEmpty;

  /// Number of units across all lines.
  int get totalQuantity {
    var sum = 0;
    for (final item in items) {
      sum += item.quantity;
    }
    return sum;
  }

  /// Sum of line totals, in rupiah.
  Money get subtotal {
    var total = Money.fromRupiah(0);
    for (final item in items) {
      total += item.lineTotal;
    }
    return total;
  }

  /// Whether [restaurantId] is compatible with this cart: true when the cart
  /// is empty (no restaurant bound) or already bound to [restaurantId].
  bool isSameRestaurant(String? restaurantId) {
    return this.restaurantId == null || this.restaurantId == restaurantId;
  }

  /// Adds [item], merging with the existing line for the same product.
  ///
  /// If [restaurantId] differs from the cart's current restaurant, the cart is
  /// reset to the new restaurant with only [item] (BR-CART-001). The UI is
  /// responsible for confirming the replacement; the domain enforces the
  /// invariant regardless.
  Cart addItem(CartItem item, {String? restaurantId, String? restaurantName}) {
    if (!isSameRestaurant(restaurantId)) {
      return Cart(
        items: <CartItem>[item],
        restaurantId: restaurantId,
        restaurantName: restaurantName,
      );
    }
    final existingIndex = items.indexWhere(
      (existing) => existing.productId == item.productId,
    );
    if (existingIndex < 0) {
      return Cart(
        items: <CartItem>[...items, item],
        restaurantId: restaurantId ?? this.restaurantId,
        restaurantName: restaurantName ?? this.restaurantName,
      );
    }
    final updated = <CartItem>[...items];
    final existing = updated[existingIndex];
    updated[existingIndex] = existing.copyWithQuantity(
      existing.quantity + item.quantity,
    );
    return Cart(
      items: updated,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
    );
  }

  /// Replaces the quantity for [productId]; removes the line when quantity ≤ 0.
  Cart updateQuantity(String productId, int quantity) {
    if (quantity <= 0) return removeProduct(productId);
    final updated = items.map((item) {
      return item.productId == productId
          ? item.copyWithQuantity(quantity)
          : item;
    }).toList();
    return Cart(
      items: updated,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
    );
  }

  /// Removes every line for [productId]. Clears the restaurant binding when
  /// the cart becomes empty.
  Cart removeProduct(String productId) {
    final remaining = items.where((i) => i.productId != productId).toList();
    if (remaining.isEmpty) return const Cart.empty();
    return Cart(
      items: remaining,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
    );
  }

  Cart clear() => const Cart.empty();
}
