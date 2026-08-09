/// Orders use cases (PF-DOC-11 §3.1 domain layer). Pure Dart; no Flutter.
library;

import '../data/orders_repository.dart';
import 'order_summary.dart';

/// Loads the current user's orders. Errors surface as typed `PareException`
/// from the repository (PF-DOC-11 §3.5).
class FetchActiveOrders {
  const FetchActiveOrders(this._repository);

  final OrdersRepository _repository;

  Future<List<OrderSummary>> call() => _repository.fetchActive();
}
