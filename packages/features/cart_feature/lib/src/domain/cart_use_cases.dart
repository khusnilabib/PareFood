/// Pure domain use cases for cart operations (PF-DOC-11 §3.1).
library;

import 'package:pare_core/pare_core.dart';

import 'cart.dart';
import 'cart_item.dart';

/// Adds item to cart, enforcing single-restaurant constraint (FR-CART-001).
class AddToCart {
  const AddToCart();

  Cart call(
    Cart cart,
    String restaurantId,
    String restaurantName,
    CartItem item,
  ) {
    if (cart.items.isNotEmpty && cart.restaurantId != restaurantId) {
      throw BusinessRuleException(
        'Single restaurant per cart. Current: ${cart.restaurantName}, '
        'Attempted: $restaurantName',
      );
    }

    final existingIndex = cart.items.indexWhere(
      (existing) =>
          existing.menuItemId == item.menuItemId &&
          _optionsMatch(existing.selectedOptions, item.selectedOptions),
    );

    if (existingIndex >= 0) {
      final updated = cart.items[existingIndex].copyWith(
        quantity: cart.items[existingIndex].quantity + item.quantity,
      );
      return cart.copyWith(
        items: <CartItem>[
          ...cart.items.sublist(0, existingIndex),
          updated,
          ...cart.items.sublist(existingIndex + 1),
        ],
        lastModifiedAt: DateTime.now().toUtc(),
      );
    }

    return cart.copyWith(
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      items: <CartItem>[...cart.items, item],
      lastModifiedAt: DateTime.now().toUtc(),
    );
  }

  bool _optionsMatch(
    List<CartItemOption> a,
    List<CartItemOption> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].optionValueId != b[i].optionValueId) return false;
    }
    return true;
  }
}

/// Removes item from cart by cartItemId.
class RemoveFromCart {
  const RemoveFromCart();

  Cart call(Cart cart, String cartItemId) {
    final filtered = cart.items.where((i) => i.cartItemId != cartItemId).toList();
    return cart.copyWith(
      items: filtered,
      lastModifiedAt: DateTime.now().toUtc(),
    );
  }
}

/// Updates quantity of item (removes if qty <= 0).
class UpdateCartItemQuantity {
  const UpdateCartItemQuantity();

  Cart call(Cart cart, String cartItemId, int newQuantity) {
    if (newQuantity <= 0) {
      return RemoveFromCart().call(cart, cartItemId);
    }

    final updated = cart.items.map((item) {
      if (item.cartItemId == cartItemId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    return cart.copyWith(
      items: updated,
      lastModifiedAt: DateTime.now().toUtc(),
    );
  }
}

/// Clears entire cart.
class ClearCart {
  const ClearCart();

  Cart call(Cart cart) => cart.copyWith(
        items: [],
        lastModifiedAt: DateTime.now().toUtc(),
      );
}
