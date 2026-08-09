/// Cart domain rules (PF-DOC-11 §3.1). Quantity sanity lives here, never in
/// the UI (FL-R03).
library;

import 'cart.dart';
import 'cart_item.dart';

/// Adds [item] to [cart], rejecting non-positive quantities.
class AddToCart {
  const AddToCart();

  Cart call(Cart cart, CartItem item) {
    if (item.quantity <= 0) {
      throw ArgumentError('CartItem quantity must be positive.');
    }
    return cart.addItem(item);
  }
}
