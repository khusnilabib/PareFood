import 'package:dio/dio.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_data/pare_data.dart';
import 'package:test/test.dart';

DioException _error(DioExceptionType type, {int? statusCode, Object? data}) {
  final requestOptions = RequestOptions(path: '/api/v1/test');
  return DioException(
    requestOptions: requestOptions,
    type: type,
    response: statusCode == null
        ? null
        : Response<Object?>(
            requestOptions: requestOptions,
            statusCode: statusCode,
            data: data,
          ),
  );
}

void main() {
  group('mapDioException transport errors', () {
    test('timeouts map to PareTimeoutException', () {
      for (final type in <DioExceptionType>[
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(mapDioException(_error(type)), isA<PareTimeoutException>());
      }
    });

    test('connection, cancel and badCertificate map to network', () {
      expect(
        mapDioException(_error(DioExceptionType.connectionError)),
        isA<PareNetworkException>(),
      );
      expect(
        mapDioException(_error(DioExceptionType.cancel)),
        isA<PareNetworkException>(),
      );
      expect(
        mapDioException(_error(DioExceptionType.badCertificate)),
        isA<PareNetworkException>(),
      );
    });

    test('unknown maps to PareUnknownException', () {
      expect(
        mapDioException(_error(DioExceptionType.unknown)),
        isA<PareUnknownException>(),
      );
    });
  });

  group('mapDioException status codes', () {
    test('maps client errors to typed exceptions', () {
      final cases = <int, Matcher>{
        400: isA<PareValidationException>(),
        401: isA<PareAuthException>(),
        403: isA<PareForbiddenException>(),
        404: isA<PareNotFoundException>(),
        409: isA<PareConflictException>(),
        422: isA<PareBusinessRuleException>(),
        429: isA<PareBusinessRuleException>(),
      };
      cases.forEach((status, matcher) {
        expect(
          mapDioException(
            _error(DioExceptionType.badResponse, statusCode: status),
          ),
          matcher,
        );
      });
    });

    test('maps 5xx and unknown statuses', () {
      expect(
        mapDioException(_error(DioExceptionType.badResponse, statusCode: 500)),
        isA<PareServerException>(),
      );
      expect(
        mapDioException(_error(DioExceptionType.badResponse, statusCode: 503)),
        isA<PareServerException>(),
      );
      expect(
        mapDioException(_error(DioExceptionType.badResponse, statusCode: 418)),
        isA<PareUnknownException>(),
      );
    });

    test('extracts server message from JSON body', () {
      final error = mapDioException(
        _error(
          DioExceptionType.badResponse,
          statusCode: 422,
          data: <String, dynamic>{'message': 'Stock insufficient'},
        ),
      );
      expect(error.message, 'Stock insufficient');
    });

    test('extracts plain string body as message', () {
      final error = mapDioException(
        _error(
          DioExceptionType.badResponse,
          statusCode: 400,
          data: 'bad request body',
        ),
      );
      expect(error.message, 'bad request body');
    });
  });
}
