/// Platform analytics dashboard with KPIs (admin view).
library;

import 'package:finance_feature/finance_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../application/finance_providers.dart';

/// Admin analytics dashboard with platform KPIs.
class AnalyticsDashboardPage extends ConsumerWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(platformKpisProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: kpis.when(
        data: (k) => ListView(
          padding: const EdgeInsets.all(PfSpacing.md),
          children: [
            _KpiGrid(kpis: k),
            const SizedBox(height: PfSpacing.md),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.account_balance_outlined),
                title: const Text('Settlement tertunda'),
                trailing: Text(
                  formatIdr(k.pendingSettlements.amount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: const Text('Payout driver tertunda'),
                trailing: Text(
                  formatIdr(k.pendingPayouts.amount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => PfErrorState(
          onRetry: () => ref.invalidate(platformKpisProvider),
          error: error is PareException ? error : null,
          title: 'Gagal memuat KPI.',
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpis});
  final PlatformKpis kpis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: PfSpacing.sm,
      mainAxisSpacing: PfSpacing.sm,
      childAspectRatio: 1.4,
      children: [
        _KpiCard(
          icon: Icons.receipt_long,
          label: 'Pesanan hari ini',
          value: '${kpis.ordersToday}',
          color: theme.colorScheme.primary,
        ),
        _KpiCard(
          icon: Icons.payments,
          label: 'GMV hari ini',
          value: formatIdr(kpis.gmvToday.amount),
          color: theme.colorScheme.tertiary,
        ),
        _KpiCard(
          icon: Icons.store,
          label: 'Merchant aktif',
          value: '${kpis.activeMerchants}',
          color: theme.colorScheme.secondary,
        ),
        _KpiCard(
          icon: Icons.local_shipping,
          label: 'Driver online',
          value: '${kpis.activeDrivers}',
          color: theme.colorScheme.primary,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(PfSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
