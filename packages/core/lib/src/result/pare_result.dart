/// Sealed result type for repository/use-case returns.
///
/// Every repository call in `pare_data` returns [PareResult] instead of
/// throwing raw exceptions, so callers switch on success/failure explicitly
/// (PF-DOC-11 §3.5). Generated with Freezed; committed (FL-R06).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../exceptions/pare_exception.dart';

part 'pare_result.freezed.dart';

/// Typed success-or-failure envelope. The failure branch carries a typed
/// [PareException]; success carries the domain value.
@freezed
sealed class PareResult<T> with _$PareResult<T> {
  const PareResult._();

  const factory PareResult.success(T data) = PareResultSuccess<T>;

  const factory PareResult.failure(PareException error) = PareResultFailure<T>;

  /// Convenience accessor: returns the value on success or throws the error.
  T get dataOrThrow => switch (this) {
    PareResultSuccess<T>(:final data) => data,
    PareResultFailure<T>(:final error) => throw error,
  };

  /// Whether this result represents a successful operation.
  bool get isSuccess => this is PareResultSuccess<T>;
}
