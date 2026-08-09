/// Dio client factory with PareFood defaults (PF-DOC-11 §3.5).
///
/// Produces a configured [Dio]: 15s timeouts, JSON headers, optional bearer
/// token injection and a bounded retry for idempotent GET/HEAD requests.
/// Request logging is routed through an injected [log] callback instead of
/// `print`, so apps can wire their own logger (avoid_print is an error).
library;

import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// Builds the shared HTTP client for one app.
///
/// [tokenProvider] returns the current bearer token (or `null` when signed
/// out). [log] receives one line per request in non-production environments;
/// pass `null` to disable logging.
Dio buildDio({
  required AppConfig config,
  Future<String?> Function()? tokenProvider,
  void Function(String message)? log,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: const <String, String>{'accept': 'application/json'},
    ),
  );

  dio.interceptors.add(_AuthTokenInterceptor(tokenProvider));

  if (config.environment != PareEnvironment.production) {
    dio.interceptors.add(_DevLogInterceptor(log));
  }

  dio.interceptors.add(_RetryInterceptor(dio));

  return dio;
}

/// Injects `Authorization: Bearer <token>` when a token is available.
class _AuthTokenInterceptor extends Interceptor {
  _AuthTokenInterceptor(this._tokenProvider);

  final Future<String?> Function()? _tokenProvider;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _tokenProvider?.call();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } on Object {
      // A failing token provider must never block the request; the server will
      // reject unauthenticated calls instead.
    }
    return handler.next(options);
  }
}

/// One-line request logger for dev/staging. Never logs response bodies.
class _DevLogInterceptor extends Interceptor {
  _DevLogInterceptor(this._log);

  final void Function(String message)? _log;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    _log?.call('→ ${options.method} ${options.uri}');
    return handler.next(options);
  }

  @override
  void onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) {
    _log?.call('← ${response.statusCode} ${response.requestOptions.uri}');
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log?.call('✕ ${err.type.name} ${err.requestOptions.uri}');
    return handler.next(err);
  }
}

/// Retries idempotent GET/HEAD requests that failed to be delivered or timed
/// out. Never retries POST/PATCH/PUT/DELETE and never retries HTTP error
/// responses, so payments and state-changing calls are not duplicated.
class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio);

  final Dio _dio;

  static const int _maxAttempts = 2;
  static const List<String> _idempotentMethods = <String>['GET', 'HEAD'];

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_isRetryable(err)) {
      return handler.next(err);
    }

    final attempt = err.requestOptions.extra['_pare_attempt'] as int? ?? 0;
    if (attempt >= _maxAttempts) {
      return handler.next(err);
    }

    err.requestOptions.extra['_pare_attempt'] = attempt + 1;
    await Future<void>.delayed(Duration(milliseconds: 200 * (attempt + 1)));

    try {
      final response = await _dio.fetch<Object?>(err.requestOptions);
      return handler.resolve(response);
    } on Object {
      return handler.next(err);
    }
  }

  bool _isRetryable(DioException err) {
    if (!_idempotentMethods.contains(err.requestOptions.method)) {
      return false;
    }
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return true;
      case DioExceptionType.badResponse:
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
        return false;
    }
  }
}
