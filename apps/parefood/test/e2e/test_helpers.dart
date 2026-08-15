/// Shared in-memory backend for E2E tests. Simulates Supabase + Edge
/// Functions so all 4 apps' repositories interact with the same state.
///
/// Extracted to a helper so both cross_app_lifecycle_test and edge_cases_test
/// can reuse it without duplicating code.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orders_feature/orders_feature.dart';
import 'package:pare_core/pare_core.dart';

class OrderItemSeed {
  const OrderItemSeed({
    required this.id,
    required this.name,
    required this.price,
    required this.qty,
  });
  final String id;
  final String name;
  final int price;
  final int qty;
}

OrderItemSeed seedItem(String id, String name, int price, int qty) {
  return OrderItemSeed(id: id, name: name, price: price, qty: qty);
}

/// A shared in-memory backend that simulates the real Supabase + Edge
/// Functions so all 4 apps' repositories interact with the same state.
class SharedBackend {
  final Map<String, OrderRow> orders = {};
  final Map<String, DeliveryRow> deliveries = {};
  int orderSeq = 0;

  late final CustomerTestRepo customerRepo = CustomerTestRepo(this);
  late final MerchantTestRepo merchantRepo = MerchantTestRepo(this);
  late final DriverTestRepo driverRepo = DriverTestRepo(this);
  late final AdminTestRepo adminRepo = AdminTestRepo(this);

  String newOrderNo() => 'PF-${++orderSeq}';
}

class OrderRow {
  OrderRow({
    required this.id,
    required this.orderNo,
    required this.restaurantId,
    required this.customerName,
    required this.subtotal,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.placedAt,
  });

  final String id;
  final String orderNo;
  final String restaurantId;
  final String customerName;
  final Money subtotal;
  final String deliveryAddress;
  final String paymentMethod;
  final DateTime placedAt;
  OrderStatus status = OrderStatus.placed;
  String? cancelReason;
}

class DeliveryRow {
  DeliveryRow({
    required this.id,
    required this.orderId,
    this.pickupCode = '1234',
  });
  final String id;
  final String orderId;
  final String pickupCode;
  DeliveryStatus status = DeliveryStatus.assigned;
}

// --- Customer repo (AP-PF) ---

class CustomerTestRepo {
  CustomerTestRepo(this._b);
  final SharedBackend _b;

  Future<OrderSummary> placeOrder({
    required String restaurantId,
    required List<OrderItemSeed> items,
    required String deliveryAddress,
    required String paymentMethod,
  }) async {
    final subtotal = items.fold(
      Money.fromRupiah(0),
      (sum, i) => sum + Money.fromRupiah(i.price * i.qty),
    );
    final id = 'o-${_b.orders.length + 1}';
    final order = OrderRow(
      id: id,
      orderNo: _b.newOrderNo(),
      restaurantId: restaurantId,
      customerName: 'Budi',
      subtotal: subtotal,
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      placedAt: DateTime.now(),
    );
    _b.orders[id] = order;
    return toSummary(order);
  }

  Future<OrderSummary> fetchById(String id) async {
    final row = _b.orders[id];
    if (row == null) throw PareNotFoundException('Order $id not found.');
    return toSummary(row);
  }

  Future<OrderSummary> cancelOrder(String id, {required String reason}) async {
    final row = _b.orders[id];
    if (row == null) throw PareNotFoundException('Order $id not found.');
    if (row.status != OrderStatus.placed &&
        row.status != OrderStatus.accepted) {
      throw const PareAuthException('Cannot cancel from current state');
    }
    row.status = OrderStatus.cancelled;
    row.cancelReason = reason;
    return toSummary(row);
  }

  OrderSummary toSummary(OrderRow r) => OrderSummary(
    id: r.id,
    orderNo: r.orderNo,
    restaurantName: 'Warung Budi',
    customerName: r.customerName,
    total: r.subtotal,
    status: r.status,
    placedAt: r.placedAt,
  );
}

// --- Merchant repo (AP-PB) ---

class MerchantTestRepo {
  MerchantTestRepo(this._b);
  final SharedBackend _b;

  Future<List<OrderSummary>> fetchForRestaurant({String? restaurantId}) async {
    return _b.orders.values
        .where((o) => restaurantId == null || o.restaurantId == restaurantId)
        .map(
          (r) => OrderSummary(
            id: r.id,
            orderNo: r.orderNo,
            restaurantName: '',
            customerName: r.customerName,
            total: r.subtotal,
            status: r.status,
            placedAt: r.placedAt,
          ),
        )
        .toList();
  }

  Future<OrderSummary> acceptOrder(String id) async {
    final row = _b.orders[id];
    if (row == null) throw PareNotFoundException('Order $id not found.');
    if (row.status != OrderStatus.placed) {
      throw const PareAuthException('Not in placed state');
    }
    row.status = OrderStatus.preparing;
    return toSummary(row);
  }

  Future<OrderSummary> declineOrder(String id) async {
    final row = _b.orders[id];
    if (row == null) throw PareNotFoundException('Order $id not found.');
    if (row.status != OrderStatus.placed) {
      throw const PareAuthException('Not in placed state');
    }
    row.status = OrderStatus.cancelled;
    row.cancelReason = 'merchant_declined';
    return toSummary(row);
  }

  Future<OrderSummary> markReady(String id) async {
    final row = _b.orders[id];
    if (row == null) throw PareNotFoundException('Order $id not found.');
    if (row.status != OrderStatus.preparing) {
      throw const PareAuthException('Not in preparing state');
    }
    row.status = OrderStatus.ready;
    final delivery = DeliveryRow(id: 'd-$id', orderId: id);
    _b.deliveries[delivery.id] = delivery;
    return toSummary(row);
  }

  OrderSummary toSummary(OrderRow r) => OrderSummary(
    id: r.id,
    orderNo: r.orderNo,
    restaurantName: 'Warung Budi',
    customerName: r.customerName,
    total: r.subtotal,
    status: r.status,
    placedAt: r.placedAt,
  );
}

// --- Driver repo (AP-PD) ---

class DriverTestRepo {
  DriverTestRepo(this._b);
  final SharedBackend _b;

  Future<List<DeliveryJob>> fetchForDriver() async {
    return _b.deliveries.values.map((d) {
      final order = _b.orders[d.orderId]!;
      return DeliveryJob(
        deliveryId: d.id,
        orderId: d.orderId,
        orderNo: order.orderNo,
        restaurantName: 'Warung Budi',
        restaurantAddress: 'Jl. Restoran',
        customerName: order.customerName,
        deliveryAddress: order.deliveryAddress,
        status: d.status,
        fare: Money.fromRupiah(6000),
        distanceKm: 2.5,
        pickupCode: d.pickupCode,
      );
    }).toList();
  }

  Future<DeliveryJob> acceptJob(String deliveryId) async {
    final d = _b.deliveries[deliveryId];
    if (d == null) throw PareNotFoundException('Delivery not found.');
    return toJob(d);
  }

  Future<void> declineJob(String deliveryId) async {
    // No-op: declining never changes the delivery state (BR-DISPATCH-006).
  }

  Future<DeliveryJob> pickup(String deliveryId, {required String code}) async {
    final d = _b.deliveries[deliveryId];
    if (d == null) throw PareNotFoundException('Delivery not found.');
    if (code != d.pickupCode) {
      throw const PareAuthException('Pickup code salah');
    }
    d.status = DeliveryStatus.pickedUp;
    _b.orders[d.orderId]!.status = OrderStatus.pickedUp;
    return toJob(d);
  }

  Future<DeliveryJob> deliver(
    String deliveryId, {
    required String proofUrl,
  }) async {
    final d = _b.deliveries[deliveryId];
    if (d == null) throw PareNotFoundException('Delivery not found.');
    d.status = DeliveryStatus.delivered;
    _b.orders[d.orderId]!.status = OrderStatus.delivered;
    return toJob(d);
  }

  DeliveryJob toJob(DeliveryRow d) {
    final order = _b.orders[d.orderId]!;
    return DeliveryJob(
      deliveryId: d.id,
      orderId: d.orderId,
      orderNo: order.orderNo,
      restaurantName: 'Warung Budi',
      restaurantAddress: 'Jl. Restoran',
      customerName: order.customerName,
      deliveryAddress: order.deliveryAddress,
      status: d.status,
      fare: Money.fromRupiah(6000),
      distanceKm: 2.5,
      pickupCode: d.pickupCode,
    );
  }
}

// --- Admin repo (AP-PA) ---

class AdminTestRepo {
  AdminTestRepo(this._b);
  final SharedBackend _b;

  Future<List<OrderSummary>> fetchAll() async {
    return _b.orders.values
        .map(
          (r) => OrderSummary(
            id: r.id,
            orderNo: r.orderNo,
            restaurantName: 'Warung Budi',
            customerName: r.customerName,
            total: r.subtotal,
            status: r.status,
            placedAt: r.placedAt,
          ),
        )
        .toList();
  }

  Future<OrderSummary> forceCancel(String id, {required String reason}) async {
    final row = _b.orders[id];
    if (row == null) throw PareNotFoundException('Order $id not found.');
    row.status = OrderStatus.cancelled;
    row.cancelReason = reason;
    return OrderSummary(
      id: row.id,
      orderNo: row.orderNo,
      restaurantName: 'Warung Budi',
      customerName: row.customerName,
      total: row.subtotal,
      status: row.status,
      placedAt: row.placedAt,
    );
  }
}
