/// Restaurant detail with menu (FR-DISC-004, PF-DOC-11 §3.1 presentation).
///
/// Covers the FL-R07 four states.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../application/discovery_providers.dart';

/// Detail view for one restaurant.
class RestaurantDetailPage extends ConsumerWidget {
  const RestaurantDetailPage({required this.restaurantId, super.key});

  final String restaurantId;

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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    subtitle: Text(item.description ?? ''),
                    trailing: Text(
                      formatIdr(item.price.amount),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
