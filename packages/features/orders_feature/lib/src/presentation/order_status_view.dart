/// Shared order-status → UI mapping helpers (PF-DOC-16 §3.2).
library;

import 'package:pare_design/pare_design.dart';

import '../domain/order_status.dart';

// Re-export so presentation pages importing this helper also see OrderStatus
// without a second import line.
export '../domain/order_status.dart';

/// Maps [OrderStatus] to a [PfStatus] badge variant.
PfStatus orderBadgeStatus(OrderStatus status) {
  return switch (status) {
    OrderStatus.placed || OrderStatus.accepted => PfStatus.pending,
    OrderStatus.preparing ||
    OrderStatus.ready ||
    OrderStatus.pickedUp => PfStatus.active,
    OrderStatus.delivered => PfStatus.active,
    OrderStatus.cancelled || OrderStatus.refunded => PfStatus.cancelled,
  };
}

/// Human-readable Indonesian label for [OrderStatus].
String orderStatusLabel(OrderStatus status) {
  return switch (status) {
    OrderStatus.placed => 'Menunggu konfirmasi',
    OrderStatus.accepted => 'Dikonfirmasi',
    OrderStatus.preparing => 'Disiapkan',
    OrderStatus.ready => 'Siap diambil',
    OrderStatus.pickedUp => 'Dalam pengantaran',
    OrderStatus.delivered => 'Selesai',
    OrderStatus.cancelled => 'Dibatalkan',
    OrderStatus.refunded => 'Dana dikembalikan',
  };
}

/// Short label for compact cards (merchant/driver boards).
String orderStatusLabelShort(OrderStatus status) {
  return switch (status) {
    OrderStatus.placed => 'Menunggu',
    OrderStatus.accepted => 'Diterima',
    OrderStatus.preparing => 'Disiapkan',
    OrderStatus.ready => 'Siap',
    OrderStatus.pickedUp => 'Diantar',
    OrderStatus.delivered => 'Selesai',
    OrderStatus.cancelled => 'Batal',
    OrderStatus.refunded => 'Refund',
  };
}
