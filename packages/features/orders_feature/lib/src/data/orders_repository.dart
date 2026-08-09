/// Orders repository contract (PF-DOC-11 §3.1 data layer).
///
/// Concrete implementations live in the app composition root and delegate to
/// `pare_data` (Dio/Supabase); features never import the SDKs directly
/// (MO-R02a). Overrides of [ordersRepositoryProvider] are the only test seam
/// (FL-R04).
library;

import 'package:pare_core/pare_core.dart';

import '../domain/order_summary.dart';

/// Contract implemented by the composition root.
abstract interface class OrdersRepository {
  /// Active + recent orders for the signed-in user. Empty when none.
  Future<List<OrderSummary>> fetchActive();

  /// Fetches one order by id; throws [PareNotFoundException] when missing.
  Future<OrderSummary> fetchById(String id);
}
