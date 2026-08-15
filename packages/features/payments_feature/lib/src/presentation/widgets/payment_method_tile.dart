/// Single payment-method row for [PaymentsPage].
library;

import 'package:flutter/material.dart';

import '../../domain/payment_method.dart';

/// Compact row describing one [PaymentMethod].
class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({required this.method, this.onTap, super.key});

  final PaymentMethod method;

  /// Called when the tile is tapped (e.g. to select at checkout).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_iconFor(method)),
      title: Text(method.label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// Maps a [PaymentMethod] to a const [IconData] (domain stays Flutter-free).
IconData _iconFor(PaymentMethod method) {
  return switch (method) {
    PaymentMethod.cashOnDelivery => Icons.payments_outlined,
    PaymentMethod.ewallet => Icons.account_balance_wallet_outlined,
    PaymentMethod.card => Icons.credit_card_outlined,
  };
}
