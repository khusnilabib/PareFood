/// Realtime order status tracking (FR-ORDER-007, PF-DOC-12 §3.5 Realtime).
///
/// Subscribes to Supabase Realtime for `orders` row changes on [orderId],
/// emitting the new status whenever the order transitions. Used by
/// [OrderTrackingPage] to show live updates without polling.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/order_status.dart';

/// Emits the latest [OrderStatus] for [orderId] via Supabase Realtime.
/// Completes (closes) when the order reaches a terminal state.
final orderStatusStreamProvider = StreamProvider.family<OrderStatus, String>((
  ref,
  orderId,
) {
  final controller = StreamController<OrderStatus>();
  final client = Supabase.instance.client;

  // Emit the current status immediately (best-effort single read).
  client.from('orders').select('status').eq('id', orderId).maybeSingle().then((
    row,
  ) {
    if (row != null) {
      controller.add(OrderStatus.fromString(row['status'] as String?));
    }
  });

  // Subscribe to realtime changes on the orders table for this row.
  final subscription = client
      .channel('order-$orderId')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'orders',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: orderId,
        ),
        callback: (payload) {
          final newRecord = payload.newRecord;
          final status = OrderStatus.fromString(newRecord['status'] as String?);
          controller.add(status);
          if (status.isTerminal) {
            controller.close();
          }
        },
      )
      .subscribe();

  ref.onDispose(() {
    client.removeChannel(subscription);
    controller.close();
  });

  return controller.stream;
});
