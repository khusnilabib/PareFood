/// Reconciliation report page (admin finance view, BR-RECON, BR-COD-004).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../application/finance_providers.dart';

/// Admin reconciliation report.
class ReconciliationPage extends ConsumerWidget {
  const ReconciliationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reconciliationProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Rekonsiliasi')),
      body: report.when(
        data: (r) => ListView(
          padding: const EdgeInsets.all(PfSpacing.md),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(PfSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Periode 7 hari terakhir',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: PfSpacing.sm),
                    _row('GMV (gross)', formatIdr(r.grossOrderTotal.amount)),
                    _row(
                      'Komisi terkumpul',
                      formatIdr(r.commissionCollected.amount),
                    ),
                    _row(
                      'Fare driver dibayar',
                      formatIdr(r.driverFaresPaid.amount),
                    ),
                    _row(
                      'Settlement restoran',
                      formatIdr(r.restaurantSettlements.amount),
                    ),
                    const Divider(),
                    _row('COD terkumpul', formatIdr(r.codCollected.amount)),
                    _row('COD disetor', formatIdr(r.codRemitted.amount)),
                    _row(
                      'COD outstanding',
                      formatIdr(r.codOutstanding.amount),
                      bold: !r.codOutstanding.isZero,
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Icon(
                          r.isClean ? Icons.check_circle : Icons.warning,
                          color: r.isClean
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: PfSpacing.xs),
                        Expanded(
                          child: Text(
                            r.isClean
                                ? 'Rekonsiliasi bersih — tidak ada mismatch.'
                                : '${r.mismatchCount} mismatch perlu review.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: r.isClean
                                      ? null
                                      : Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => PfErrorState(
          onRetry: () => ref.invalidate(reconciliationProvider),
          error: error is PareException ? error : null,
          title: 'Gagal memuat rekonsiliasi.',
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                label,
                style: bold
                    ? theme.textTheme.bodyLarge
                    : theme.textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                value,
                style: bold
                    ? theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      )
                    : theme.textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}
