/// Merchant verification status page (FR-ONB-002, PF-DOC-11 §3.1).
library;

import 'package:flutter/material.dart';
import 'package:pare_design/pare_design.dart';

import '../../domain/restaurant.dart';

/// Shows the merchant's restaurant and its verification status.
class MerchantStatusPage extends StatelessWidget {
  const MerchantStatusPage({required this.restaurant, super.key});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (badge, title, message) = switch (restaurant.status) {
      RestaurantStatus.active => (
        const PfStatusBadge(status: PfStatus.active, label: 'Aktif'),
        'Restoran Anda aktif!',
        'Anda dapat mulai mengelola menu dan menerima pesanan.',
      ),
      RestaurantStatus.pending => (
        const PfStatusBadge(
          status: PfStatus.pending,
          label: 'Menunggu Verifikasi',
        ),
        'Verifikasi sedang berlangsung',
        'Dokumen Anda sedang diperiksa. Anda akan dapat mengelola menu setelah disetujui.',
      ),
      RestaurantStatus.suspended || RestaurantStatus.rejected => (
        const PfStatusBadge(status: PfStatus.error, label: 'Ditolak'),
        'Verifikasi ditolak',
        'Silakan periksa dokumen Anda dan daftar ulang.',
      ),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Status Restoran')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PfSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: badge),
              const SizedBox(height: PfSpacing.lg),
              Text(
                restaurant.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: PfSpacing.sm),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: PfSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: PfSpacing.lg),
              if (restaurant.status == RestaurantStatus.active)
                PfButton(
                  label: 'Kelola Menu',
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Menu management di halaman terpisah.'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
