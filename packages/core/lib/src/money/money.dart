/// Money value object for PareFood.
///
/// Amounts are stored as whole Rupiah (IDR has no minor units for display;
/// PF-DOC-16 §3.3). The database stores money as `bigint` (PF-DOC-13 DB-R02),
/// so JSON representation is the integer amount as a string.
library;

import 'package:meta/meta.dart';

/// Immutable money value holding a whole-rupiah amount.
///
/// [BigInt] guarantees exact arithmetic on Flutter Web, where `int` is
/// precision-limited (53-bit). All operations return a new [Money].
@immutable
class Money implements Comparable<Money> {
  /// Creates [Money] from a [BigInt] amount. Const-constructible so [Money]
  /// can be used in const contexts (default parameter values, compile-time
  /// constants). Negative amounts are guarded at runtime by the
  /// [Money.fromRupiah] factory and the subtraction operator.
  const Money(this._amount);

  /// Amount in whole Rupiah.
  final BigInt _amount;

  /// Creates [Money] from a whole-rupiah [int]. Asserts non-negative.
  factory Money.fromRupiah(int rupiah) {
    assert(rupiah >= 0, 'Money cannot be negative');
    return Money(BigInt.from(rupiah));
  }

  /// Zero value. Lazily initialised because [BigInt.zero] is not a
  /// compile-time constant.
  static final Money zero = Money(BigInt.zero);

  /// Creates [Money] from the integer amount, parsing a JSON string value.
  factory Money.fromJson(Object? json) {
    if (json is int) return Money.fromRupiah(json);
    if (json is String) return Money(BigInt.parse(json));
    throw FormatException('Cannot parse Money from $json');
  }

  /// Whole-rupiah amount.
  BigInt get amount => _amount;

  /// Whether this is a zero amount.
  bool get isZero => _amount == BigInt.zero;

  Money operator +(Money other) => Money(_amount + other._amount);

  Money operator -(Money other) {
    final result = _amount - other._amount;
    if (result.isNegative) {
      throw ArgumentError('Money cannot go below zero: $result');
    }
    return Money(result);
  }

  Money operator *(int factor) => Money(_amount * BigInt.from(factor));

  bool operator >(Money other) => _amount > other._amount;
  bool operator >=(Money other) => _amount >= other._amount;
  bool operator <(Money other) => _amount < other._amount;
  bool operator <=(Money other) => _amount <= other._amount;

  @override
  int compareTo(Money other) => _amount.compareTo(other._amount);

  /// Renders as a plain integer string, e.g. `85000`.
  String get toJson => _amount.toString();

  @override
  bool operator ==(Object other) => other is Money && other._amount == _amount;

  @override
  int get hashCode => _amount.hashCode;

  @override
  String toString() => 'Money(${_amount.toString()})';
}
