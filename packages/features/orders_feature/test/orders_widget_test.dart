/// Widget tests for the orders surface (FL-R07: all four states).
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
  group('OrdersPage (FL-R07)', () {
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
      expect(find.text('Bakso Joss'), findsOneWidget);
      expect(find.text('Rp 45.000 • 05 Agu 2026'), findsOneWidget);
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
      expect(find.text('Pesananmu akan muncul di sini.'), findsOneWidget);
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
      expect(find.text('Gagal memuat pesanan.'), findsNothing);

      repository.fetchError = null;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.byType(OrderCard), findsNWidgets(2));
    });
  });

  group('OrderCard status mapping', () {
    test('pending and confirmed map to the pending badge status', () {
      expect(OrderCard.badgeStatus(OrderStatus.pending), PfStatus.pending);
      expect(OrderCard.statusLabel(OrderStatus.pending), 'Menunggu');
      expect(OrderCard.badgeStatus(OrderStatus.confirmed), PfStatus.pending);
      expect(OrderCard.statusLabel(OrderStatus.confirmed), 'Dikonfirmasi');
    });

    test('delivering and delivered map to the active badge status', () {
      expect(OrderCard.badgeStatus(OrderStatus.delivering), PfStatus.active);
      expect(OrderCard.statusLabel(OrderStatus.delivering), 'Diantar');
      expect(OrderCard.badgeStatus(OrderStatus.delivered), PfStatus.active);
      expect(OrderCard.statusLabel(OrderStatus.delivered), 'Selesai');
    });
  });

  group('OrderSummary', () {
    test('value equality and hashCode', () {
      final a = OrderSummary(
        id: 'o1',
        restaurantName: 'Bakso Joss',
        total: Money.fromRupiah(45000),
        status: OrderStatus.delivered,
        placedAt: _placedAt,
      );
      final b = OrderSummary(
        id: 'o1',
        restaurantName: 'Bakso Joss',
        total: Money.fromRupiah(45000),
        status: OrderStatus.delivered,
        placedAt: _placedAt,
      );
      final c = OrderSummary(
        id: 'o2',
        restaurantName: 'Bakso Joss',
        total: Money.fromRupiah(45000),
        status: OrderStatus.delivered,
        placedAt: _placedAt,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
      expect(a == 'o1', isFalse);
    });
  });
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
  Future<List<OrderSummary>> fetchActive() {
    final error = fetchError;
    if (error != null) return Future.error(error);
    if (pending) return Completer<List<OrderSummary>>().future;
    if (empty) return Future.value(const []);
    return Future.value([
      OrderSummary(
        id: 'o1',
        restaurantName: 'Bakso Joss',
        total: Money.fromRupiah(45000),
        status: OrderStatus.delivered,
        placedAt: _placedAt,
      ),
      OrderSummary(
        id: 'o2',
        restaurantName: 'Sate Rembiga',
        total: Money.fromRupiah(60000),
        status: OrderStatus.delivering,
        placedAt: _placedAt,
      ),
    ]);
  }

  @override
  Future<OrderSummary> fetchById(String id) async {
    throw PareNotFoundException('Order $id not found.');
  }
}
