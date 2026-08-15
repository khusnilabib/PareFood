/// Payment methods surfaced at checkout (PF-DOC-18 §3.4, DB CHECK in 0007).
///
/// Values match the `orders.payment_method` column exactly so repository
/// mapping is a direct lookup.
library;

/// Supported payment methods. The wire value matches the DB CHECK constraint.
enum PaymentMethod {
  cashOnDelivery,
  ewallet,
  card;

  /// Parses the DB string; falls back to [cashOnDelivery] for unknown values.
  static PaymentMethod fromString(String? value) {
    return switch (value) {
      'cod' => PaymentMethod.cashOnDelivery,
      'ewallet' => PaymentMethod.ewallet,
      'card' => PaymentMethod.card,
      _ => PaymentMethod.cashOnDelivery,
    };
  }

  /// The DB column value (snake_case).
  String toWire() => switch (this) {
    PaymentMethod.cashOnDelivery => 'cod',
    PaymentMethod.ewallet => 'ewallet',
    PaymentMethod.card => 'card',
  };

  /// Human-readable Indonesian label.
  String get label => switch (this) {
    PaymentMethod.cashOnDelivery => 'Bayar di Tempat (COD)',
    PaymentMethod.ewallet => 'E-Wallet (GoPay/OVO/DANA)',
    PaymentMethod.card => 'Kartu Debit/Kredit',
  };

  /// Material icon for the method.
  int get icon => switch (this) {
    PaymentMethod.cashOnDelivery => 0xe59c, // Icons.payments_outlined
    PaymentMethod.ewallet => 0xe6fc, // Icons.account_balance_wallet_outlined
    PaymentMethod.card => 0xe6a1, // Icons.credit_card_outlined
  };
}
