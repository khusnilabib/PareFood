/// Widget tests for the payments surface (FL-R07: all four states).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pare_core/pare_core.dart';
import 'package:payments_feature/payments_feature.dart';

/// Riverpod 3 retries by default; disable it so error states can be asserted
/// deterministically in widget tests.
Duration? _noRetry(int attempt, Object error) => null;

void main() {
  group('paymentMethodsProvider', () {
    test('surfaces repository methods', () async {
      final container = ProviderContainer(
        retry: _noRetry,
        overrides: [
          paymentsRepositoryProvider.overrideWithValue(
            _FakePaymentsRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final methods = await container.read(paymentMethodsProvider.future);
      expect(methods, PaymentMethod.values);
    });

    test('throws when the repository is not overridden (FL-R04)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(paymentsRepositoryProvider),
        throwsA(
          predicate<Object>(
            (e) => e.toString().contains(
              'must be overridden in the composition root',
            ),
          ),
        ),
      );
    });
  });

  group('PaymentsPage (FL-R07)', () {
    testWidgets('shows a spinner while methods load', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: _noRetry,
          overrides: [
            paymentsRepositoryProvider.overrideWithValue(
              _FakePaymentsRepository(pending: true),
            ),
          ],
          child: const MaterialApp(home: PaymentsPage()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders one tile per payment method', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: _noRetry,
          overrides: [
            paymentsRepositoryProvider.overrideWithValue(
              _FakePaymentsRepository(),
            ),
          ],
          child: const MaterialApp(home: PaymentsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PaymentMethodTile), findsNWidgets(3));
      expect(find.textContaining('E-Wallet'), findsOneWidget);
      expect(find.textContaining('Kartu'), findsOneWidget);
      expect(find.textContaining('Bayar di Tempat'), findsOneWidget);
    });

    testWidgets('shows the empty state when no methods are offered', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: _noRetry,
          overrides: [
            paymentsRepositoryProvider.overrideWithValue(
              _FakePaymentsRepository(empty: true),
            ),
          ],
          child: const MaterialApp(home: PaymentsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada metode pembayaran'), findsOneWidget);
      expect(
        find.text('Metode pembayaran akan muncul di sini.'),
        findsOneWidget,
      );
    });

    testWidgets('surfaces typed errors and recovers via retry', (tester) async {
      final repository = _FakePaymentsRepository(
        methodsError: const PareNetworkException('Koneksi terputus.'),
      );
      await tester.pumpWidget(
        ProviderScope(
          retry: _noRetry,
          overrides: [paymentsRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: PaymentsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Koneksi terputus.'), findsOneWidget);
      expect(find.text('Gagal memuat metode pembayaran.'), findsNothing);

      repository.methodsError = null;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.byType(PaymentMethodTile), findsNWidgets(3));
    });
  });

  group('PaymentMethod', () {
    test('labels every method in Indonesian', () {
      expect(PaymentMethod.cashOnDelivery.label, 'Bayar di Tempat (COD)');
      expect(PaymentMethod.ewallet.label, 'E-Wallet (GoPay/OVO/DANA)');
      expect(PaymentMethod.card.label, 'Kartu Debit/Kredit');
    });

    test('fromString round-trips via toWire', () {
      for (final m in PaymentMethod.values) {
        expect(PaymentMethod.fromString(m.toWire()), m);
      }
    });

    test('fromString falls back to cashOnDelivery for unknown values', () {
      expect(PaymentMethod.fromString('qris'), PaymentMethod.cashOnDelivery);
      expect(PaymentMethod.fromString(null), PaymentMethod.cashOnDelivery);
    });
  });

  group('PaymentResult', () {
    test('isSuccess reflects the status', () {
      const success = PaymentResult(
        paymentId: 'pay-1',
        status: PaymentStatus.success,
      );
      const pending = PaymentResult(
        paymentId: 'pay-2',
        status: PaymentStatus.pending,
      );
      const failed = PaymentResult(
        paymentId: 'pay-3',
        status: PaymentStatus.failed,
      );

      expect(success.isSuccess, isTrue);
      expect(pending.isSuccess, isFalse);
      expect(failed.isSuccess, isFalse);
    });

    test('carries the authorized amount when reported', () {
      final result = PaymentResult(
        paymentId: 'pay-1',
        status: PaymentStatus.success,
        authorizedAmount: Money.fromRupiah(75000),
      );

      expect(result.authorizedAmount, Money.fromRupiah(75000));
    });
  });
}

class _FakePaymentsRepository implements PaymentsRepository {
  _FakePaymentsRepository({
    this.methodsError,
    this.pending = false,
    this.empty = false,
  });

  PareException? methodsError;
  final bool pending;
  final bool empty;

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
  Future<List<PaymentMethod>> availableMethods() {
    final error = methodsError;
    if (error != null) return Future.error(error);
    if (pending) return Completer<List<PaymentMethod>>().future;
    if (empty) return Future.value(const []);
    return Future.value(PaymentMethod.values);
  }

  @override
  Future<PromoValidation> validatePromo({
    required String code,
    required Money subtotal,
  }) async => PromoValidation.none;

  @override
  Future<PaymentIntent?> fetchIntentForOrder(String orderId) async => null;
}
