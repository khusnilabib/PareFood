/// Order detail with items + status timeline (PF-DOC-11 §3.5, FR-ORDER-009).
library;

import 'package:pare_core/pare_core.dart';

import 'order_status.dart';
import 'order_summary.dart';

/// A snapshot line item stored on the order (PF-DOC-13 `order_items`).
class OrderItemSnapshot {
  const OrderItemSnapshot({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.selectedOptions,
  });

  final String id;
  final String? menuItemId;
  final String name;
  final int quantity;
  final Money unitPrice;
  final Money lineTotal;

  /// JSON snapshot of option groups chosen at placement (PF-DOC-13).
  final Map<String, dynamic>? selectedOptions;
}

/// One entry in the status history (append-only, PF-DOC-13
/// `order_status_history`).
class OrderStatusEntry {
  const OrderStatusEntry({
    required this.fromStatus,
    required this.toStatus,
    required this.at,
    this.reason,
  });

  final OrderStatus? fromStatus;
  final OrderStatus toStatus;
  final DateTime at;
  final String? reason;
}

/// Full order detail: summary + items + timeline + delivery info.
class OrderDetail {
  const OrderDetail({
    required this.summary,
    required this.items,
    required this.timeline,
    this.deliveryAddress,
    this.paymentMethod,
    this.paymentStatus,
    this.pickupCode,
    this.driverId,
  });

  final OrderSummary summary;
  final List<OrderItemSnapshot> items;
  final List<OrderStatusEntry> timeline;
  final String? deliveryAddress;
  final String? paymentMethod;
  final String? paymentStatus;

  /// Pickup code shown to driver (FR-ORDER-005); null until assigned.
  final String? pickupCode;
  final String? driverId;

  Money get subtotal {
    var total = Money.fromRupiah(0);
    for (final item in items) {
      total += item.lineTotal;
    }
    return total;
  }
}

/// A delivery job offered to / held by a driver (FR-ORDER-004, PF-DOC-13
/// `deliveries`). Distinct from [OrderDetail] because a driver cares about
/// fare, distance and pickup code, not the full item list.
class DeliveryJob {
  const DeliveryJob({
    required this.deliveryId,
    required this.orderId,
    required this.orderNo,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.customerName,
    required this.deliveryAddress,
    required this.status,
    required this.fare,
    required this.distanceKm,
    this.pickupCode,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  final String deliveryId;
  final String orderId;
  final String orderNo;
  final String restaurantName;
  final String restaurantAddress;
  final String customerName;
  final String deliveryAddress;
  final DeliveryStatus status;
  final Money fare;
  final double distanceKm;
  final String? pickupCode;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
}

/// `deliveries.status` sub-state machine (PF-DOC-18 §3.3, migration 0007).
enum DeliveryStatus {
  assigned,
  arrivedPickup,
  pickedUp,
  delivered,
  failed;

  static DeliveryStatus fromString(String? value) {
    return switch (value) {
      'assigned' => DeliveryStatus.assigned,
      'arrived_pickup' => DeliveryStatus.arrivedPickup,
      'picked_up' => DeliveryStatus.pickedUp,
      'delivered' => DeliveryStatus.delivered,
      'failed' => DeliveryStatus.failed,
      _ => DeliveryStatus.assigned,
    };
  }

  String toWire() => switch (this) {
    DeliveryStatus.assigned => 'assigned',
    DeliveryStatus.arrivedPickup => 'arrived_pickup',
    DeliveryStatus.pickedUp => 'picked_up',
    DeliveryStatus.delivered => 'delivered',
    DeliveryStatus.failed => 'failed',
  };
}
