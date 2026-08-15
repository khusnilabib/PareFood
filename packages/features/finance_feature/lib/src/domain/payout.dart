/// Driver payout domain: daily wallet credit for delivered orders
/// (BR-PAYOUT-001).
library;

import 'package:pare_core/pare_core.dart';

/// Lifecycle of a driver payout.
enum PayoutStatus { pending, completed, failed }

extension PayoutStatusX on PayoutStatus {
  String toWire() => switch (this) {
    PayoutStatus.pending => 'pending',
    PayoutStatus.completed => 'completed',
    PayoutStatus.failed => 'failed',
  };

  static PayoutStatus fromString(String? value) {
    return switch (value) {
      'completed' => PayoutStatus.completed,
      'failed' => PayoutStatus.failed,
      _ => PayoutStatus.pending,
    };
  }

  String get label => switch (this) {
    PayoutStatus.pending => 'Menunggu',
    PayoutStatus.completed => 'Selesai',
    PayoutStatus.failed => 'Gagal',
  };
}

/// One payout row for a driver + period.
class DriverPayout {
  const DriverPayout({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.periodDate,
    required this.amount,
    required this.deliveryCount,
    required this.status,
    this.bankAccountRef,
  });

  final String id;
  final String driverId;
  final String driverName;
  final DateTime periodDate;
  final Money amount;
  final int deliveryCount;
  final PayoutStatus status;
  final String? bankAccountRef;
}
