/// Payments page covering all four states (FL-R07, PF-DOC-11 §3.5).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';

import '../../application/payments_providers.dart';
import '../widgets/payment_method_tile.dart';

/// Payment methods offered to the user at checkout.
class PaymentsPage extends ConsumerWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methods = ref.watch(paymentMethodsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Metode Pembayaran')),
      body: methods.when(
        data: (list) => list.isEmpty
            ? const PfEmptyState(
                icon: Icons.credit_card_outlined,
                title: 'Belum ada metode pembayaran',
                subtitle: 'Metode pembayaran akan muncul di sini.',
              )
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    PaymentMethodTile(method: list[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => PfErrorState(
          onRetry: () => ref.invalidate(paymentMethodsProvider),
          error: error is PareException ? error : null,
          title: 'Gagal memuat metode pembayaran.',
        ),
      ),
    );
  }
}
