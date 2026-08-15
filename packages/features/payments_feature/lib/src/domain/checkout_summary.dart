/// Checkout fee breakdown (BR-PRICE-001, PF-DOC-18 §3.1).
///
/// `total = subtotal + delivery_fee + service_fee − discount`
/// All money in bigint IDR (PF-DOC-13).
library;

import 'package:pare_core/pare_core.dart';

/// Immutable checkout cost breakdown. The cart owns the subtotal; this model
/// adds the fees + discount computed at checkout time.
class CheckoutSummary {
  const CheckoutSummary({
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    this.discount,
  });

  final Money subtotal;
  final Money deliveryFee;
  final Money serviceFee;

  /// Applied discount (null when no promo is active).
  final Money? discount;

  /// `total = subtotal + delivery_fee + service_fee − discount` (BR-PRICE-001).
  /// Guarded to be ≥ 0 (BR-PRICE-003).
  Money get total {
    final discountAmount = discount?.amount ?? BigInt.zero;
    final raw =
        subtotal.amount +
        deliveryFee.amount +
        serviceFee.amount -
        discountAmount;
    return Money(raw < BigInt.zero ? BigInt.zero : raw);
  }

  /// Whether the order meets the minimum order value (BR-PRICE-005).
  bool meetsMinimum(Money minimum) => subtotal >= minimum;

  CheckoutSummary copyWithDiscount(Money discount) {
    return CheckoutSummary(
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      discount: discount,
    );
  }
}
