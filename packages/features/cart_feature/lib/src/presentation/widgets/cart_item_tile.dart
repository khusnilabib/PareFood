/// Single cart row with name, quantity stepper and line total (PF-DOC-16).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../application/cart_providers.dart';
import '../../domain/cart_item.dart';

/// Compact row for one [CartItem] with inline quantity controls.
class CartItemTile extends ConsumerWidget {
  const CartItemTile({required this.item, super.key});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(item.productId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: theme.colorScheme.errorContainer,
        padding: const EdgeInsets.only(right: PfSpacing.lg),
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      onDismissed: (_) =>
          ref.read(cartProvider.notifier).removeProduct(item.productId),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PfSpacing.md,
          vertical: PfSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: theme.textTheme.bodyLarge),
                  Text(
                    '${formatIdr(item.unitPrice.amount)} / item',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Quantity stepper
            _QuantityStepper(item: item),
            const SizedBox(width: PfSpacing.md),
            SizedBox(
              width: 88,
              child: Text(
                formatIdr(item.lineTotal.amount),
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends ConsumerWidget {
  const _QuantityStepper({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(PfRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                ref.read(cartProvider.notifier).decrement(item.productId),
          ),
          Text(
            '${item.quantity}',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                ref.read(cartProvider.notifier).increment(item.productId),
          ),
        ],
      ),
    );
  }
}
