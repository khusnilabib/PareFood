/// Default [OrdersRepository] backed by Supabase PostgREST (PF-DOC-11 §3.1,
/// PF-DOC-14 §3.2). Role-scoped by RLS: each query returns only the rows the
/// caller's JWT permits (customer sees own, merchant sees own restaurants,
/// driver sees assigned, admin sees all).
library;

import 'package:pare_core/pare_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/order_detail.dart';
import '../domain/order_status.dart';
import '../domain/order_summary.dart';
import 'orders_repository.dart';

/// Adapts the Supabase client to [OrdersRepository]. The client is bootstrapped
/// by `pare_data` (`SupabaseBootstrap.initialize`); reads go through PostgREST
/// (RLS), writes go through Edge Functions (API-R01) — this repository is
/// read-only.
class SupabaseOrdersRepository implements OrdersRepository {
  SupabaseOrdersRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<OrderSummary>> fetchForCustomer() async {
    final rows = await _client
        .from('orders')
        .select('id, order_no, status, total, placed_at, restaurants(name)')
        .order('placed_at', ascending: false)
        .limit(50);
    return rows.map(_toCustomerSummary).toList();
  }

  @override
  Future<List<OrderSummary>> fetchForRestaurant({
    String? restaurantId,
    Set<OrderStatus>? statuses,
  }) async {
    var query = _client
        .from('orders')
        .select('id, order_no, status, total, placed_at, profiles(name)');
    if (restaurantId != null) {
      query = query.eq('restaurant_id', restaurantId);
    }
    if (statuses != null && statuses.isNotEmpty) {
      query = query.inFilter(
        'status',
        statuses.map((s) => s.toWire()).toList(),
      );
    }
    final rows = await query.order('placed_at', ascending: false).limit(100);
    return rows.map(_toMerchantSummary).toList();
  }

  @override
  Future<List<DeliveryJob>> fetchForDriver() async {
    final rows = await _client
        .from('deliveries')
        .select(
          'id, order_id, status, pickup_code, assigned_at, picked_up_at, '
          'delivered_at, orders(order_no, restaurant_id, delivery_address, '
          'restaurants(name, slug))',
        )
        .order('assigned_at', ascending: false)
        .limit(50);
    return rows.map(_toJob).toList();
  }

  @override
  Future<List<OrderSummary>> fetchAll({
    Set<OrderStatus>? statuses,
    String? search,
  }) async {
    var query = _client
        .from('orders')
        .select(
          'id, order_no, status, total, placed_at, '
          'restaurants(name), profiles(name)',
        );
    if (statuses != null && statuses.isNotEmpty) {
      query = query.inFilter(
        'status',
        statuses.map((s) => s.toWire()).toList(),
      );
    }
    if (search != null && search.isNotEmpty) {
      query = query.ilike('order_no', '%$search%');
    }
    final rows = await query.order('placed_at', ascending: false).limit(200);
    return rows.map(_toAdminSummary).toList();
  }

  @override
  Future<OrderSummary> fetchById(String id) async {
    final row = await _client
        .from('orders')
        .select('id, order_no, status, total, placed_at, restaurants(name)')
        .eq('id', id)
        .maybeSingle();
    if (row == null) throw PareNotFoundException('Order $id not found.');
    return _toCustomerSummary(row);
  }

  @override
  Future<OrderDetail> fetchDetail(String id) async {
    final orderRow = await _client
        .from('orders')
        .select(
          'id, order_no, status, total, subtotal, placed_at, delivery_address, '
          'payment_method, payment_status, restaurants(name), profiles(name)',
        )
        .eq('id', id)
        .maybeSingle();
    if (orderRow == null) throw PareNotFoundException('Order $id not found.');

    final itemsRows = await _client
        .from('order_items')
        .select('id, menu_item_id, item_name, quantity, unit_price, line_total')
        .eq('order_id', id);

    final historyRows = await _client
        .from('order_status_history')
        .select('from_status, to_status, created_at, reason')
        .eq('order_id', id)
        .order('created_at', ascending: true);

    return OrderDetail(
      summary: _toAdminSummary(orderRow),
      items: itemsRows.map(_toItem).toList(),
      timeline: historyRows.map(_toHistoryEntry).toList(),
      deliveryAddress: orderRow['delivery_address'] as String?,
      paymentMethod: orderRow['payment_method'] as String?,
      paymentStatus: orderRow['payment_status'] as String?,
    );
  }

  // --- Mappers ---

  OrderSummary _toCustomerSummary(Map<String, dynamic> row) {
    final rest = (row['restaurants'] as Map<String, dynamic>?) ?? const {};
    return OrderSummary(
      id: row['id'] as String,
      orderNo: (row['order_no'] as String?) ?? '',
      restaurantName: (rest['name'] as String?) ?? 'Restoran',
      customerName: '',
      total: Money.fromRupiah(row['total'] as int),
      status: OrderStatus.fromString(row['status'] as String?),
      placedAt: DateTime.parse(row['placed_at'] as String),
    );
  }

  OrderSummary _toMerchantSummary(Map<String, dynamic> row) {
    final cust = (row['profiles'] as Map<String, dynamic>?) ?? const {};
    return OrderSummary(
      id: row['id'] as String,
      orderNo: (row['order_no'] as String?) ?? '',
      restaurantName: '',
      customerName: (cust['name'] as String?) ?? 'Pelanggan',
      total: Money.fromRupiah(row['total'] as int),
      status: OrderStatus.fromString(row['status'] as String?),
      placedAt: DateTime.parse(row['placed_at'] as String),
    );
  }

  OrderSummary _toAdminSummary(Map<String, dynamic> row) {
    final rest = (row['restaurants'] as Map<String, dynamic>?) ?? const {};
    final cust = (row['profiles'] as Map<String, dynamic>?) ?? const {};
    return OrderSummary(
      id: row['id'] as String,
      orderNo: (row['order_no'] as String?) ?? '',
      restaurantName: (rest['name'] as String?) ?? 'Restoran',
      customerName: (cust['name'] as String?) ?? 'Pelanggan',
      total: Money.fromRupiah(row['total'] as int),
      status: OrderStatus.fromString(row['status'] as String?),
      placedAt: DateTime.parse(row['placed_at'] as String),
    );
  }

  DeliveryJob _toJob(Map<String, dynamic> row) {
    final order = (row['orders'] as Map<String, dynamic>?) ?? const {};
    final rest = (order['restaurants'] as Map<String, dynamic>?) ?? const {};
    return DeliveryJob(
      deliveryId: row['id'] as String,
      orderId: (order['id'] as String?) ?? '',
      orderNo: (order['order_no'] as String?) ?? '',
      restaurantName: (rest['name'] as String?) ?? 'Restoran',
      restaurantAddress: (rest['slug'] as String?) ?? '',
      customerName: '',
      deliveryAddress: (order['delivery_address'] as String?) ?? '',
      status: DeliveryStatus.fromString(row['status'] as String?),
      fare: Money.fromRupiah(0),
      distanceKm: 0,
      pickupCode: row['pickup_code'] as String?,
      assignedAt: _parseDate(row['assigned_at'] as String?),
      pickedUpAt: _parseDate(row['picked_up_at'] as String?),
      deliveredAt: _parseDate(row['delivered_at'] as String?),
    );
  }

  OrderItemSnapshot _toItem(Map<String, dynamic> row) {
    return OrderItemSnapshot(
      id: row['id'] as String,
      menuItemId: row['menu_item_id'] as String?,
      name: (row['item_name'] as String?) ?? '',
      quantity: (row['quantity'] as int?) ?? 1,
      unitPrice: Money.fromRupiah((row['unit_price'] as int?) ?? 0),
      lineTotal: Money.fromRupiah((row['line_total'] as int?) ?? 0),
    );
  }

  OrderStatusEntry _toHistoryEntry(Map<String, dynamic> row) {
    return OrderStatusEntry(
      fromStatus: OrderStatus.fromString(row['from_status'] as String?),
      toStatus: OrderStatus.fromString(row['to_status'] as String?),
      at: DateTime.parse(row['created_at'] as String),
      reason: row['reason'] as String?,
    );
  }

  DateTime? _parseDate(String? iso) =>
      iso == null ? null : DateTime.tryParse(iso);
}
