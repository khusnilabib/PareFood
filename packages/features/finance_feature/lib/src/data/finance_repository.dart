/// Finance repository contract (PF-DOC-11 §3.5).
///
/// Role-scoped: admin sees all; merchant sees own settlements; driver sees
/// own payouts. Concrete implementations live in the app composition root
/// (FL-R04).
library;

import 'package:pare_core/pare_core.dart';

import '../domain/payout.dart';
import '../domain/reconciliation_report.dart';
import '../domain/settlement.dart';

abstract interface class FinanceRepository {
  /// Restaurant settlements for a period. Admin sees all; merchant sees own
  /// (filtered by RLS to the caller's restaurants).
  Future<List<Settlement>> fetchSettlements({
    String? restaurantId,
    DateTime? from,
    DateTime? to,
  });

  /// Approves a batch of settlements for payout (finance action).
  Future<void> approveSettlements(List<String> settlementIds);

  /// Driver payouts for a period.
  Future<List<DriverPayout>> fetchPayouts({
    String? driverId,
    DateTime? from,
    DateTime? to,
  });

  /// Generates a reconciliation report for [from]–[to].
  Future<ReconciliationReport> fetchReconciliation({
    required DateTime from,
    required DateTime to,
  });

  /// Platform analytics KPIs for the dashboard.
  Future<PlatformKpis> fetchKpis();
}

/// Aggregated platform KPIs for the admin dashboard.
class PlatformKpis {
  const PlatformKpis({
    required this.ordersToday,
    required this.gmvToday,
    required this.activeMerchants,
    required this.activeDrivers,
    required this.pendingSettlements,
    required this.pendingPayouts,
  });

  final int ordersToday;
  final Money gmvToday;
  final int activeMerchants;
  final int activeDrivers;
  final Money pendingSettlements;
  final Money pendingPayouts;
}
