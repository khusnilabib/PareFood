/// Menu tab: menu management for the merchant's first restaurant; prompts to
/// complete onboarding while no restaurant exists (FR-MENU-001).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:menu_feature/menu_feature.dart';
import 'package:merchant_feature/merchant_feature.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';

/// Shows menu management once a restaurant exists, guidance otherwise.
class MenuTab extends ConsumerWidget {
  const MenuTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurants = ref.watch(myRestaurantsProvider);
    return restaurants.when(
      data: (list) {
        if (list.isEmpty) {
          return const Scaffold(
            body: PfEmptyState(
              icon: Icons.restaurant_menu_outlined,
              title: 'Belum ada restoran',
              subtitle:
                  'Daftarkan restoran Anda di tab Restoran untuk mulai '
                  'mengelola menu.',
            ),
          );
        }
        return MenuManagementPage(restaurantId: list.first.id);
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
