/// Cart page — FL-R07 loading/error/empty/data states.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_design/pare_design.dart';

import '../../application/cart_providers.dart';

/// Displays cart contents with item list, subtotal, checkout CTA (FR-CART-001, FR-CART-002).
class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final fees = ref.watch(feeBreakdownProvider);

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Keranjang')),
        body: const PfEmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'Keranjang Kosong',
          subtitle: 'Mulai belanja dari restoran favorit Anda',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => ref.read(cartProvider.notifier).clear(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(PfSpacing.md),
        children: [
          Text(
            cart.restaurantName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: PfSpacing.md),
          ...cart.items.map((item) => _CartItemTile(item: item)),
          const SizedBox(height: PfSpacing.lg),
          _FeeBreakdownCard(breakdown: fees),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(PfSpacing.md),
        child: PfButton(
          label: 'Lanjut ke Checkout',
          onPressed: () {}
        ),
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  const _CartItemTile({required this.item});
  final cartItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(PfSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name),
                  Text(item.itemTotal.toString()),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  iconSize: 20,
                  onPressed: item.quantity > 1
                      ? () => ref.read(cartProvider.notifier)
                          .updateQuantity(item.cartItemId, item.quantity - 1)
                      : null,
                ),
                Text(item.quantity.toString()),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 20,
                  onPressed: () => ref.read(cartProvider.notifier)
                      .updateQuantity(item.cartItemId, item.quantity + 1),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => ref.read(cartProvider.notifier)
                      .removeItem(item.cartItemId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeeBreakdownCard extends StatelessWidget {
  const _FeeBreakdownCard({required this.breakdown});
  final FeeBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(PfSpacing.md),
        child: Column(
          children: [
            _FeeRow('Subtotal', breakdown.subtotal),
            _FeeRow('Ongkir', breakdown.deliveryFee),
            _FeeRow('Layanan', breakdown.serviceFee),
            const Divider(),
            _FeeRow('Total', breakdown.total, isTotal: true),
          ],
        ),
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  const _FeeRow(this.label, this.amount, {this.isTotal = false});
  final String label;
  final Money amount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(amount.toString()),
        ],
      ),
    );
  }
}
