/// Orders providers (PF-DOC-11 §3.2).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/orders_repository.dart';
import '../domain/order_detail.dart';
import '../domain/order_summary.dart';
import '../domain/orders_use_cases.dart';

/// Repository contract; override at the composition root (FL-R04).
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  throw UnimplementedError(
    'ordersRepositoryProvider must be overridden in the composition root.',
  );
});

// --- Use cases ---

final fetchCustomerOrdersProvider = Provider<FetchCustomerOrders>((ref) {
  return FetchCustomerOrders(ref.watch(ordersRepositoryProvider));
});

final fetchRestaurantOrdersProvider = Provider<FetchRestaurantOrders>((ref) {
  return FetchRestaurantOrders(ref.watch(ordersRepositoryProvider));
});

final fetchDriverJobsProvider = Provider<FetchDriverJobs>((ref) {
  return FetchDriverJobs(ref.watch(ordersRepositoryProvider));
});

final fetchAllOrdersProvider = Provider<FetchAllOrders>((ref) {
  return FetchAllOrders(ref.watch(ordersRepositoryProvider));
});

final fetchOrderDetailProvider = Provider<FetchOrderDetail>((ref) {
  return FetchOrderDetail(ref.watch(ordersRepositoryProvider));
});

// --- View providers ---

/// Active + recent orders for the signed-in customer (FR-ORDER-009).
final customerOrdersProvider = FutureProvider<List<OrderSummary>>((ref) {
  return ref.watch(fetchCustomerOrdersProvider).call();
});

/// Incoming orders for the signed-in merchant's restaurant (FR-ORDER-002).
/// Pass a restaurant id to scope; null = all owned restaurants.
final restaurantOrdersProvider =
    FutureProvider.family<List<OrderSummary>, String?>((ref, restaurantId) {
      return ref
          .watch(fetchRestaurantOrdersProvider)
          .call(restaurantId: restaurantId);
    });

/// Delivery jobs for the signed-in driver (FR-ORDER-004).
final driverJobsProvider = FutureProvider<List<DeliveryJob>>((ref) {
  return ref.watch(fetchDriverJobsProvider).call();
});

/// All orders for the admin board (FR-ORDER-011).
final allOrdersProvider = FutureProvider<List<OrderSummary>>((ref) {
  return ref.watch(fetchAllOrdersProvider).call();
});

/// One order's full detail (FR-ORDER-009).
final orderDetailProvider = FutureProvider.family<OrderDetail, String>((
  ref,
  orderId,
) {
  return ref.watch(fetchOrderDetailProvider).call(orderId);
});

/// Backwards-compatible alias kept for the existing [OrdersPage] customer view
/// (the original `activeOrdersProvider`). Now routes through the customer
/// use case so it is role-scoped.
final activeOrdersProvider = customerOrdersProvider;
