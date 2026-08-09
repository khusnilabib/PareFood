/// Orders page covering all four states (FL-R07, PF-DOC-11 §3.5).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';

import '../../application/orders_providers.dart';
import '../widgets/order_card.dart';

/// Active + recent orders for the signed-in user.
class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(activeOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan')),
      body: orders.when(
        data: (list) => list.isEmpty
            ? const PfEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada pesanan',
                subtitle: 'Pesananmu akan muncul di sini.',
              )
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: PfSpacing.sm),
                padding: const EdgeInsets.all(PfSpacing.md),
                itemBuilder: (context, index) => OrderCard(order: list[index]),
              ),
        loading: () => const _OrdersLoading(),
        error: (error, stack) => PfErrorState(
          onRetry: () => ref.invalidate(activeOrdersProvider),
          error: error is PareException ? error : null,
          title: 'Gagal memuat pesanan.',
        ),
      ),
    );
  }
}

/// Skeleton placeholders while orders load (PF-DOC-16 §3.6).
class _OrdersLoading extends StatelessWidget {
  const _OrdersLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(PfSpacing.md),
      children: const [
        PfSkeleton(height: 96),
        SizedBox(height: PfSpacing.sm),
        PfSkeleton(height: 96),
        SizedBox(height: PfSpacing.sm),
        PfSkeleton(height: 96),
      ],
    );
  }
}
