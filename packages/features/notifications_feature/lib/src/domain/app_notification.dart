/// A single push/in-app notification for the current user.
///
/// S6 expansion: adds [type] for routing (order status vs system), [data]
/// for deep-link payloads, and [orderId] for order-related notifications.
library;

/// Notification category for icon + routing (FR-NOTIF-001..004).
enum NotificationType {
  orderAccepted,
  orderPreparing,
  orderReady,
  driverAssigned,
  orderDelivered,
  orderCancelled,
  promo,
  system;

  static NotificationType fromString(String? value) {
    return switch (value) {
      'order_accepted' => NotificationType.orderAccepted,
      'order_preparing' => NotificationType.orderPreparing,
      'order_ready' => NotificationType.orderReady,
      'driver_assigned' => NotificationType.driverAssigned,
      'order_delivered' => NotificationType.orderDelivered,
      'order_cancelled' => NotificationType.orderCancelled,
      'promo' => NotificationType.promo,
      _ => NotificationType.system,
    };
  }

  String toWire() => switch (this) {
    NotificationType.orderAccepted => 'order_accepted',
    NotificationType.orderPreparing => 'order_preparing',
    NotificationType.orderReady => 'order_ready',
    NotificationType.driverAssigned => 'driver_assigned',
    NotificationType.orderDelivered => 'order_delivered',
    NotificationType.orderCancelled => 'order_cancelled',
    NotificationType.promo => 'promo',
    NotificationType.system => 'system',
  };
}

/// Immutable notification item. Equality is value-based.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.type,
    this.isRead = false,
    this.orderId,
    this.data,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final NotificationType type;
  final bool isRead;

  /// Order id when the notification is order-related (for deep-link routing).
  final String? orderId;

  /// Extra payload (promo code, driver name, etc.).
  final Map<String, dynamic>? data;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
      type: type,
      isRead: isRead ?? this.isRead,
      orderId: orderId,
      data: data,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppNotification &&
        other.id == id &&
        other.title == title &&
        other.body == body &&
        other.createdAt == createdAt &&
        other.type == type &&
        other.isRead == isRead &&
        other.orderId == orderId;
  }

  @override
  int get hashCode =>
      Object.hash(id, title, body, createdAt, type, isRead, orderId);
}
