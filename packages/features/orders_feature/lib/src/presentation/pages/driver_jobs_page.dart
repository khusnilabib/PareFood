/// Driver job feed + active delivery (FR-ORDER-004/005/006, PF-DOC-11 §3.5).
///
/// Lists delivery jobs offered/assigned to the driver. Accept/decline (BR-JOB),
/// pickup-code verify (BR-PICKUP) and drop-off photo proof (BR-DELIVERY) are
/// callback-injected (MO-R02d).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../application/orders_providers.dart';
import '../../domain/order_detail.dart';

/// Driver job feed.
class DriverJobsPage extends ConsumerWidget {
  const DriverJobsPage({
    this.onAcceptJob,
    this.onDeclineJob,
    this.onPickup,
    this.onDeliver,
    super.key,
  });

  final void Function(BuildContext context, DeliveryJob job)? onAcceptJob;
  final void Function(BuildContext context, DeliveryJob job)? onDeclineJob;
  final void Function(BuildContext context, DeliveryJob job)? onPickup;
  final void Function(BuildContext context, DeliveryJob job)? onDeliver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(driverJobsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pekerjaan')),
      body: jobs.when(
        data: (list) {
          if (list.isEmpty) {
            return const PfEmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'Belum ada pekerjaan',
              subtitle: 'Tugas antar akan muncul di sini saat tersedia.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(PfSpacing.md),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: PfSpacing.sm),
            itemBuilder: (context, index) => _JobRow(
              job: list[index],
              onAccept: onAcceptJob,
              onDecline: onDeclineJob,
              onPickup: onPickup,
              onDeliver: onDeliver,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => PfErrorState(
          onRetry: () => ref.invalidate(driverJobsProvider),
          error: error is PareException ? error : null,
          title: 'Gagal memuat pekerjaan.',
        ),
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({
    required this.job,
    this.onAccept,
    this.onDecline,
    this.onPickup,
    this.onDeliver,
  });

  final DeliveryJob job;
  final void Function(BuildContext, DeliveryJob)? onAccept;
  final void Function(BuildContext, DeliveryJob)? onDecline;
  final void Function(BuildContext, DeliveryJob)? onPickup;
  final void Function(BuildContext, DeliveryJob)? onDeliver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(PfSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${job.orderNo} • ${job.restaurantName}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  formatIdr(job.fare.amount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: PfSpacing.xs),
            _RouteLine(
              from: job.restaurantAddress,
              to: '${job.customerName} • ${job.deliveryAddress}',
              distanceKm: job.distanceKm,
            ),
            const SizedBox(height: PfSpacing.sm),
            _actionsFor(context),
          ],
        ),
      ),
    );
  }

  Widget _actionsFor(BuildContext context) {
    switch (job.status) {
      case DeliveryStatus.assigned:
        return Row(
          children: [
            Expanded(
              child: PfButton(
                label: 'Ambil tugas',
                size: PfButtonSize.medium,
                onPressed: onAccept == null
                    ? null
                    : () => onAccept!(context, job),
              ),
            ),
            const SizedBox(width: PfSpacing.sm),
            Expanded(
              child: PfButton(
                label: 'Lewati',
                variant: PfButtonVariant.outline,
                size: PfButtonSize.medium,
                onPressed: onDecline == null
                    ? null
                    : () => onDecline!(context, job),
              ),
            ),
          ],
        );
      case DeliveryStatus.arrivedPickup:
        return PfButton(
          label: job.pickupCode != null
              ? 'Ambil pesanan (kode ${job.pickupCode})'
              : 'Ambil pesanan',
          icon: Icons.qr_code,
          size: PfButtonSize.medium,
          onPressed: onPickup == null ? null : () => onPickup!(context, job),
        );
      case DeliveryStatus.pickedUp:
        return PfButton(
          label: 'Selesaikan pengantaran',
          icon: Icons.photo_camera_outlined,
          size: PfButtonSize.medium,
          onPressed: onDeliver == null ? null : () => onDeliver!(context, job),
        );
      case DeliveryStatus.delivered:
      case DeliveryStatus.failed:
        return const SizedBox.shrink();
    }
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({
    required this.from,
    required this.to,
    required this.distanceKm,
  });

  final String from;
  final String to;
  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(Icons.store, size: 16, color: muted),
            Container(width: 2, height: 20, color: theme.dividerColor),
            Icon(Icons.location_on, size: 16, color: muted),
          ],
        ),
        const SizedBox(width: PfSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                from,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                to,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: PfSpacing.sm),
        Text(
          '${distanceKm.toStringAsFixed(1)} km',
          style: theme.textTheme.labelSmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}
