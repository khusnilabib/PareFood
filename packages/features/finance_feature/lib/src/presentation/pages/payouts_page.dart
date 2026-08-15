/// Driver payouts list page (admin finance view, FR-FIN-002/003).
library;

import 'package:finance_feature/finance_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../application/finance_providers.dart';

/// Admin driver payouts list.
class PayoutsPage extends ConsumerWidget {
  const PayoutsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payouts = ref.watch(payoutsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Payout Driver')),
      body: payouts.when(
        data: (list) {
          if (list.isEmpty) {
            return const PfEmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'Belum ada payout',
              subtitle:
                  'Payout driver akan muncul setelah pengantaran selesai.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(PfSpacing.md),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: PfSpacing.sm),
            itemBuilder: (context, index) {
              final p = list[index];
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(p.driverName),
                  subtitle: Text(
                    '${p.deliveryCount} pengantaran • ${_fmtDate(p.periodDate)}',
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatIdr(p.amount.amount),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      PfStatusBadge(
                        status: _badgeStatus(p.status),
                        label: p.status.label,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => PfErrorState(
          onRetry: () => ref.invalidate(payoutsProvider),
          error: error is PareException ? error : null,
          title: 'Gagal memuat payout.',
        ),
      ),
    );
  }

  PfStatus _badgeStatus(PayoutStatus s) => switch (s) {
    PayoutStatus.pending => PfStatus.pending,
    PayoutStatus.completed => PfStatus.active,
    PayoutStatus.failed => PfStatus.cancelled,
  };

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
