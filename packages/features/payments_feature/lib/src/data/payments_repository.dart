/// Payments repository contract (PF-DOC-11 §3.1 data layer).
///
/// Concrete implementations live in the app composition root and delegate to
/// `pare_data` (Dio/Supabase); features never import the SDKs directly
/// (MO-R02a). Overrides of [paymentsRepositoryProvider] are the only test seam
/// (FL-R04).
library;

import 'package:pare_core/pare_core.dart';

import '../domain/payment_method.dart';
import '../domain/payment_result.dart';

/// Contract implemented by the composition root.
abstract interface class PaymentsRepository {
  /// Creates a charge. [idempotencyKey] is required so retries never create
  /// duplicate charges (NFR-021, FL-R05).
  Future<PaymentResult> createCharge({
    required String orderId,
    required String idempotencyKey,
    required Money amount,
    required PaymentMethod method,
  });

  /// Methods currently offered to the user.
  Future<List<PaymentMethod>> availableMethods();
}
