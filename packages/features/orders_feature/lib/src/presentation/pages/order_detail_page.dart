/// Order detail with items + status timeline (FR-ORDER-009, PF-DOC-11 §3.5).
///
/// Covers the FL-R07 four states. An optional [onCancel] lets the customer
/// cancel (when the order is still cancellable per BR-CANCEL-001); the app
/// wires it to the `cancel-order` Edge Function.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../application/orders_providers.dart';
import '../../domain/order_detail.dart';
import '../../domain/order_summary.dart';
import '../order_status_view.dart';
import '../widgets/order_card.dart';

/// Full order detail for the customer (and reusable by other roles).
class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({required this.orderId, this.onCancel, super.key});

  final String orderId;

  /// Invoked when the customer cancels. When `null`, the cancel button is
  /// hidden. The caller decides whether cancellation is allowed per BR-CANCEL.
  final void Function(BuildContext context, OrderSummary summary)? onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: detail.when(
        data: (value) => _OrderDetailBody(
          detail: value,
          onCancel: onCancel == null
              ? null
              : () => onCancel!(context, value.summary),
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

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({required this.detail, this.onCancel});

  final OrderDetail detail;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = detail.summary;
    return ListView(
      padding: const EdgeInsets.all(PfSpacing.md),
      children: [
        OrderCard(order: s, subtitle: 'No. pesanan ${s.orderNo}'),
        const SizedBox(height: PfSpacing.md),
        if (detail.items.isNotEmpty) ...[
          Text('Item', style: theme.textTheme.titleMedium),
          const SizedBox(height: PfSpacing.sm),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final item in detail.items) ...[
                  ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.quantity} × ${formatIdr(item.unitPrice.amount)}',
                    ),
                    trailing: Text(
                      formatIdr(item.lineTotal.amount),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (item != detail.items.last) const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: PfSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PfSpacing.sm),
            child: Row(
              children: [
                Text('Total', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  formatIdr(s.total.amount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: PfSpacing.md),
        ],
        Text('Status pesanan', style: theme.textTheme.titleMedium),
        const SizedBox(height: PfSpacing.sm),
        _StatusTimeline(timeline: detail.timeline),
        if (onCancel != null && s.status.isActive) ...[
          const SizedBox(height: PfSpacing.lg),
          PfButton(
            label: 'Batalkan pesanan',
            variant: PfButtonVariant.outline,
            icon: Icons.cancel_outlined,
            onPressed: onCancel,
          ),
        ],
      ],
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.timeline});

  final List<OrderStatusEntry> timeline;

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
              _TimelineRow(entry: ordered[i], isLast: i == ordered.length - 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.isLast});

  final OrderStatusEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
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
                  fontWeight: FontWeight.w600,
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
