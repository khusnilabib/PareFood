/// Order tracking page: live status timeline + driver info (FR-ORDER-007).
///
/// Subscribes to [orderStatusStreamProvider] for realtime status updates and
/// shows the full status timeline from [orderDetailProvider]. The timeline
/// auto-updates as the order progresses through the state machine.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../application/order_tracking_providers.dart';
import '../../application/orders_providers.dart';
import '../../domain/order_detail.dart';
import '../../domain/order_summary.dart';
import '../order_status_view.dart';

/// Live order tracking for the customer (and reusable by other roles).
class OrderTrackingPage extends ConsumerWidget {
  const OrderTrackingPage({required this.orderId, this.onCancel, super.key});

  final String orderId;

  /// Cancel callback (shown while the order is still cancellable).
  final void Function(BuildContext context, OrderSummary summary)? onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(orderDetailProvider(orderId));
    final liveStatus = ref.watch(orderStatusStreamProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Lacak Pesanan')),
      body: detail.when(
        data: (value) => _TrackingBody(
          detail: value,
          liveStatus: liveStatus.value,
          onCancel: onCancel,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => PfErrorState(
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
          error: error is PareException ? error : null,
          title: 'Gagal memuat pesanan.',
        ),
      ),
    );
  }
}

class _TrackingBody extends StatelessWidget {
  const _TrackingBody({
    required this.detail,
    required this.liveStatus,
    this.onCancel,
  });

  final OrderDetail detail;
  final OrderStatus? liveStatus;
  final void Function(BuildContext, OrderSummary)? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = detail.summary;
    // Use the realtime status when available, else fall back to the loaded one.
    final currentStatus = liveStatus ?? s.status;

    return ListView(
      padding: const EdgeInsets.all(PfSpacing.md),
      children: [
        // Status header
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(PfSpacing.md),
            child: Column(
              children: [
                Icon(
                  _statusIcon(currentStatus),
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: PfSpacing.sm),
                Text(
                  orderStatusLabel(currentStatus),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (s.estimatedMinutes != null) ...[
                  const SizedBox(height: PfSpacing.xxs),
                  Text(
                    'Estimasi ${s.estimatedMinutes} menit',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: PfSpacing.xs),
                Text(
                  'No. pesanan ${s.orderNo}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: PfSpacing.md),

        // Items summary
        Text('Item', style: theme.textTheme.titleMedium),
        const SizedBox(height: PfSpacing.sm),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (final item in detail.items) ...[
                ListTile(
                  dense: true,
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.quantity} × ${formatIdr(item.unitPrice.amount)}',
                  ),
                  trailing: Text(formatIdr(item.lineTotal.amount)),
                ),
                if (item != detail.items.last) const Divider(height: 1),
              ],
            ],
          ),
        ),
        const SizedBox(height: PfSpacing.md),

        // Status timeline
        Text('Riwayat Status', style: theme.textTheme.titleMedium),
        const SizedBox(height: PfSpacing.sm),
        _LiveTimeline(timeline: detail.timeline, currentStatus: currentStatus),
        const SizedBox(height: PfSpacing.lg),

        // Cancel button (while cancellable)
        if (onCancel != null && currentStatus.isActive)
          PfButton(
            label: 'Batalkan pesanan',
            variant: PfButtonVariant.outline,
            icon: Icons.cancel_outlined,
            onPressed: () => onCancel!(context, s),
          ),
      ],
    );
  }

  IconData _statusIcon(OrderStatus status) => switch (status) {
    OrderStatus.placed => const IconData(0xe88f), // info
    OrderStatus.accepted => const IconData(0xe86c), // check_circle
    OrderStatus.preparing => const IconData(0xe6fc), // restaurant
    OrderStatus.ready => const IconData(0xe88f), // ready
    OrderStatus.pickedUp => const IconData(0xe59c), // local_shipping
    OrderStatus.delivered => const IconData(0xe86c), // check_circle
    OrderStatus.cancelled => const IconData(0xe888), // cancel
    OrderStatus.refunded => const IconData(0xe042), // undo
  };
}

/// Timeline that highlights the current step and fades future steps.
class _LiveTimeline extends StatelessWidget {
  const _LiveTimeline({required this.timeline, required this.currentStatus});

  final List<OrderStatusEntry> timeline;
  final OrderStatus currentStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (timeline.isEmpty) {
      return Text(
        'Belum ada riwayat status.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    final ordered = List<OrderStatusEntry>.from(timeline)
      ..sort((a, b) => a.at.compareTo(b.at));
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(PfSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < ordered.length; i++) ...[
              _TimelineRow(
                entry: ordered[i],
                isCurrent: ordered[i].toStatus == currentStatus,
                isLast: i == ordered.length - 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.entry,
    required this.isCurrent,
    required this.isLast,
  });

  final OrderStatusEntry entry;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isCurrent
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: theme.colorScheme.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: PfSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orderStatusLabel(entry.toStatus),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                formatDateIndonesian(entry.at),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (entry.reason != null)
                Text(
                  entry.reason!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (!isLast) const SizedBox(height: PfSpacing.sm),
            ],
          ),
        ),
      ],
    );
  }
}
