/// Payment intent lifecycle (PF-DOC-13 `payment_intents`, PF-DOC-14 §3.3).
library;

import 'package:pare_core/pare_core.dart';

/// Lifecycle of a payment intent as surfaced to the UI.
enum PaymentIntentStatus {
  created,
  processing,
  succeeded,
  failed,
  refunded;

  static PaymentIntentStatus statusFromString(String? value) {
    return switch (value) {
      'created' => PaymentIntentStatus.created,
      'processing' => PaymentIntentStatus.processing,
      'succeeded' => PaymentIntentStatus.succeeded,
      'failed' => PaymentIntentStatus.failed,
      'refunded' => PaymentIntentStatus.refunded,
      _ => PaymentIntentStatus.created,
    };
  }

  static String statusToWire(PaymentIntentStatus s) => switch (s) {
    PaymentIntentStatus.created => 'created',
    PaymentIntentStatus.processing => 'processing',
    PaymentIntentStatus.succeeded => 'succeeded',
    PaymentIntentStatus.failed => 'failed',
    PaymentIntentStatus.refunded => 'refunded',
  };
}

/// Mirrors the `payment_intents` table (migration 0007). A charge or refund
/// attempt; idempotent per the client-supplied key (API-R02).
class PaymentIntent {
  const PaymentIntent({
    required this.id,
    required this.orderId,
    required this.intentType,
    required this.amount,
    required this.status,
    this.psp,
    this.pspStatus,
    this.createdAt,
  });

  final String id;
  final String? orderId;
  final PaymentIntentType intentType;
  final Money amount;
  final PaymentIntentStatus status;
  final String? psp;
  final String? pspStatus;
  final DateTime? createdAt;

  bool get isSucceeded => status == PaymentIntentStatus.succeeded;
  bool get isTerminal =>
      status == PaymentIntentStatus.succeeded ||
      status == PaymentIntentStatus.failed ||
      status == PaymentIntentStatus.refunded;
}

/// `payment_intents.intent_type` column (migration 0007).
enum PaymentIntentType { charge, refund, payout }

extension PaymentIntentTypeWire on PaymentIntentType {
  String toWire() => switch (this) {
    PaymentIntentType.charge => 'charge',
    PaymentIntentType.refund => 'refund',
    PaymentIntentType.payout => 'payout',
  };

  static PaymentIntentType fromString(String? value) {
    return switch (value) {
      'charge' => PaymentIntentType.charge,
      'refund' => PaymentIntentType.refund,
      'payout' => PaymentIntentType.payout,
      _ => PaymentIntentType.charge,
    };
  }
}
