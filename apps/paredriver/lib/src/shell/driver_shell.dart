/// Signed-in driver shell: bottom navigation over Pekerjaan (job feed) and
/// Akun (profile). Accept/decline/pickup/deliver actions are wired to Edge
/// Functions via [SupabaseClient.functions.invoke] (FR-ORDER-004/005/006).
/// An online/offline toggle controls whether the driver receives job offers
/// (FR-ONB-004).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orders_feature/orders_feature.dart';
import 'package:pare_design/pare_design.dart';
import 'package:profile_feature/profile_feature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Hosts the signed-in driver experience.
class DriverShell extends ConsumerStatefulWidget {
  const DriverShell({super.key});

  @override
  ConsumerState<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends ConsumerState<DriverShell> {
  bool _online = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PareDriver'),
          actions: [
            _OnlineToggle(
              online: _online,
              onToggle: (v) => setState(() => _online = v),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            DriverJobsPage(
              onAcceptJob: (context, job) =>
                  _invokeJobAction(context, job, 'accept-job'),
              onDeclineJob: (context, job) =>
                  _invokeJobAction(context, job, 'decline-job'),
              onPickup: (context, job) => _invokePickup(context, job),
              onDeliver: (context, job) => _invokeDeliver(context, job),
            ),
            const ProfilePage(),
          ],
        ),
        bottomNavigationBar: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Pekerjaan'),
            Tab(icon: Icon(Icons.person_outline), text: 'Akun'),
          ],
        ),
      ),
    );
  }

  /// Invokes a job-lifecycle Edge Function (accept-job / decline-job).
  Future<void> _invokeJobAction(
    BuildContext context,
    DeliveryJob job,
    String functionName,
  ) async {
    try {
      await Supabase.instance.client.functions.invoke(
        functionName,
        headers: {'x-idempotency-key': '$functionName-${job.deliveryId}'},
        body: {'delivery_id': job.deliveryId},
      );
      ref.invalidate(driverJobsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              functionName == 'accept-job'
                  ? 'Tugas diterima. Ambil pesanan di restoran.'
                  : 'Tugas dilewati.',
            ),
          ),
        );
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  /// Driver confirms pickup with the 4-digit code (FR-ORDER-005, BR-PICKUP).
  Future<void> _invokePickup(BuildContext context, DeliveryJob job) async {
    // Prompt for the pickup code.
    final code = await _promptForCode(context, job.pickupCode);
    if (code == null) return;
    try {
      await Supabase.instance.client.functions.invoke(
        'driver-pickup',
        headers: {'x-idempotency-key': 'pickup-${job.deliveryId}'},
        body: {'delivery_id': job.deliveryId, 'pickup_code': code},
      );
      ref.invalidate(driverJobsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan diambil. Antar ke pelanggan.')),
        );
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  /// Driver confirms delivery with a photo proof URL (FR-ORDER-006).
  /// In a full impl, the photo is uploaded to Storage first; here we pass a
  /// placeholder URL (S12 hardening wires the real upload).
  Future<void> _invokeDeliver(BuildContext context, DeliveryJob job) async {
    try {
      await Supabase.instance.client.functions.invoke(
        'driver-delivered',
        headers: {'x-idempotency-key': 'deliver-${job.deliveryId}'},
        body: {
          'delivery_id': job.deliveryId,
          'proof_photo_url':
              'https://cdn.parefood.co/proof/${job.deliveryId}.jpg',
        },
      );
      ref.invalidate(driverJobsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengantaran selesai. Terima kasih!')),
        );
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  /// Shows a dialog to enter the 4-digit pickup code. When the job already
  /// carries a [pickupCode] (driver view), it's pre-filled.
  Future<String?> _promptForCode(BuildContext context, String? prefill) async {
    final controller = TextEditingController(text: prefill ?? '');
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kode Pickup'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(
              labelText: '4-digit kode',
              hintText: '0000',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Konfirmasi'),
            ),
          ],
        );
      },
    );
  }
}

/// Compact online/offline switch in the AppBar. When toggled, in a full impl
/// it updates `driver_locations.online` via an Edge Function (FR-ONB-004).
class _OnlineToggle extends StatelessWidget {
  const _OnlineToggle({required this.online, required this.onToggle});

  final bool online;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: PfSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            online ? 'Online' : 'Offline',
            style: theme.textTheme.labelMedium?.copyWith(
              color: online
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: PfSpacing.xxs),
          Switch(value: online, onChanged: onToggle),
        ],
      ),
    );
  }
}
