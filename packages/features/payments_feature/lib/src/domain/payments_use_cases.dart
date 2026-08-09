/// Payments use cases (PF-DOC-11 §3.1 domain layer). Pure Dart; no Flutter.
///
/// Idempotency is enforced here and mirrored server-side (PF-DOC-18).
library;

import 'package:pare_core/pare_core.dart';

import '../data/payments_repository.dart';
import 'payment_method.dart';
import 'payment_result.dart';

/// Creates a charge with a mandatory [idempotencyKey]; throws [ArgumentError]
/// when absent so retried taps never double-charge (NFR-021).
class CreateCharge {
  const CreateCharge(this._repository);

  final PaymentsRepository _repository;

  Future<PaymentResult> call({
    required String orderId,
    required Money amount,
    required PaymentMethod method,
    String? idempotencyKey,
  }) {
    final key = idempotencyKey;
    if (key == null || key.isEmpty) {
      throw ArgumentError.value(
        idempotencyKey,
        'idempotencyKey',
        'Required to guarantee exactly-once payment (NFR-021).',
      );
    }
    return _repository.createCharge(
      orderId: orderId,
      idempotencyKey: key,
      amount: amount,
      method: method,
    );
  }
}
