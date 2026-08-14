/// Abstract CartRepository contract (PF-DOC-11 §3.3 data flow).
library;

import 'package:pare_core/pare_core.dart';

import '../domain/cart.dart';

/// Repository for cart persistence via drift/SQLite (PF-DOC-11 §3.4).
abstract class CartRepository {
  Future<Cart> getCart();
  Future<Cart> saveCart(Cart cart);
  Future<void> clearCart();
  Stream<Cart> watchCart();
}

/// In-memory implementation for testing (PF-DOC-20 TS-R06).
class InMemoryCartRepository implements CartRepository {
  Cart _cart = Cart(
    restaurantId: '',
    restaurantName: '',
    items: [],
    lastModifiedAt: DateTime.now().toUtc(),
  );

  @override
  Future<Cart> getCart() async => _cart;

  @override
  Future<Cart> saveCart(Cart cart) async {
    _cart = cart;
    return _cart;
  }

  @override
  Future<void> clearCart() async {
    _cart = Cart(
      restaurantId: '',
      restaurantName: '',
      items: [],
      lastModifiedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Stream<Cart> watchCart() async* {
    yield _cart;
  }
}
