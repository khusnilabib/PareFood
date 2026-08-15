/// Lightweight order summary for list screens (PF-DOC-11 §3.5).
library;

import 'package:pare_core/pare_core.dart';

import 'order_status.dart';

/// Immutable order summary used in lists (customer history, merchant incoming,
/// driver job feed, admin board). Equality is value-based.
class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.orderNo,
    required this.restaurantName,
    required this.customerName,
    required this.total,
    required this.status,
    required this.placedAt,
    this.driverName,
    this.estimatedMinutes,
  });

  final String id;
  final String orderNo;
  final String restaurantName;
  final String customerName;
  final Money total;
  final OrderStatus status;
  final DateTime placedAt;

  /// Driver name when assigned (driver/admin views).
  final String? driverName;

  /// ETA in minutes from placement (BR-ETA-001).
  final int? estimatedMinutes;

  @override
  bool operator ==(Object other) {
    return other is OrderSummary &&
        other.id == id &&
        other.orderNo == orderNo &&
        other.restaurantName == restaurantName &&
        other.customerName == customerName &&
        other.total == total &&
        other.status == status &&
        other.placedAt == placedAt &&
        other.driverName == driverName &&
        other.estimatedMinutes == estimatedMinutes;
  }

  @override
  int get hashCode => Object.hash(
    id,
    orderNo,
    restaurantName,
    customerName,
    total,
    status,
    placedAt,
    driverName,
    estimatedMinutes,
  );
}
