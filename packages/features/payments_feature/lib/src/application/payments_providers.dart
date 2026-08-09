/// Payments providers (PF-DOC-11 §3.2).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/payments_repository.dart';
import '../domain/payment_method.dart';

/// Repository contract; override at the composition root (FL-R04).
final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  throw UnimplementedError(
    'paymentsRepositoryProvider must be overridden in the composition root.',
  );
});

/// Methods currently offered to the user.
final paymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) {
  return ref.watch(paymentsRepositoryProvider).availableMethods();
});
