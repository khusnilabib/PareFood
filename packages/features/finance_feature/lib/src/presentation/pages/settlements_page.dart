/// Settlements list page (admin finance view, FR-FIN-001).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../application/finance_providers.dart';
import '../../domain/settlement.dart';

/// Admin settlements list with approve action.
class SettlementsPage extends ConsumerWidget {
  const SettlementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlements = ref.watch(settlementsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settlement Restoran')),
      body: settlements.when(
        data: (list) {
          if (list.isEmpty) {
            return const PfEmptyState(
              icon: Icons.account_balance_outlined,
              title: 'Belum ada settlement',
              subtitle: 'Settlement akan muncul setelah pesanan selesai.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(PfSpacing.md),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: PfSpacing.sm),
            itemBuilder: (context, index) {
              final s = list[index];
              return _SettlementCard(
                settlement: s,
                onApprove: s.isPending
                    ? () => _approve(context, ref, [s.id])
                    : null,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => PfErrorState(
          onRetry: () => ref.invalidate(settlementsProvider),
          error: error is PareException ? error : null,
          title: 'Gagal memuat settlement.',
        ),
      ),
    );
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    List<String> ids,
  ) async {
    try {
      await ref.read(approveSettlementsProvider)(ids);
      ref.invalidate(settlementsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settlement disetujui.')));
      }
    } on Object catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }
}

class _SettlementCard extends StatelessWidget {
  const _SettlementCard({required this.settlement, this.onApprove});

  final Settlement settlement;
  final VoidCallback? onApprove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = settlement;
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
                    s.restaurantName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                PfStatusBadge(
                  status: _badgeStatus(s.status),
                  label: s.status.label,
                ),
              ],
            ),
            const SizedBox(height: PfSpacing.xs),
            Text(
              'Periode ${_fmtDate(s.periodStart)} – ${_fmtDate(s.periodEnd)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: PfSpacing.sm),
            _row('Gross', formatIdr(s.gross.amount)),
            _row('Komisi', '-${formatIdr(s.commission.amount)}'),
            _row('Net', formatIdr(s.net.amount), bold: true),
            if (onApprove != null) ...[
              const SizedBox(height: PfSpacing.sm),
              PfButton(
                label: 'Setujui',
                size: PfButtonSize.medium,
                onPressed: onApprove,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
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

  PfStatus _badgeStatus(SettlementStatus s) => switch (s) {
    SettlementStatus.calculated => PfStatus.pending,
    SettlementStatus.approved => PfStatus.active,
    SettlementStatus.paid => PfStatus.active,
    SettlementStatus.failed => PfStatus.cancelled,
  };

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
