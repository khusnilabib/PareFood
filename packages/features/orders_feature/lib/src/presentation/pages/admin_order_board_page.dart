/// Admin order board (FR-ORDER-010/011, PF-DOC-11 §3.5).
///
/// Live list of all orders with filters and a force-cancel action (BR-CANCEL-
/// 003, audit-logged server-side). Callback-injected writes (MO-R02d).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../application/orders_providers.dart';
import '../../domain/order_summary.dart';
import '../order_status_view.dart';

/// Admin order board with status filter chips.
class AdminOrderBoardPage extends ConsumerStatefulWidget {
  const AdminOrderBoardPage({this.onForceCancel, this.onOpenDetail, super.key});

  final void Function(BuildContext context, OrderSummary order)? onForceCancel;
  final void Function(BuildContext context, String orderId)? onOpenDetail;

  @override
  ConsumerState<AdminOrderBoardPage> createState() =>
      _AdminOrderBoardPageState();
}

class _AdminOrderBoardPageState extends ConsumerState<AdminOrderBoardPage> {
  OrderStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(allOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Papan Pesanan')),
      body: Column(
        children: [
          _FilterBar(
            selected: _filter,
            onChanged: (s) => setState(() => _filter = s),
          ),
          Expanded(
            child: orders.when(
              data: (list) {
                final filtered = _filter == null
                    ? list
                    : list.where((o) => o.status == _filter).toList();
                if (filtered.isEmpty) {
                  return const PfEmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Tidak ada pesanan',
                    subtitle: 'Tidak ada pesanan untuk filter ini.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(PfSpacing.md),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: PfSpacing.sm),
                  itemBuilder: (context, index) {
                    final o = filtered[index];
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
                                    '${o.orderNo} • ${o.restaurantName}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                PfStatusBadge(
                                  status: orderBadgeStatus(o.status),
                                  label: orderStatusLabelShort(o.status),
                                ),
                              ],
                            ),
                            const SizedBox(height: PfSpacing.xs),
                            Text(
                              '${o.customerName} • ${formatIdr(o.total.amount)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: PfSpacing.sm),
                            Wrap(
                              spacing: PfSpacing.sm,
                              children: [
                                if (widget.onOpenDetail != null)
                                  TextButton(
                                    onPressed: () =>
                                        widget.onOpenDetail!(context, o.id),
                                    child: const Text('Detail'),
                                  ),
                                if (widget.onForceCancel != null &&
                                    o.status.isActive)
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    onPressed: () =>
                                        widget.onForceCancel!(context, o),
                                    child: const Text('Batalkan paksa'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => PfErrorState(
                onRetry: () => ref.invalidate(allOrdersProvider),
                error: error is PareException ? error : null,
                title: 'Gagal memuat pesanan.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onChanged;

  static const _filters = <OrderStatus>[
    OrderStatus.placed,
    OrderStatus.preparing,
    OrderStatus.ready,
    OrderStatus.pickedUp,
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: PfSpacing.md),
        children: [
          _chip(context, label: 'Semua', value: null),
          for (final s in _filters)
            _chip(context, label: orderStatusLabelShort(s), value: s),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required OrderStatus? value,
  }) {
    final active = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: PfSpacing.xs),
      child: FilterChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => onChanged(active ? null : value),
      ),
    );
  }
}
