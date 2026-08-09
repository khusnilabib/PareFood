/// Lightweight order summary for list screens (PF-DOC-11 §3.5).
library;

import 'package:pare_core/pare_core.dart';

import 'order_status.dart';

/// Immutable order summary. Equality is value-based.
class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.restaurantName,
    required this.total,
    required this.status,
    required this.placedAt,
  });

  final String id;
  final String restaurantName;
  final Money total;
  final OrderStatus status;
  final DateTime placedAt;

  @override
  bool operator ==(Object other) {
    return other is OrderSummary &&
        other.id == id &&
        other.restaurantName == restaurantName &&
        other.total == total &&
        other.status == status &&
        other.placedAt == placedAt;
  }

  @override
  int get hashCode => Object.hash(id, restaurantName, total, status, placedAt);
}
