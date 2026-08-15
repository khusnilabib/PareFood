/// Orders use cases (PF-DOC-11 §3.1 domain layer). Pure Dart; no Flutter.
library;

import '../data/orders_repository.dart';
import 'order_detail.dart';
import 'order_status.dart';
import 'order_summary.dart';

/// Loads the current customer's orders (FR-ORDER-009).
class FetchCustomerOrders {
  const FetchCustomerOrders(this._repository);
  final OrdersRepository _repository;
  Future<List<OrderSummary>> call() => _repository.fetchForCustomer();
}

/// Loads orders for the merchant's restaurant (FR-ORDER-002).
class FetchRestaurantOrders {
  const FetchRestaurantOrders(this._repository);
  final OrdersRepository _repository;
  Future<List<OrderSummary>> call({
    String? restaurantId,
    Set<OrderStatus>? statuses,
  }) {
    return _repository.fetchForRestaurant(
      restaurantId: restaurantId,
      statuses: statuses,
    );
  }
}

/// Loads delivery jobs for the signed-in driver (FR-ORDER-004).
class FetchDriverJobs {
  const FetchDriverJobs(this._repository);
  final OrdersRepository _repository;
  Future<List<DeliveryJob>> call() => _repository.fetchForDriver();
}

/// Loads all orders for the admin board (FR-ORDER-011).
class FetchAllOrders {
  const FetchAllOrders(this._repository);
  final OrdersRepository _repository;
  Future<List<OrderSummary>> call({
    Set<OrderStatus>? statuses,
    String? search,
  }) {
    return _repository.fetchAll(statuses: statuses, search: search);
  }
}

/// Loads one order's full detail (FR-ORDER-009).
class FetchOrderDetail {
  const FetchOrderDetail(this._repository);
  final OrdersRepository _repository;
  Future<OrderDetail> call(String id) => _repository.fetchDetail(id);
}
