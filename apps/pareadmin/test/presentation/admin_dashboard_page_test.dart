/// Dashboard smoke test: the admin console shows the order board.
library;

import 'package:app_pareadmin/src/presentation/admin_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orders_feature/orders_feature.dart';
import 'package:pare_core/pare_core.dart';

void main() {
  testWidgets('shows the order board with the empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersRepositoryProvider.overrideWithValue(_EmptyOrdersRepository()),
        ],
        child: const MaterialApp(home: AdminDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Papan Pesanan'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    // Empty orders → empty state.
    expect(find.text('Tidak ada pesanan'), findsOneWidget);
  });
}

class _EmptyOrdersRepository implements OrdersRepository {
  @override
  Future<List<OrderSummary>> fetchForCustomer() async => const [];
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
