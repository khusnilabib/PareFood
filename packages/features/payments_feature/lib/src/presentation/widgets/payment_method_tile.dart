/// Single payment-method row for [PaymentsPage].
library;

import 'package:flutter/material.dart';

import '../../domain/payment_method.dart';

/// Compact row describing one [PaymentMethod].
class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({required this.method, super.key});

  final PaymentMethod method;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.account_balance_wallet_outlined),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  String get label => switch (method) {
    PaymentMethod.qris => 'QRIS',
    PaymentMethod.virtualAccount => 'Virtual Account',
    PaymentMethod.ewallet => 'E-Wallet',
    PaymentMethod.cashOnDelivery => 'Bayar di Tempat',
  };
}
