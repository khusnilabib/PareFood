/// Discovery home: nearest-first restaurant list (FR-DISC-001, PF-DOC-11 §3.1).
///
/// Covers the FL-R07 four states (loading / data / error / empty).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';

import '../../application/discovery_providers.dart';
import 'restaurant_detail_page.dart';

/// Discovery list for a fixed reference location (Sprint 1; geolocation wiring
/// lands with the customer app).
class DiscoveryPage extends ConsumerWidget {
  const DiscoveryPage({super.key});

  static const _defaultLat = -6.200000;
  static const _defaultLng = 106.816666;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurants = ref.watch(
      nearbyRestaurantsProvider((
        lat: _defaultLat,
        lng: _defaultLng,
        radiusKm: 5,
      )),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Temukan Restoran')),
      body: restaurants.when(
        data: (list) {
          if (list.isEmpty) {
            return const PfEmptyState(
              icon: Icons.storefront_outlined,
              title: 'Belum ada restoran',
              subtitle: 'Belum ada restoran aktif di sekitar Anda.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(PfSpacing.md),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: PfSpacing.sm),
            itemBuilder: (context, index) {
              final r = list[index];
              return Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    foregroundImage: r.logoUrl == null
                        ? null
                        : NetworkImage(r.logoUrl!),
                    child: Text(r.name.characters.first.toUpperCase()),
                  ),
                  title: Text(r.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (r.description != null)
                        Text(
                          r.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            r.ratingAvg > 0
                                ? '${r.ratingAvg.toStringAsFixed(1)} (${r.reviewCount})'
                                : 'Baru',
                          ),
                          const SizedBox(width: PfSpacing.md),
                          const Icon(Icons.delivery_dining, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            'Jangkauan ${r.deliveryRadiusKm.toStringAsFixed(0)} km',
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            RestaurantDetailPage(restaurantId: r.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => PfErrorState(
          onRetry: () => ref.invalidate(
            nearbyRestaurantsProvider((
              lat: _defaultLat,
              lng: _defaultLng,
              radiusKm: 5,
            )),
          ),
          error: error is PareException ? error : null,
          title: 'Gagal memuat restoran.',
        ),
      ),
    );
  }
}
