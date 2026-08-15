/// Settlement domain: restaurant payout for a period (BR-SETTLE-001, T+7).
///
/// Mirrors the `settlements` table (migration 0008). A settlement is created
/// per delivered order by `complete-order`, then aggregated and approved by
/// finance as a batch payout to the restaurant.
library;

import 'package:pare_core/pare_core.dart';

/// Lifecycle of a settlement as surfaced to the finance UI.
enum SettlementStatus { calculated, approved, paid, failed }

extension SettlementStatusX on SettlementStatus {
  String toWire() => switch (this) {
    SettlementStatus.calculated => 'calculated',
    SettlementStatus.approved => 'approved',
    SettlementStatus.paid => 'paid',
    SettlementStatus.failed => 'failed',
  };

  static SettlementStatus fromString(String? value) {
    return switch (value) {
      'approved' => SettlementStatus.approved,
      'paid' => SettlementStatus.paid,
      'failed' => SettlementStatus.failed,
      _ => SettlementStatus.calculated,
    };
  }

  String get label => switch (this) {
    SettlementStatus.calculated => 'Dihitung',
    SettlementStatus.approved => 'Disetujui',
    SettlementStatus.paid => 'Dibayar',
    SettlementStatus.failed => 'Gagal',
  };
}

/// One settlement row for a restaurant + period.
class Settlement {
  const Settlement({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.periodStart,
    required this.periodEnd,
    required this.gross,
    required this.commission,
    required this.net,
    required this.status,
    this.orderCount = 0,
    this.approvedAt,
  });

  final String id;
  final String restaurantId;
  final String restaurantName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Money gross;
  final Money commission;
  final Money net;
  final SettlementStatus status;
  final int orderCount;
  final DateTime? approvedAt;

  bool get isPending => status == SettlementStatus.calculated;
}
