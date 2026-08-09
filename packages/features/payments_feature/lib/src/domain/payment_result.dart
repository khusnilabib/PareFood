/// Result of a payment attempt.
library;

import 'package:pare_core/pare_core.dart';

/// Lifecycle of a charge as surfaced to the UI.
enum PaymentStatus { pending, success, failed }

/// Immutable payment attempt result.
class PaymentResult {
  const PaymentResult({
    required this.paymentId,
    required this.status,
    this.authorizedAmount,
  });

  final String paymentId;
  final PaymentStatus status;

  /// Authorized amount when the provider reports it at creation.
  final Money? authorizedAmount;

  bool get isSuccess => status == PaymentStatus.success;
}
