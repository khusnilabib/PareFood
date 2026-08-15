/// Single order row for list screens (PF-DOC-16 §3.2).
///
/// Used by customer history, merchant incoming and admin board. The optional
/// [onTap] opens detail; the optional trailing action slot is filled by the
/// caller (e.g. an "accept" button for the merchant).
library;

import 'package:flutter/material.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../domain/order_summary.dart';
import '../order_status_view.dart';

/// Single order row.
class OrderCard extends StatelessWidget {
  const OrderCard({
    required this.order,
    this.onTap,
    this.trailing,
    this.subtitle,
    super.key,
  });

  final OrderSummary order;

  /// Opens the order detail (or any consumer-defined action).
  final VoidCallback? onTap;

  /// Optional trailing widget (e.g. accept/decline buttons for merchant).
  final Widget? trailing;

  /// Optional second-line content; defaults to total + placed-at.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(PfSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${order.orderNo} · ${order.restaurantName}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PfStatusBadge(
                    status: orderBadgeStatus(order.status),
                    label: orderStatusLabelShort(order.status),
                  ),
                ],
              ),
              const SizedBox(height: PfSpacing.xs),
              Text(
                subtitle ??
                    '${formatIdr(order.total.amount)} • ${formatDateIndonesian(order.placedAt)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(height: PfSpacing.sm),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
