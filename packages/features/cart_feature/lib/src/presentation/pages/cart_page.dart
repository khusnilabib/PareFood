/// Cart page (FL-R07: renders content or an empty state).
///
/// Shows the bound restaurant (BR-CART-001), inline quantity steppers, and a
/// checkout CTA. Checkout is a demo flow here — the real `place-order` Edge
/// Function wiring lands in Sprint 5 (PF-DOC-25 §3.3).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../application/cart_providers.dart';
import '../widgets/cart_item_tile.dart';

/// Cart screen bound to [cartProvider].
class CartPage extends ConsumerWidget {
  const CartPage({this.onCheckout, super.key});

  /// When provided, the "Pesan Sekarang" button calls this instead of the
  /// demo confirmation dialog. The app composition root wires it to navigate
  /// to the full checkout flow (MO-R02d: cart_feature never imports the app).
  final VoidCallback? onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);
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
                if (cart.restaurantName != null)
                  Container(
                    width: double.infinity,
                    color: theme.colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.symmetric(
                      horizontal: PfSpacing.md,
                      vertical: PfSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_outlined, size: 18),
                        const SizedBox(width: PfSpacing.xs),
                        Expanded(
                          child: Text(
                            cart.restaurantName!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        CartItemTile(item: cart.items[index]),
                  ),
                ),
                SafeArea(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                    padding: const EdgeInsets.all(PfSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text('Total', style: theme.textTheme.titleMedium),
                            const Spacer(),
                            Text(
                              formatIdr(cart.subtotal.amount),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: PfSpacing.sm),
                        PfButton(
                          label: 'Pesan Sekarang',
                          icon: Icons.shopping_bag_outlined,
                          onPressed:
                              onCheckout ??
                              () => _confirmCheckout(
                                context,
                                ref,
                                cart.restaurantName,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _confirmCheckout(
    BuildContext context,
    WidgetRef ref,
    String? restaurantName,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi pesanan'),
          content: Text(
            restaurantName == null
                ? 'Pesan sekarang? Fitur pembayaran akan segera tersedia.'
                : 'Pesan dari $restaurantName sekarang? Fitur pembayaran akan segera tersedia.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clear();
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pesanan berhasil dibuat (demo).'),
                  ),
                );
              },
              child: const Text('Pesan'),
            ),
          ],
        );
      },
    );
  }
}
