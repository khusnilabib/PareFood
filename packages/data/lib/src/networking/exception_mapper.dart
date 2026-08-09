/// Maps [DioException] to the typed `pare_core` exception hierarchy
/// (PF-DOC-11 §3.5). Pure function, unit-tested.
library;

import 'package:dio/dio.dart';
import 'package:pare_core/pare_core.dart';

/// Returns a typed [PareException] for [error].
PareException mapDioException(DioException error, {String scope = 'api'}) {
  final message = _readServerMessage(error);

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return PareTimeoutException(
        message ?? 'The request timed out. Please retry.',
        error,
      );
    case DioExceptionType.connectionError:
      return PareNetworkException(
        message ?? 'Network error. Please retry.',
        error,
      );
    case DioExceptionType.cancel:
      return PareNetworkException('Request cancelled.', error);
    case DioExceptionType.badResponse:
      return _mapStatus(error, message: message, scope: scope);
    case DioExceptionType.badCertificate:
      return PareNetworkException(
        'A secure connection could not be established.',
        error,
      );
    case DioExceptionType.unknown:
      return PareUnknownException(message ?? 'Something went wrong.', error);
  }
}

PareException _mapStatus(
  DioException error, {
  required String? message,
  required String scope,
}) {
  final status = error.response?.statusCode;
  if (status == 400) {
    return PareValidationException(
      message ?? 'Please check the information provided.',
      error,
    );
  }
  if (status == 401) {
    return PareAuthException(
      'Your session has expired. Please sign in again.',
      error,
    );
  }
  if (status == 403) {
    return PareForbiddenException(
      'You do not have permission to do this.',
      error,
    );
  }
  if (status == 404) {
    return PareNotFoundException('The item could not be found.', error);
  }
  if (status == 409) {
    return PareConflictException(
      'This action conflicts with the current state.',
      error,
    );
  }
  if (status == 422) {
    return PareBusinessRuleException(
      message ?? 'This action is not allowed.',
      error,
    );
  }
  if (status == 429) {
    return PareBusinessRuleException(
      'Too many requests. Please try again later.',
      error,
    );
  }
  if (status != null && status >= 500) {
    return PareServerException(
      'Something went wrong on our side. Please retry.',
      error,
    );
  }
  return PareUnknownException('Unexpected server response ($status).', error);
}

/// Extracts a developer-facing message from common Supabase/Dio error bodies.
String? _readServerMessage(DioException error) {
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    final msg = data['message'] ?? data['error'];
    if (msg is String && msg.isNotEmpty) {
      return msg;
    }
  }
  if (data is String && data.isNotEmpty) {
    return data;
  }
  return null;
}
