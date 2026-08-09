import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:pare_data/pare_data.dart';
import 'package:test/test.dart';

AppConfig _config({PareEnvironment env = PareEnvironment.dev}) => AppConfig(
  environment: env,
  supabaseUrl: 'https://demo.supabase.co',
  supabaseAnonKey: 'anon',
  apiBaseUrl: 'https://api.parefood.test',
);

/// Adapter that answers every request with `200 {"ok":true}` without
/// touching the network, so the full interceptor chain (request and
/// response handlers) runs.
class _FakeAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"ok":true}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('buildDio', () {
    test('sets base URL and timeouts from config', () {
      final dio = buildDio(config: _config());
      expect(dio.options.baseUrl, 'https://api.parefood.test');
      expect(dio.options.connectTimeout, const Duration(seconds: 15));
      expect(dio.options.receiveTimeout, const Duration(seconds: 15));
      expect(dio.options.sendTimeout, const Duration(seconds: 15));
      expect(dio.options.headers['accept'], 'application/json');
    });

    test('injects bearer token from tokenProvider', () async {
      final dio = buildDio(
        config: _config(),
        tokenProvider: () async => 'tok123',
      );
      String? authorization;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            authorization = options.headers['Authorization'] as String?;
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                statusCode: 200,
                data: null,
              ),
            );
          },
        ),
      );

      final response = await dio.get<Object?>('/health');

      expect(response.statusCode, 200);
      expect(authorization, 'Bearer tok123');
    });

    test('omits Authorization when no token provider', () async {
      final dio = buildDio(config: _config());
      String? authorization = 'sentinel';
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            authorization = options.headers['Authorization'] as String?;
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                statusCode: 200,
                data: null,
              ),
            );
          },
        ),
      );

      final response = await dio.get<Object?>('/health');

      expect(response.statusCode, 200);
      expect(authorization, isNull);
    });

    test('retries idempotent GET failures twice then succeeds', () async {
      final dio = buildDio(config: _config());
      var attempts = 0;
      dio.interceptors.insert(
        0,
        InterceptorsWrapper(
          onRequest: (options, handler) {
            attempts++;
            if (attempts <= 2) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                  message: 'simulated failure',
                ),
                true,
              );
            } else {
              handler.resolve(
                Response<Object?>(
                  requestOptions: options,
                  statusCode: 200,
                  data: 'ok',
                ),
              );
            }
          },
        ),
      );

      final response = await dio.get<Object?>('/health');

      expect(response.statusCode, 200);
      expect(attempts, 3);
    });

    test('does not retry non-idempotent methods', () async {
      final dio = buildDio(config: _config());
      var attempts = 0;
      dio.interceptors.insert(
        0,
        InterceptorsWrapper(
          onRequest: (options, handler) {
            attempts++;
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                message: 'simulated failure',
              ),
              true,
            );
          },
        ),
      );

      await expectLater(
        dio.post<Object?>('/orders'),
        throwsA(isA<DioException>()),
      );

      expect(attempts, 1);
    });

    test('gives up after the retry budget is exhausted', () async {
      final dio = buildDio(config: _config());
      var attempts = 0;
      dio.interceptors.insert(
        0,
        InterceptorsWrapper(
          onRequest: (options, handler) {
            attempts++;
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.unknown,
                message: 'simulated failure',
              ),
              true,
            );
          },
        ),
      );

      await expectLater(
        dio.get<Object?>('/health'),
        throwsA(isA<DioException>()),
      );

      // Initial attempt + two retries.
      expect(attempts, 3);
    });

    test('does not retry HTTP error responses', () async {
      final dio = buildDio(config: _config());
      var attempts = 0;
      dio.interceptors.insert(
        0,
        InterceptorsWrapper(
          onRequest: (options, handler) {
            attempts++;
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<Object?>(
                  requestOptions: options,
                  statusCode: 500,
                ),
                message: 'server error',
              ),
              true,
            );
          },
        ),
      );

      await expectLater(
        dio.get<Object?>('/health'),
        throwsA(isA<DioException>()),
      );

      expect(attempts, 1);
    });

    test('does not retry cancelled or bad-certificate requests', () async {
      for (final type in [
        DioExceptionType.cancel,
        DioExceptionType.badCertificate,
      ]) {
        final dio = buildDio(config: _config());
        var attempts = 0;
        dio.interceptors.insert(
          0,
          InterceptorsWrapper(
            onRequest: (options, handler) {
              attempts++;
              handler.reject(
                DioException(requestOptions: options, type: type),
                true,
              );
            },
          ),
        );

        await expectLater(
          dio.get<Object?>('/health'),
          throwsA(isA<DioException>()),
        );

        expect(attempts, 1, reason: '$type must not be retried');
      }
    });
  });

  group('dev logging', () {
    test('logs request and response lines in dev', () async {
      final lines = <String>[];
      final dio = buildDio(config: _config(), log: lines.add);
      dio.httpClientAdapter = _FakeAdapter();

      await dio.get<Object?>('/health');

      expect(lines, contains('→ GET https://api.parefood.test/health'));
      expect(lines.where((l) => l.startsWith('← 200')), isNotEmpty);
    });

    test('logs errors in staging', () async {
      final lines = <String>[];
      final dio = buildDio(
        config: _config(env: PareEnvironment.staging),
        log: lines.add,
      );
      dio.interceptors.insert(
        0,
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<Object?>(
                  requestOptions: options,
                  statusCode: 500,
                ),
              ),
              true,
            );
          },
        ),
      );

      await expectLater(
        dio.get<Object?>('/health'),
        throwsA(isA<DioException>()),
      );

      expect(lines.where((l) => l.startsWith('✕')), isNotEmpty);
    });

    test('production builds skip the log interceptor', () async {
      final lines = <String>[];
      final dio = buildDio(
        config: _config(env: PareEnvironment.production),
        log: lines.add,
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                statusCode: 200,
                data: null,
              ),
            );
          },
        ),
      );

      await dio.get<Object?>('/health');

      expect(lines, isEmpty);
    });
  });
}
