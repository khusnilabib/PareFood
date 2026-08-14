/// CartItem value object — menu item instance with options + quantity (Freezed).
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pare_core/pare_core.dart';

part 'cart_item.freezed.dart';

/// Selected option for cart item (e.g., size, topping).
@freezed
class CartItemOption with _\$CartItemOption {
  const factory CartItemOption({
    required String optionGroupId,
    required String optionGroupName,
    required String optionValueId,
    required String optionValueLabel,
    required Money extraPrice,
  }) = _CartItemOption;
}

/// Menu item instance in cart with options + quantity.
@freezed
class CartItem with _\$CartItem {
  const CartItem._();

  const factory CartItem({
    required String cartItemId,
    required String menuItemId,
    required String name,
    required Money unitPrice,
    required int quantity,
    @Default(<CartItemOption>[]) List<CartItemOption> selectedOptions,
    String? notes,
    required DateTime addedAt,
  }) = _CartItem;

  /// Total price: (unit + options) × quantity.
  Money get itemTotal {
    final optionsTotalPerUnit = selectedOptions.fold(
      Money.fromRupiah(0),
      (sum, opt) => sum + opt.extraPrice,
    );
    final pricePerUnit = unitPrice + optionsTotalPerUnit;
    return pricePerUnit * quantity;
  }
}
