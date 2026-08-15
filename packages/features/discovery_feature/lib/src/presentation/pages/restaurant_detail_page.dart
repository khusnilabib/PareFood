/// Restaurant detail with menu (FR-DISC-004, PF-DOC-11 §3.1 presentation).
///
/// Covers the FL-R07 four states. An optional [onAddToCart] callback enables
/// the "add to cart" affordance on each menu item; the app composition root
/// wires it to the cart (MO-R02d: this package never imports cart_feature).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../application/discovery_providers.dart';
import '../../domain/discovery_models.dart';

/// Detail view for one restaurant.
class RestaurantDetailPage extends ConsumerWidget {
  const RestaurantDetailPage({
    required this.restaurantId,
    this.onAddToCart,
    super.key,
  });

  final String restaurantId;

  /// Invoked when the user adds a menu item to the cart. When `null`, the
  /// add-to-cart buttons are hidden (read-only detail).
  final void Function(DiscoveryMenuItem item)? onAddToCart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(restaurantDetailProvider(restaurantId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detail')),
      body: detail.when(
        data: (value) {
          if (value == null) {
            return PfErrorState(
              onRetry: () =>
                  ref.invalidate(restaurantDetailProvider(restaurantId)),
              title: 'Restoran tidak ditemukan.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(PfSpacing.md),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    foregroundImage: value.restaurant.logoUrl == null
                        ? null
                        : NetworkImage(value.restaurant.logoUrl!),
                    child: Text(
                      value.restaurant.name.characters.first.toUpperCase(),
                    ),
                  ),
                  const SizedBox(width: PfSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value.restaurant.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (value.restaurant.ratingAvg > 0)
                          Text(
                            '${value.restaurant.ratingAvg.toStringAsFixed(1)} · ${value.restaurant.reviewCount} ulasan',
                          ),
                        if (value.restaurant.deliveryRadiusKm > 0)
                          Text(
                            'Jangkauan antar ${value.restaurant.deliveryRadiusKm.toStringAsFixed(0)} km',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (value.restaurant.description != null) ...[
                const SizedBox(height: PfSpacing.md),
                Text(value.restaurant.description!),
              ],
              const SizedBox(height: PfSpacing.lg),
              Text(
                'Menu',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: PfSpacing.sm),
              if (value.menu.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: PfSpacing.lg),
                  child: Text('Belum ada menu.'),
                )
              else
                for (final item in value.menu)
                  _MenuRow(
                    item: item,
                    onAdd: onAddToCart == null || !item.isAvailable
                        ? null
                        : () => onAddToCart!(item),
                  ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => PfErrorState(
          onRetry: () => ref.invalidate(restaurantDetailProvider(restaurantId)),
          error: error is PareException ? error : null,
          title: 'Gagal memuat detail.',
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item, required this.onAdd});

  final DiscoveryMenuItem item;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unavailable = !item.isAvailable;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PfSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: PfSpacing.sm),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(PfRadius.sm),
                child: Image.network(
                  item.imageUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const SizedBox(width: 56, height: 56),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: unavailable ? theme.disabledColor : null,
                  ),
                ),
                if (item.description != null)
                  Text(
                    item.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  formatIdr(item.price.amount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (unavailable)
                  Text(
                    'Stok habis',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: PfSpacing.sm),
          if (onAdd != null)
            IconButton.filled(
              icon: const Icon(Icons.add, size: 20),
              onPressed: onAdd,
              visualDensity: VisualDensity.compact,
            )
          else if (item.isAvailable)
            // When the add callback is not wired (read-only), show a disabled
            // hint so the affordance is still discoverable.
            const IconButton.filled(
              icon: Icon(Icons.add, size: 20),
              onPressed: null,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
