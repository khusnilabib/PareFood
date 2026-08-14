/// Riverpod providers for cart state management (PF-DOC-11 §3.2).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_core/pare_core.dart';

import '../data/cart_repository.dart';
import '../domain/cart.dart';
import '../domain/cart_use_cases.dart';

/// Seam for CartRepository (overridable in tests, FL-R04).
final cartRepositoryProvider = Provider<CartRepository>((ref) {
  throw UnimplementedError(
    'cartRepositoryProvider must be overridden in composition root',
  );
});

/// Mutable cart state (NotifierProvider per PF-DOC-11 §3.2).
final cartProvider = NotifierProvider<CartNotifier, Cart>(
  CartNotifier.new,
);

/// Notifier for cart state mutations.
class CartNotifier extends Notifier<Cart> {
  @override
  Cart build() => Cart(
    restaurantId: '',
    restaurantName: '',
    items: [],
    lastModifiedAt: DateTime.now().toUtc(),
  );

  void removeItem(String cartItemId) {
    state = RemoveFromCart().call(state, cartItemId);
  }

  void updateQuantity(String cartItemId, int newQuantity) {
    state = UpdateCartItemQuantity().call(state, cartItemId, newQuantity);
  }

  void clear() {
    state = ClearCart().call(state);
  }

  Future<void> loadFromStorage() async {
    final repo = ref.read(cartRepositoryProvider);
    state = await repo.getCart();
  }

  Future<void> saveToStorage() async {
    final repo = ref.read(cartRepositoryProvider);
    await repo.saveCart(state);
  }
}

/// Fee breakdown (mirrors BR-PRICE from PF-DOC-18).
class FeeBreakdown {
  const FeeBreakdown({
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.promoDiscount,
  });

  final Money subtotal;
  final Money deliveryFee;
  final Money serviceFee;
  final Money promoDiscount;

  Money get total => subtotal + deliveryFee + serviceFee - promoDiscount;

  factory FeeBreakdown.fromCart(Cart cart) {
    return FeeBreakdown(
      subtotal: cart.subtotal,
      deliveryFee: Money.fromRupiah(15000),
      serviceFee: Money.fromRupiah(2500),
      promoDiscount: Money.fromRupiah(0),
    );
  }
}

/// Computed fee breakdown provider (PF-DOC-11 §3.3).
final feeBreakdownProvider = Provider<FeeBreakdown>((ref) {
  final cart = ref.watch(cartProvider);
  return FeeBreakdown.fromCart(cart);
});
