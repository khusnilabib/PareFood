/// Error taxonomy shared by every PareFood package and app (PF-DOC-11 §3.5).
///
/// A [PareException] is thrown by repositories/use cases and mapped to a
/// human-readable message + action by the UI layer (FL-R07).
library;

import 'package:meta/meta.dart';

/// Machine-readable error categories. The UI maps each category to a message,
/// icon and retry strategy.
enum PareErrorCode {
  network,
  timeout,
  auth,
  validation,
  notFound,
  forbidden,
  conflict,
  businessRule,
  server,
  unknown,
}

/// Base class of the PareFood exception hierarchy.
///
/// Subclasses provide their own [code] and [scope]; [message] and [cause] are
/// forwarded from the constructor.
@immutable
abstract class PareException implements Exception {
  const PareException(this.message, {this.cause});

  /// Stable category used for logging, retry decisions and UI mapping.
  PareErrorCode get code;

  /// Human-readable, localised-at-UI message. Developer-facing text may be
  /// English; UI strings are localised in ARB (PF-DOC-23 §3.6).
  final String message;

  /// Underlying error, when available. Never contains PII or payment data
  /// (PF-DOC-19 §3.4).
  final Object? cause;

  /// A stable, scannable identifier for logs, e.g. `orders/not_found`.
  String get scope;

  @override
  String toString() => 'PareException($scope: $message)';
}

/// The request could not be delivered (offline, DNS, connection reset).
class PareNetworkException extends PareException {
  const PareNetworkException([String? message, Object? cause])
    : super(message ?? 'Network error. Please retry.', cause: cause);

  @override
  PareErrorCode get code => PareErrorCode.network;

  @override
  String get scope => 'network/request_failed';
}

/// The request timed out before completing.
class PareTimeoutException extends PareException {
  const PareTimeoutException([String? message, Object? cause])
    : super(message ?? 'The request timed out. Please retry.', cause: cause);

  @override
  PareErrorCode get code => PareErrorCode.timeout;

  @override
  String get scope => 'network/timeout';
}

/// Authentication failed or the session is missing/expired.
class PareAuthException extends PareException {
  const PareAuthException([String? message, Object? cause])
    : super(
        message ?? 'Your session has expired. Please sign in again.',
        cause: cause,
      );

  @override
  PareErrorCode get code => PareErrorCode.auth;

  @override
  String get scope => 'auth/failed';
}

/// The submitted payload violates validation rules.
class PareValidationException extends PareException {
  const PareValidationException([String? message, Object? cause])
    : super(message ?? 'Please check the information provided.', cause: cause);

  @override
  PareErrorCode get code => PareErrorCode.validation;

  @override
  String get scope => 'validation/failed';
}

/// The requested resource does not exist.
class PareNotFoundException extends PareException {
  const PareNotFoundException([String? message, Object? cause])
    : super(message ?? 'The item could not be found.', cause: cause);

  @override
  PareErrorCode get code => PareErrorCode.notFound;

  @override
  String get scope => 'resource/not_found';
}

/// The user is authenticated but lacks permission (RLS/403).
class PareForbiddenException extends PareException {
  const PareForbiddenException([String? message, Object? cause])
    : super(message ?? 'You do not have permission to do this.', cause: cause);

  @override
  PareErrorCode get code => PareErrorCode.forbidden;

  @override
  String get scope => 'auth/forbidden';
}

/// The operation conflicts with the current state (HTTP 409).
class PareConflictException extends PareException {
  const PareConflictException([String? message, Object? cause])
    : super(
        message ?? 'This action conflicts with the current state.',
        cause: cause,
      );

  @override
  PareErrorCode get code => PareErrorCode.conflict;

  @override
  String get scope => 'resource/conflict';
}

/// A backend business rule rejected the operation (PF-DOC-18).
class PareBusinessRuleException extends PareException {
  const PareBusinessRuleException([String? message, Object? cause])
    : super(message ?? 'This action is not allowed.', cause: cause);

  @override
  PareErrorCode get code => PareErrorCode.businessRule;

  @override
  String get scope => 'business_rule/rejected';
}

/// The server returned an unexpected error (5xx, decode failure).
class PareServerException extends PareException {
  const PareServerException([String? message, Object? cause])
    : super(
        message ?? 'Something went wrong on our side. Please retry.',
        cause: cause,
      );

  @override
  PareErrorCode get code => PareErrorCode.server;

  @override
  String get scope => 'server/error';
}

/// Fallback for anything not covered above. Prefer a typed subtype.
class PareUnknownException extends PareException {
  const PareUnknownException([String? message, Object? cause])
    : super(message ?? 'Something went wrong.', cause: cause);

  @override
  PareErrorCode get code => PareErrorCode.unknown;

  @override
  String get scope => 'unknown/error';
}
