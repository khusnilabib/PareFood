/// A single line in the cart (PF-DOC-11 §3.2 `cartProvider`).
library;

import 'package:pare_core/pare_core.dart';

/// Immutable cart line item. Equality is value-based.
class CartItem {
  const CartItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    this.quantity = 1,
  });

  final String productId;
  final String name;
  final Money unitPrice;
  final int quantity;

  /// Price × quantity, in rupiah.
  Money get lineTotal => unitPrice * quantity;

  CartItem copyWithQuantity(int quantity) {
    assert(quantity > 0);
    return CartItem(
      productId: productId,
      name: name,
      unitPrice: unitPrice,
      quantity: quantity,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CartItem &&
        other.productId == productId &&
        other.name == name &&
        other.unitPrice == unitPrice &&
        other.quantity == quantity;
  }

  @override
  int get hashCode => Object.hash(productId, name, unitPrice, quantity);
}
