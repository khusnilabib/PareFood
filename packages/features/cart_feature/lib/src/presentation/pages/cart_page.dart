/// Cart page (FL-R07: renders content or an empty state).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../application/cart_providers.dart';
import '../widgets/cart_item_tile.dart';

/// Cart screen bound to [cartProvider].
class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang')),
      body: cart.isEmpty
          ? const PfEmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Keranjang masih kosong',
              subtitle: 'Tambahkan menu favoritmu untuk mulai memesan.',
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        CartItemTile(item: cart.items[index]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(PfSpacing.md),
                  child: Row(
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        formatIdr(cart.subtotal.amount),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
