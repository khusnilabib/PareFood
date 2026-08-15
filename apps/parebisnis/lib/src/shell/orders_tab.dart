/// Pesanan tab: merchant incoming orders, scoped to the merchant's first
/// restaurant (FR-ORDER-002). Accept/decline/mark-ready actions are wired to
/// Edge Functions via the composition root's callback overrides.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchant_feature/merchant_feature.dart';
import 'package:orders_feature/orders_feature.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';

/// Merchant incoming-orders tab.
class OrdersTab extends ConsumerWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        // MVP: single restaurant. Pass its id so the provider scopes correctly.
        return IncomingOrdersPage(restaurantId: list.first.id);
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
