import 'package:pare_core/pare_core.dart';
import 'package:test/test.dart';

void main() {
  group('Money', () {
    test('constructs from rupiah and stores exact amount', () {
      final m = Money.fromRupiah(85000);
      expect(m.amount, BigInt.from(85000));
      expect(m.isZero, isFalse);
    });

    test('parses integer and string JSON', () {
      expect(Money.fromJson(85000).amount, BigInt.from(85000));
      expect(Money.fromJson('85000').amount, BigInt.from(85000));
    });

    test('serialises to integer string', () {
      expect(Money.fromRupiah(85000).toJson, '85000');
    });

    test('adds and subtracts', () {
      expect(
        (Money.fromRupiah(5000) + Money.fromRupiah(2500)).amount,
        BigInt.from(7500),
      );
      expect(
        (Money.fromRupiah(5000) - Money.fromRupiah(2000)).amount,
        BigInt.from(3000),
      );
    });

    test('throws on negative result', () {
      expect(
        () => Money.fromRupiah(1000) - Money.fromRupiah(2000),
        throwsArgumentError,
      );
    });

    test('rejects negative construction', () {
      expect(() => Money(BigInt.from(-1)), throwsA(isA<AssertionError>()));
    });

    test('multiplies by integer factor', () {
      expect((Money.fromRupiah(2000) * 3).amount, BigInt.from(6000));
    });

    test('compares values', () {
      final small = Money.fromRupiah(100);
      final big = Money.fromRupiah(900);
      expect(small < big, isTrue);
      expect(big > small, isTrue);
      expect(small <= small, isTrue);
      expect(big >= small, isTrue);
      expect(small.compareTo(big), lessThan(0));
    });

    test('equality is value-based', () {
      expect(Money.fromRupiah(5000), Money.fromRupiah(5000));
      expect(Money.fromRupiah(5000).hashCode, Money.fromRupiah(5000).hashCode);
    });

    test('rejects unparseable JSON', () {
      expect(() => Money.fromJson(3.14), throwsFormatException);
    });

    test('toString renders the amount', () {
      expect(Money.fromRupiah(85000).toString(), 'Money(85000)');
    });
  });

  group('PareResult', () {
    test('success holds data and isSuccess', () {
      const result = PareResult<int>.success(42);
      expect(result.isSuccess, isTrue);
      expect(result.dataOrThrow, 42);
    });

    test('failure throws its error on dataOrThrow', () {
      const error = PareNotFoundException('missing');
      const result = PareResult<int>.failure(error);
      expect(result.isSuccess, isFalse);
      expect(() => result.dataOrThrow, throwsA(isA<PareNotFoundException>()));
    });

    test('switch matches both variants', () {
      const ok = PareResult<int>.success(1);
      final label = switch (ok) {
        PareResultSuccess<int>() => 'success',
        PareResultFailure<int>() => 'failure',
      };
      expect(label, 'success');
    });
  });

  group('PareException hierarchy', () {
    test('carries code, message and scope', () {
      const error = PareNetworkException('offline');
      expect(error.code, PareErrorCode.network);
      expect(error.message, 'offline');
      expect(error.scope, 'network/request_failed');
    });

    test('subtypes map to correct codes', () {
      expect(const PareAuthException('x').code, PareErrorCode.auth);
      expect(const PareNotFoundException('x').code, PareErrorCode.notFound);
      expect(const PareForbiddenException('x').code, PareErrorCode.forbidden);
      expect(
        const PareBusinessRuleException('x').code,
        PareErrorCode.businessRule,
      );
      expect(const PareServerException('x').code, PareErrorCode.server);
      expect(const PareTimeoutException('x').code, PareErrorCode.timeout);
    });

    test('subtypes provide default messages and scopes', () {
      final cases = <PareException, String>{
        const PareNetworkException(): 'network/request_failed',
        const PareTimeoutException(): 'network/timeout',
        const PareAuthException(): 'auth/failed',
        const PareValidationException(): 'validation/failed',
        const PareNotFoundException(): 'resource/not_found',
        const PareForbiddenException(): 'auth/forbidden',
        const PareConflictException(): 'resource/conflict',
        const PareBusinessRuleException(): 'business_rule/rejected',
        const PareServerException(): 'server/error',
        const PareUnknownException(): 'unknown/error',
      };
      for (final entry in cases.entries) {
        expect(entry.key.scope, entry.value);
        expect(entry.key.message, isNotEmpty);
      }
      expect(const PareValidationException().code, PareErrorCode.validation);
      expect(const PareConflictException().code, PareErrorCode.conflict);
      expect(const PareUnknownException().code, PareErrorCode.unknown);
    });

    test('carries the cause and renders toString', () {
      final cause = StateError('boom');
      final error = PareNetworkException('offline', cause);
      expect(error.cause, same(cause));
      expect(
        error.toString(),
        'PareException(network/request_failed: offline)',
      );
    });
  });
}
