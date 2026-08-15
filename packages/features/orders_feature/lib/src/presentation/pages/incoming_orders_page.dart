/// Merchant incoming-orders page (FR-ORDER-002, PF-DOC-11 §3.5).
///
/// Lists orders for the merchant's restaurant with accept/decline actions
/// (BR-ACCEPT-001) and a "mark ready" action (BR-ORDER state machine). Write
/// actions are callback-injected (MO-R02d): this package never imports the
/// Edge Function client; the app composition root wires them.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../application/orders_providers.dart';
import '../../domain/order_summary.dart';
import '../order_status_view.dart';

/// Merchant incoming-orders board.
class IncomingOrdersPage extends ConsumerWidget {
  const IncomingOrdersPage({
    this.restaurantId,
    this.onAccept,
    this.onDecline,
    this.onMarkReady,
    this.onOpenDetail,
    super.key,
  });

  /// When `null`, fetches all owned restaurants (single-restaurant MVP).
  final String? restaurantId;

  final void Function(BuildContext context, OrderSummary order)? onAccept;
  final void Function(BuildContext context, OrderSummary order)? onDecline;
  final void Function(BuildContext context, OrderSummary order)? onMarkReady;
  final void Function(BuildContext context, String orderId)? onOpenDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(restaurantOrdersProvider(restaurantId));
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Masuk')),
      body: orders.when(
        data: (list) {
          if (list.isEmpty) {
            return const PfEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Belum ada pesanan',
              subtitle: 'Pesanan masuk akan muncul di sini secara langsung.',
            );
          }
          // Sort: placed first (needs action), then by placedAt descending.
          final sorted = [...list]
            ..sort((a, b) {
              final aNeeds = a.status == OrderStatus.placed ? 0 : 1;
              final bNeeds = b.status == OrderStatus.placed ? 0 : 1;
              if (aNeeds != bNeeds) return aNeeds.compareTo(bNeeds);
              return a.placedAt.compareTo(b.placedAt);
            });
          return ListView.separated(
            padding: const EdgeInsets.all(PfSpacing.md),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(height: PfSpacing.sm),
            itemBuilder: (context, index) {
              final o = sorted[index];
              return _MerchantOrderRow(
                order: o,
                onAccept: onAccept,
                onDecline: onDecline,
                onMarkReady: onMarkReady,
                onOpenDetail: onOpenDetail,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => PfErrorState(
          onRetry: () => ref.invalidate(restaurantOrdersProvider(restaurantId)),
          error: error is PareException ? error : null,
          title: 'Gagal memuat pesanan.',
        ),
      ),
    );
  }
}

class _MerchantOrderRow extends StatelessWidget {
  const _MerchantOrderRow({
    required this.order,
    this.onAccept,
    this.onDecline,
    this.onMarkReady,
    this.onOpenDetail,
  });

  final OrderSummary order;
  final void Function(BuildContext, OrderSummary)? onAccept;
  final void Function(BuildContext, OrderSummary)? onDecline;
  final void Function(BuildContext, OrderSummary)? onMarkReady;
  final void Function(BuildContext, String)? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(PfSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.orderNo} • ${order.customerName}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        formatIdr(order.total.amount),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                PfStatusBadge(
                  status: orderBadgeStatus(order.status),
                  label: orderStatusLabelShort(order.status),
                ),
              ],
            ),
            const SizedBox(height: PfSpacing.sm),
            _actionsFor(context, order),
          ],
        ),
      ),
    );
  }

  Widget _actionsFor(BuildContext context, OrderSummary o) {
    switch (o.status) {
      case OrderStatus.placed:
        return Row(
          children: [
            Expanded(
              child: PfButton(
                label: 'Terima',
                size: PfButtonSize.medium,
                onPressed: onAccept == null
                    ? null
                    : () => onAccept!(context, o),
              ),
            ),
            const SizedBox(width: PfSpacing.sm),
            Expanded(
              child: PfButton(
                label: 'Tolak',
                variant: PfButtonVariant.outline,
                size: PfButtonSize.medium,
                onPressed: onDecline == null
                    ? null
                    : () => onDecline!(context, o),
              ),
            ),
          ],
        );
      case OrderStatus.accepted:
      case OrderStatus.preparing:
        return PfButton(
          label: 'Tandai siap',
          icon: Icons.check_circle_outline,
          size: PfButtonSize.medium,
          onPressed: onMarkReady == null
              ? null
              : () => onMarkReady!(context, o),
        );
      default:
        return onOpenDetail == null
            ? const SizedBox.shrink()
            : Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => onOpenDetail!(context, o.id),
                  child: const Text('Lihat detail'),
                ),
              );
    }
  }
}
