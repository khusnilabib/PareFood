import 'package:pare_util/pare_util.dart';
import 'package:test/test.dart';

void main() {
  group('formatIdr', () {
    test('formats thousands with dot separators and no decimals', () {
      expect(formatIdr(BigInt.from(85000)), 'Rp 85.000');
      expect(formatIdr(BigInt.from(1000000)), 'Rp 1.000.000');
      expect(formatIdr(BigInt.from(500)), 'Rp 500');
      expect(formatIdr(BigInt.zero), 'Rp 0');
    });

    test('formats negative amounts', () {
      expect(formatIdr(BigInt.from(-5000)), 'Rp -5.000');
    });
  });

  group('date/time formatters', () {
    test('formats date as dd MMM yyyy in Indonesian', () {
      expect(formatDateIndonesian(DateTime(2026, 8, 6)), '06 Agu 2026');
    });

    test('formats 24h time', () {
      expect(formatTime24(DateTime(2026, 8, 6, 19, 5)), '19:05');
      expect(formatTime24(DateTime(2026, 8, 6, 9, 30)), '09:30');
    });

    test('formats relative time in Indonesian', () {
      final now = DateTime(2026, 8, 6, 12, 0);
      expect(
        relativeTimeIndonesian(
          now.subtract(const Duration(seconds: 20)),
          now: now,
        ),
        'baru saja',
      );
      expect(
        relativeTimeIndonesian(
          now.subtract(const Duration(minutes: 5)),
          now: now,
        ),
        '5 mnt lalu',
      );
      expect(
        relativeTimeIndonesian(
          now.subtract(const Duration(hours: 3)),
          now: now,
        ),
        '3 jam lalu',
      );
      expect(
        relativeTimeIndonesian(now.subtract(const Duration(days: 2)), now: now),
        '2 hari lalu',
      );
    });

    test('formats ETA', () {
      expect(formatEta(const Duration(minutes: 25)), '±25 mnt');
    });
  });

  group('validators', () {
    test('required rejects empty values', () {
      expect(requiredValidator(null), isNotNull);
      expect(requiredValidator(''), isNotNull);
      expect(requiredValidator('   '), isNotNull);
      expect(requiredValidator('address'), isNull);
    });

    test('email accepts valid and rejects invalid', () {
      expect(emailValidator('user@example.com'), isNull);
      expect(emailValidator('user+tag@sub.example.co'), isNull);
      expect(emailValidator('not-an-email'), isNotNull);
      expect(emailValidator('a@b'), isNotNull);
    });

    test('phone accepts Indonesian formats', () {
      expect(phoneValidator('081234567890'), isNull);
      expect(phoneValidator('+6281234567890'), isNull);
      expect(phoneValidator('0812-3456-7890'), isNull);
      expect(phoneValidator('12345'), isNotNull);
    });

    test('otp accepts exactly 6 digits', () {
      expect(otpValidator('123456'), isNull);
      expect(otpValidator(' 123456 '), isNull);
      expect(otpValidator(''), isNull); // optional; pair with requiredValidator
      expect(otpValidator('12345'), isNotNull);
      expect(otpValidator('1234567'), isNotNull);
      expect(otpValidator('12a456'), isNotNull);
    });

    test('min length enforces threshold', () {
      expect(minLengthValidator('abc'), isNotNull);
      expect(minLengthValidator('abcdef', minLength: 6), isNull);
    });
  });

  group('extensions', () {
    test('normalizedForComparison trims and lowercases', () {
      expect('  Jl. Merdeka '.normalizedForComparison, 'jl. merdeka');
    });

    test('digitsOnly strips non-digits', () {
      expect('Rp 85.000'.digitsOnly, '85000');
    });

    test('ceilToMultiple rounds up', () {
      expect(7.ceilToMultiple(5), 10);
      expect(10.ceilToMultiple(5), 10);
      expect(0.ceilToMultiple(5), 0);
    });

    test('clampTo bounds values', () {
      expect(2.clampTo(0, 1), 1);
      expect((-1).clampTo(0, 10), 0);
      expect(5.clampTo(0, 10), 5);
    });

    test('inMinutesCeil rounds up', () {
      expect(const Duration(minutes: 1, seconds: 1).inMinutesCeil, 2);
      expect(const Duration(minutes: 2).inMinutesCeil, 2);
    });
  });
}
