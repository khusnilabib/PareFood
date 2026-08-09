/// Cart aggregate root (PF-DOC-11 §3.2 mutable UI state via Notifier).
library;

import 'package:pare_core/pare_core.dart';

import 'cart_item.dart';

/// Immutable cart snapshot. Mutations return new instances.
class Cart {
  const Cart({this.items = const <CartItem>[]});

  const Cart.empty() : this();

  final List<CartItem> items;

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

  /// Adds [item], merging with the existing line for the same product.
  Cart addItem(CartItem item) {
    final existingIndex = items.indexWhere(
      (existing) => existing.productId == item.productId,
    );
    if (existingIndex < 0) {
      return Cart(items: <CartItem>[...items, item]);
    }
    final updated = <CartItem>[...items];
    final existing = updated[existingIndex];
    updated[existingIndex] = existing.copyWithQuantity(
      existing.quantity + item.quantity,
    );
    return Cart(items: updated);
  }

  /// Removes every line for [productId].
  Cart removeProduct(String productId) {
    return Cart(items: items.where((i) => i.productId != productId).toList());
  }

  Cart clear() => const Cart.empty();
}
