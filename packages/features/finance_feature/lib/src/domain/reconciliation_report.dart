/// Reconciliation report: COD totals vs remittances + settlement accuracy
/// (BR-RECON, BR-COD-004).
library;

import 'package:pare_core/pare_core.dart';

/// Aggregated reconciliation for a period. Flags mismatches for finance
/// review (BR-COD-004: COD totals vs driver remittances; BR-RECON: settlement
/// accuracy).
class ReconciliationReport {
  const ReconciliationReport({
    required this.periodStart,
    required this.periodEnd,
    required this.grossOrderTotal,
    required this.commissionCollected,
    required this.driverFaresPaid,
    required this.restaurantSettlements,
    required this.codCollected,
    required this.codRemitted,
    required this.mismatchCount,
  });

  final DateTime periodStart;
  final DateTime periodEnd;

  /// Sum of all delivered order totals.
  final Money grossOrderTotal;

  /// Commission retained by platform (BR-COMM-001).
  final Money commissionCollected;

  /// Driver fares paid out (BR-COMM-003: 100% of delivery fee).
  final Money driverFaresPaid;

  /// Net settled to restaurants.
  final Money restaurantSettlements;

  /// COD cash collected by drivers (to be remitted).
  final Money codCollected;

  /// COD cash remitted by drivers (verified).
  final Money codRemitted;

  /// Number of mismatches flagged for review.
  final int mismatchCount;

  /// COD outstanding = collected − remitted (BR-COD-001: ≤ 24h).
  Money get codOutstanding => codCollected - codRemitted;

  /// Whether the reconciliation is clean (no mismatches).
  bool get isClean => mismatchCount == 0 && codOutstanding.isZero;
}
