/// Finance providers (PF-DOC-11 §3.2).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/finance_repository.dart';
import '../data/supabase_finance_repository.dart';
import '../domain/payout.dart';
import '../domain/reconciliation_report.dart';
import '../domain/settlement.dart';

/// Repository contract; override at the composition root (FL-R04).
final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return SupabaseFinanceRepository();
});

/// Settlements list (admin sees all; merchant filtered by RLS).
final settlementsProvider = FutureProvider<List<Settlement>>((ref) {
  return ref.watch(financeRepositoryProvider).fetchSettlements();
});

/// Driver payouts list.
final payoutsProvider = FutureProvider<List<DriverPayout>>((ref) {
  return ref.watch(financeRepositoryProvider).fetchPayouts();
});

/// Platform KPIs for the dashboard.
final platformKpisProvider = FutureProvider<PlatformKpis>((ref) {
  return ref.watch(financeRepositoryProvider).fetchKpis();
});

/// Reconciliation report for the last 7 days (default range).
final reconciliationProvider = FutureProvider<ReconciliationReport>((ref) {
  final now = DateTime.now();
  final from = now.subtract(const Duration(days: 7));
  return ref
      .watch(financeRepositoryProvider)
      .fetchReconciliation(from: from, to: now);
});

/// Approve settlements — callable so the UI can retry.
final approveSettlementsProvider =
    Provider<Future<void> Function(List<String>)>((ref) {
      return (ids) =>
          ref.read(financeRepositoryProvider).approveSettlements(ids);
    });
