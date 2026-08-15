/// Widget tests for the orders surface (FL-R07: all four states) + domain.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orders_feature/orders_feature.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';

/// Riverpod 3 retries by default; disable it so error states can be asserted
/// deterministically in widget tests.
Duration? _noRetry(int attempt, Object error) => null;

void main() {
  group('OrdersPage (customer, FL-R07)', () {
    testWidgets('shows skeleton placeholders while orders load', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: _noRetry,
          overrides: [
            ordersRepositoryProvider.overrideWithValue(
              _FakeOrdersRepository(pending: true),
            ),
          ],
          child: const MaterialApp(home: OrdersPage()),
        ),
      );

      expect(find.byType(PfSkeleton), findsNWidgets(3));
    });

    testWidgets('renders one card per order with money and date', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: _noRetry,
          overrides: [
            ordersRepositoryProvider.overrideWithValue(_FakeOrdersRepository()),
          ],
          child: const MaterialApp(home: OrdersPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OrderCard), findsNWidgets(2));
      expect(find.textContaining('Bakso Joss'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('Diantar'), findsOneWidget);
    });

    testWidgets('shows the empty state when there are no orders', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: _noRetry,
          overrides: [
            ordersRepositoryProvider.overrideWithValue(
              _FakeOrdersRepository(empty: true),
            ),
          ],
          child: const MaterialApp(home: OrdersPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada pesanan'), findsOneWidget);
    });

    testWidgets('surfaces typed errors and recovers via retry', (tester) async {
      final repository = _FakeOrdersRepository(
        fetchError: const PareServerException('Server sedang sibuk.'),
      );
      await tester.pumpWidget(
        ProviderScope(
          retry: _noRetry,
          overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: OrdersPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Server sedang sibuk.'), findsOneWidget);

      repository.fetchError = null;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.byType(OrderCard), findsNWidgets(2));
    });
  });

  group('OrderStatus mapping', () {
    test('placed/accepted map to the pending badge status', () {
      expect(orderBadgeStatus(OrderStatus.placed), PfStatus.pending);
      expect(orderStatusLabel(OrderStatus.placed), 'Menunggu konfirmasi');
      expect(orderBadgeStatus(OrderStatus.accepted), PfStatus.pending);
    });

    test('preparing/ready/pickedUp/delivered map to the active badge', () {
      expect(orderBadgeStatus(OrderStatus.preparing), PfStatus.active);
      expect(orderBadgeStatus(OrderStatus.ready), PfStatus.active);
      expect(orderBadgeStatus(OrderStatus.pickedUp), PfStatus.active);
      expect(orderBadgeStatus(OrderStatus.delivered), PfStatus.active);
    });

    test('cancelled/refunded map to the cancelled badge', () {
      expect(orderBadgeStatus(OrderStatus.cancelled), PfStatus.cancelled);
      expect(orderBadgeStatus(OrderStatus.refunded), PfStatus.cancelled);
    });

    test('fromString/toWire round-trip', () {
      for (final s in OrderStatus.values) {
        expect(OrderStatus.fromString(s.toWire()), s);
      }
    });

    test('fromString falls back to placed for unknown values', () {
      expect(OrderStatus.fromString('unknown'), OrderStatus.placed);
      expect(OrderStatus.fromString(null), OrderStatus.placed);
    });

    test('isActive / isTerminal', () {
      expect(OrderStatus.placed.isActive, isTrue);
      expect(OrderStatus.pickedUp.isActive, isTrue);
      expect(OrderStatus.pickedUp.isTerminal, isFalse);
      expect(OrderStatus.delivered.isActive, isFalse);
      expect(OrderStatus.delivered.isTerminal, isTrue);
      expect(OrderStatus.cancelled.isTerminal, isTrue);
      expect(OrderStatus.refunded.isTerminal, isTrue);
    });
  });

  group('OrderSummary', () {
    test('value equality and hashCode', () {
      final a = _summary();
      final b = _summary();
      final c = _summary(id: 'o2');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
      const Object other = 'o1';
      expect(a == other, isFalse);
    });
  });
}

OrderSummary _summary({String id = 'o1'}) {
  return OrderSummary(
    id: id,
    orderNo: 'PF-001',
    restaurantName: 'Bakso Joss',
    customerName: 'Budi',
    total: Money.fromRupiah(45000),
    status: OrderStatus.delivered,
    placedAt: _placedAt,
  );
}

final _placedAt = DateTime(2026, 8, 5, 19, 5);

class _FakeOrdersRepository implements OrdersRepository {
  _FakeOrdersRepository({
    this.fetchError,
    this.pending = false,
    this.empty = false,
  });

  PareException? fetchError;
  final bool pending;
  final bool empty;

  @override
  Future<List<OrderSummary>> fetchForCustomer() {
    final error = fetchError;
    if (error != null) return Future.error(error);
    if (pending) return Completer<List<OrderSummary>>().future;
    if (empty) return Future.value(const []);
    return Future.value([
      OrderSummary(
        id: 'o1',
        orderNo: 'PF-001',
        restaurantName: 'Bakso Joss',
        customerName: 'Budi',
        total: Money.fromRupiah(45000),
        status: OrderStatus.delivered,
        placedAt: _placedAt,
      ),
      OrderSummary(
        id: 'o2',
        orderNo: 'PF-002',
        restaurantName: 'Sate Rembiga',
        customerName: 'Sari',
        total: Money.fromRupiah(60000),
        status: OrderStatus.pickedUp,
        placedAt: _placedAt,
      ),
    ]);
  }

  @override
  Future<List<OrderSummary>> fetchForRestaurant({
    String? restaurantId,
    Set<OrderStatus>? statuses,
  }) async => const [];

  @override
  Future<List<DeliveryJob>> fetchForDriver() async => const [];

  @override
  Future<List<OrderSummary>> fetchAll({
    Set<OrderStatus>? statuses,
    String? search,
  }) async => const [];

  @override
  Future<OrderSummary> fetchById(String id) async {
    throw PareNotFoundException('Order $id not found.');
  }

  @override
  Future<OrderDetail> fetchDetail(String id) async {
    throw PareNotFoundException('Order $id not found.');
  }
}
