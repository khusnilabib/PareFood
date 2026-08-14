/// Cart aggregate root — immutable value object (Freezed).
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pare_core/pare_core.dart';

import 'cart_item.dart';

part 'cart.freezed.dart';

/// Immutable cart state holding restaurant context + items.
@freezed
class Cart with _\$Cart {
  const Cart._();

  const factory Cart({
    required String restaurantId,
    required String restaurantName,
    @Default(<CartItem>[]) List<CartItem> items,
    required DateTime lastModifiedAt,
  }) = _Cart;

  bool get isEmpty => items.isEmpty;
  int get itemCount => items.fold<int>(0, (sum, item) => sum + item.quantity);
  Money get subtotal =>
      items.fold(Money.fromRupiah(0), (sum, item) => sum + item.itemTotal);
}
