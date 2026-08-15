/// Payments providers (PF-DOC-11 §3.2).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_core/pare_core.dart';

import '../data/payments_repository.dart';
import '../domain/payment_method.dart';
import '../domain/promo_code.dart';

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

/// Validates a promo code against [subtotal]. Family so each code gets its
/// own cached result; pass an empty code to reset.
final promoValidationProvider =
    FutureProvider.family<PromoValidation, ({String code, Money subtotal})>((
      ref,
      params,
    ) {
      if (params.code.trim().isEmpty) {
        return Future.value(PromoValidation.none);
      }
      return ref
          .watch(paymentsRepositoryProvider)
          .validatePromo(code: params.code, subtotal: params.subtotal);
    });
