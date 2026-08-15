/// Promo code validation result (BR-PROMO-001..006, PF-DOC-18 §3.9).
library;

import 'package:pare_core/pare_core.dart';

/// Voucher types supported at MVP (BR-PROMO-001).
enum PromoType { fixed, percent, freeDelivery }

extension PromoTypeWire on PromoType {
  static PromoType fromString(String? value) {
    return switch (value) {
      'fixed' => PromoType.fixed,
      'percent' => PromoType.percent,
      'free_delivery' => PromoType.freeDelivery,
      _ => PromoType.fixed,
    };
  }

  String toWire() => switch (this) {
    PromoType.fixed => 'fixed',
    PromoType.percent => 'percent',
    PromoType.freeDelivery => 'free_delivery',
  };
}

/// The outcome of validating a promo code against a cart subtotal.
class PromoValidation {
  const PromoValidation({
    required this.code,
    required this.type,
    required this.discountAmount,
    required this.isValid,
    this.message,
    this.minSubtotal,
    this.maxDiscount,
  });

  /// The code as the user entered it.
  final String code;

  final PromoType type;

  /// Computed discount in rupiah (BR-PROMO-002: min subtotal + max discount
  /// enforced). Zero when invalid.
  final Money discountAmount;

  final bool isValid;

  /// User-facing message (why it was rejected, or confirmation).
  final String? message;

  /// Minimum subtotal required (BR-PROMO-002), for display.
  final Money? minSubtotal;

  /// Maximum discount cap (BR-PROMO-002), for display.
  final Money? maxDiscount;

  /// Empty (no promo applied) sentinel.
  static PromoValidation get none => PromoValidation(
    code: '',
    type: PromoType.fixed,
    discountAmount: Money.fromRupiah(0),
    isValid: false,
  );
}
