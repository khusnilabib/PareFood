/// Order list card with status badge (PF-DOC-16 §3.2).
library;

import 'package:flutter/material.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../domain/order_status.dart';
import '../../domain/order_summary.dart';

/// Single order row for [OrdersPage].
class OrderCard extends StatelessWidget {
  const OrderCard({required this.order, super.key});

  final OrderSummary order;

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
                  child: Text(
                    order.restaurantName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                PfStatusBadge(
                  status: badgeStatus(order.status),
                  label: statusLabel(order.status),
                ),
              ],
            ),
            const SizedBox(height: PfSpacing.sm),
            Text(
              '${formatIdr(order.total.amount)} • ${formatDateIndonesian(order.placedAt)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static PfStatus badgeStatus(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending || OrderStatus.confirmed => PfStatus.pending,
      OrderStatus.preparing ||
      OrderStatus.delivering ||
      OrderStatus.delivered => PfStatus.active,
      OrderStatus.cancelled => PfStatus.cancelled,
    };
  }

  static String statusLabel(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending => 'Menunggu',
      OrderStatus.confirmed => 'Dikonfirmasi',
      OrderStatus.preparing => 'Disiapkan',
      OrderStatus.delivering => 'Diantar',
      OrderStatus.delivered => 'Selesai',
      OrderStatus.cancelled => 'Dibatalkan',
    };
  }
}
