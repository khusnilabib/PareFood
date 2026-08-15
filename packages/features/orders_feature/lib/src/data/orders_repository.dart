/// Orders repository contract (PF-DOC-11 §3.1 data layer).
///
/// Concrete implementations live in the app composition root and delegate to
/// `pare_data` (Dio/Supabase); features never import the SDKs directly
/// (MO-R02a). Overrides of [ordersRepositoryProvider] are the only test seam
/// (FL-R04).
library;

import 'package:pare_core/pare_core.dart';

import '../domain/order_detail.dart';
import '../domain/order_status.dart';
import '../domain/order_summary.dart';

/// Contract implemented by the composition root. Each method is role-scoped:
/// the caller's JWT + RLS determines which rows are visible (PF-DOC-19).
abstract interface class OrdersRepository {
  /// Active + recent orders for the signed-in customer (FR-ORDER-009).
  Future<List<OrderSummary>> fetchForCustomer();

  /// Orders for the signed-in merchant's restaurant(s) (FR-ORDER-002).
  /// Filterable by status; null = all statuses.
  Future<List<OrderSummary>> fetchForRestaurant({
    String? restaurantId,
    Set<OrderStatus>? statuses,
  });

  /// Delivery jobs assigned to the signed-in driver (FR-ORDER-004).
  /// Includes active + recent; the app filters to active for the feed.
  Future<List<DeliveryJob>> fetchForDriver();

  /// All orders — admin only (FR-ORDER-011). Filterable for the live board.
  Future<List<OrderSummary>> fetchAll({
    Set<OrderStatus>? statuses,
    String? search,
  });

  /// One order summary by id; throws [PareNotFoundException] when missing.
  Future<OrderSummary> fetchById(String id);

  /// Full order detail with items + timeline (FR-ORDER-009).
  Future<OrderDetail> fetchDetail(String id);
}
