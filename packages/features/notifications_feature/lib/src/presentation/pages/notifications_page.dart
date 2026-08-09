/// Notifications page covering all four states (FL-R07, PF-DOC-11 §3.5).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';

import '../../application/notifications_providers.dart';
import '../widgets/notification_tile.dart';

/// Notifications for the signed-in user.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: notifications.when(
        data: (list) => list.isEmpty
            ? const PfEmptyState(
                icon: Icons.notifications_none,
                title: 'Belum ada notifikasi',
                subtitle: 'Pembaruan pesanan akan muncul di sini.',
              )
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    NotificationTile(notification: list[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => PfErrorState(
          onRetry: () => ref.invalidate(notificationsProvider),
          error: error is PareException ? error : null,
          title: 'Gagal memuat notifikasi.',
        ),
      ),
    );
  }
}
