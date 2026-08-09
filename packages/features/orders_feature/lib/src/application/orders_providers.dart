/// Orders providers (PF-DOC-11 §3.2).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/orders_repository.dart';
import '../domain/order_summary.dart';
import '../domain/orders_use_cases.dart';

/// Repository contract; override at the composition root (FL-R04).
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  throw UnimplementedError(
    'ordersRepositoryProvider must be overridden in the composition root.',
  );
});

/// Loads active + recent orders for the signed-in user.
final fetchActiveOrdersProvider = Provider<FetchActiveOrders>((ref) {
  return FetchActiveOrders(ref.watch(ordersRepositoryProvider));
});

/// Active + recent orders for the home/order-tracking screens.
final activeOrdersProvider = FutureProvider<List<OrderSummary>>((ref) {
  return ref.watch(fetchActiveOrdersProvider).call();
});
