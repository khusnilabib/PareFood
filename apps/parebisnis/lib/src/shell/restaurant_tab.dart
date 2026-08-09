/// Restoran tab: onboarding wizard for merchants without a restaurant,
/// verification status once one exists (FR-ONB-001/002).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchant_feature/merchant_feature.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';

/// Switches between onboarding and status based on owned restaurants.
class RestaurantTab extends ConsumerWidget {
  const RestaurantTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurants = ref.watch(myRestaurantsProvider);
    return restaurants.when(
      data: (list) => list.isEmpty
          ? const MerchantOnboardingPage()
          : MerchantStatusPage(restaurant: list.first),
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
