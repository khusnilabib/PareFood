/// Order lifecycle status (PF-DOC-18 §3.3 state machine, mapped to UI).
///
/// Mirrors the `orders.status` CHECK constraint (migration 0007). Transitions
/// are enforced server-side by Edge Functions (FL-R03); the client only
/// reflects them.
library;

/// Statuses surfaced to the UI. The values match the DB column exactly so
/// repository mapping is a direct lookup.
enum OrderStatus {
  placed,
  accepted,
  preparing,
  ready,
  pickedUp,
  delivered,
  cancelled,
  refunded;

  /// Parses the DB string; falls back to [placed] for unknown values so the
  /// UI never crashes on a forward-compatible new status (PF-DOC-23).
  static OrderStatus fromString(String? value) {
    return switch (value) {
      'placed' => OrderStatus.placed,
      'accepted' => OrderStatus.accepted,
      'preparing' => OrderStatus.preparing,
      'ready' => OrderStatus.ready,
      'picked_up' => OrderStatus.pickedUp,
      'delivered' => OrderStatus.delivered,
      'cancelled' => OrderStatus.cancelled,
      'refunded' => OrderStatus.refunded,
      _ => OrderStatus.placed,
    };
  }

  /// The DB column value (snake_case).
  String toWire() => switch (this) {
    OrderStatus.placed => 'placed',
    OrderStatus.accepted => 'accepted',
    OrderStatus.preparing => 'preparing',
    OrderStatus.ready => 'ready',
    OrderStatus.pickedUp => 'picked_up',
    OrderStatus.delivered => 'delivered',
    OrderStatus.cancelled => 'cancelled',
    OrderStatus.refunded => 'refunded',
  };

  /// Whether the order is still "live" (customer expects progress).
  bool get isActive =>
      this == OrderStatus.placed ||
      this == OrderStatus.accepted ||
      this == OrderStatus.preparing ||
      this == OrderStatus.ready ||
      this == OrderStatus.pickedUp;

  /// Whether the order reached a terminal state.
  bool get isTerminal =>
      this == OrderStatus.delivered ||
      this == OrderStatus.cancelled ||
      this == OrderStatus.refunded;
}
