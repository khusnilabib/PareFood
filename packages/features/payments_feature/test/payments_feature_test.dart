import 'package:flutter_test/flutter_test.dart';
import 'package:pare_core/pare_core.dart';
import 'package:payments_feature/payments_feature.dart';

void main() {
  group('CreateCharge', () {
    test('rejects a missing idempotency key (NFR-021)', () {
      final useCase = CreateCharge(_FakePaymentsRepository());
      expect(
        () => useCase(
          orderId: 'o1',
          amount: Money.fromRupiah(75000),
          method: PaymentMethod.ewallet,
        ),
        throwsArgumentError,
      );
    });

    test('forwards a valid charge to the repository', () async {
      final useCase = CreateCharge(_FakePaymentsRepository());
      final result = await useCase(
        orderId: 'o1',
        amount: Money.fromRupiah(75000),
        method: PaymentMethod.ewallet,
        idempotencyKey: 'key-1',
      );
      expect(result.isSuccess, isTrue);
    });
  });
}

class _FakePaymentsRepository implements PaymentsRepository {
  @override
  Future<PaymentResult> createCharge({
    required String orderId,
    required String idempotencyKey,
    required Money amount,
    required PaymentMethod method,
  }) async {
    return const PaymentResult(
      paymentId: 'pay-1',
      status: PaymentStatus.success,
    );
  }

  @override
  Future<List<PaymentMethod>> availableMethods() async => PaymentMethod.values;

  @override
  Future<PromoValidation> validatePromo({
    required String code,
    required Money subtotal,
  }) async => PromoValidation.none;

  @override
  Future<PaymentIntent?> fetchIntentForOrder(String orderId) async => null;
}
