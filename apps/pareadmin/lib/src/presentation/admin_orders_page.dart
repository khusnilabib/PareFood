/// Admin orders page: order board with force-cancel wired (FR-ORDER-010/011).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orders_feature/orders_feature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_shell.dart';

/// Admin order board with force-cancel wired to cancel-order Edge Function.
class AdminOrdersPage extends ConsumerWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminShell(
      section: AdminSection.orders,
      child: AdminOrderBoardPage(
        onForceCancel: (context, order) => _forceCancel(context, ref, order),
        onOpenDetail: (context, orderId) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => OrderDetailPage(orderId: orderId),
            ),
          );
        },
      ),
    );
  }

  Future<void> _forceCancel(
    BuildContext context,
    WidgetRef ref,
    OrderSummary order,
  ) async {
    final reason = await _promptReason(context);
    if (reason == null || reason.trim().isEmpty) return;
    try {
      await Supabase.instance.client.functions.invoke(
        'cancel-order',
        headers: {'x-idempotency-key': 'cancel-${order.id}'},
        body: {'order_id': order.id, 'reason': reason.trim(), 'actor': 'admin'},
      );
      ref.invalidate(allOrdersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan dibatalkan paksa. Audit log dicatat.'),
          ),
        );
      }
    } on Object catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<String?> _promptReason(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Batalkan pesanan paksa'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Alasan (wajib, dicatat di audit log)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Batalkan'),
            ),
          ],
        );
      },
    );
  }
}
