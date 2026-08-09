/// Local cart persistence contract (offline strategy, PF-DOC-11 §3.4).
///
/// The cart must survive app restarts and sync on reconnection. Implemented
/// with drift/SQLite later; override in tests (FL-R04).
library;

import '../domain/cart.dart';

/// Contract implemented by the composition root.
abstract interface class CartStore {
  Future<Cart> load();

  Future<void> save(Cart cart);
}
