/// Pesanan tab: merchant incoming orders, scoped to the merchant's first
/// restaurant (FR-ORDER-002). Accept/decline/mark-ready actions are wired to
/// Edge Functions via [SupabaseClient.functions.invoke]. A realtime
/// subscription auto-refreshes the list when a new order arrives.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchant_feature/merchant_feature.dart';
import 'package:orders_feature/orders_feature.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Merchant incoming-orders tab with Edge Function wiring.
class OrdersTab extends ConsumerStatefulWidget {
  const OrdersTab({super.key});

  @override
  ConsumerState<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends ConsumerState<OrdersTab> {
  @override
  Widget build(BuildContext context) {
    final restaurants = ref.watch(myRestaurantsProvider);
    return restaurants.when(
      data: (list) {
        if (list.isEmpty) {
          return const Scaffold(
            body: PfEmptyState(
              icon: Icons.store_outlined,
              title: 'Belum ada restoran',
              subtitle:
                  'Daftarkan restoran Anda di tab Restoran untuk menerima pesanan.',
            ),
          );
        }
        return _RealtimeIncomingOrders(restaurantId: list.first.id);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: PfErrorState(
          onRetry: () => ref.invalidate(myRestaurantsProvider),
          error: error is PareException ? error : null,
          title: 'Gagal memuat restoran.',
        ),
      ),
    );
  }
}

/// Wraps [IncomingOrdersPage] with a realtime subscription that invalidates
/// the orders provider whenever a new order is inserted or an existing one
/// changes status (FR-ORDER-002 realtime).
class _RealtimeIncomingOrders extends ConsumerStatefulWidget {
  const _RealtimeIncomingOrders({required this.restaurantId});

  final String restaurantId;

  @override
  ConsumerState<_RealtimeIncomingOrders> createState() =>
      _RealtimeIncomingOrdersState();
}

class _RealtimeIncomingOrdersState
    extends ConsumerState<_RealtimeIncomingOrders> {
  late final RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();
    // Guard: only subscribe to realtime if Supabase is bootstrapped. In tests
    // (no Supabase instance), the subscription is skipped — the page still
    // works via the FutureProvider (which returns empty with a fake repo).
    try {
      _channel = Supabase.instance.client
          .channel('merchant-orders-${widget.restaurantId}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'restaurant_id',
              value: widget.restaurantId,
            ),
            callback: (_) {
              ref.invalidate(restaurantOrdersProvider(widget.restaurantId));
            },
          )
          .subscribe();
    } on Object {
      // Supabase not initialised (test env) — skip realtime; polling refetch
      // on tab focus is the fallback.
    }
  }

  @override
  void dispose() {
    try {
      Supabase.instance.client.removeChannel(_channel);
    } on Object {
      // Supabase not initialised — nothing to remove.
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IncomingOrdersPage(
      restaurantId: widget.restaurantId,
      onAccept: (context, order) => _invokeOrderAction(
        context,
        order,
        'accept-order',
        decision: 'accept',
      ),
      onDecline: (context, order) => _invokeOrderAction(
        context,
        order,
        'accept-order',
        decision: 'decline',
      ),
      onMarkReady: (context, order) =>
          _invokeOrderAction(context, order, 'ready-order'),
      onOpenDetail: (context, orderId) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => OrderDetailPage(orderId: orderId),
          ),
        );
      },
    );
  }

  /// Invokes an order-lifecycle Edge Function and shows a SnackBar with the
  /// result. All mutations go through Edge Functions (API-R01).
  Future<void> _invokeOrderAction(
    BuildContext context,
    OrderSummary order,
    String functionName, {
    String? decision,
  }) async {
    try {
      await Supabase.instance.client.functions.invoke(
        functionName,
        headers: {'x-idempotency-key': '$functionName-${order.id}'},
        body: {
          'order_id': order.id,
          if (decision != null) 'decision': decision,
        },
      );
      ref.invalidate(restaurantOrdersProvider(widget.restaurantId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              decision == 'decline'
                  ? 'Pesanan ditolak. Pelanggan akan direfund.'
                  : decision == 'accept'
                  ? 'Pesanan diterima. Mulai menyiapkan.'
                  : 'Pesanan ditandai siap. Driver akan dikirim.',
            ),
          ),
        );
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }
}
