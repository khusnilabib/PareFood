/// Dashboard smoke test: the admin console shows the analytics dashboard.
library;

import 'package:app_pareadmin/src/presentation/admin_dashboard_page.dart';
import 'package:finance_feature/finance_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orders_feature/orders_feature.dart';
import 'package:pare_core/pare_core.dart';

void main() {
  testWidgets('shows the analytics dashboard with KPI labels', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersRepositoryProvider.overrideWithValue(_EmptyOrdersRepository()),
          financeRepositoryProvider.overrideWithValue(
            _EmptyFinanceRepository(),
          ),
        ],
        child: const MaterialApp(home: AdminDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsNWidgets(2));
    // KPI labels render.
    expect(find.text('Pesanan hari ini'), findsOneWidget);
    expect(find.text('GMV hari ini'), findsOneWidget);
    expect(find.text('Merchant aktif'), findsOneWidget);
    expect(find.text('Driver online'), findsOneWidget);
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

class _EmptyFinanceRepository implements FinanceRepository {
  @override
  Future<List<Settlement>> fetchSettlements({
    String? restaurantId,
    DateTime? from,
    DateTime? to,
  }) async => const [];

  @override
  Future<void> approveSettlements(List<String> settlementIds) async {}

  @override
  Future<List<DriverPayout>> fetchPayouts({
    String? driverId,
    DateTime? from,
    DateTime? to,
  }) async => const [];

  @override
  Future<ReconciliationReport> fetchReconciliation({
    required DateTime from,
    required DateTime to,
  }) async => ReconciliationReport(
    periodStart: from,
    periodEnd: to,
    grossOrderTotal: Money.fromRupiah(0),
    commissionCollected: Money.fromRupiah(0),
    driverFaresPaid: Money.fromRupiah(0),
    restaurantSettlements: Money.fromRupiah(0),
    codCollected: Money.fromRupiah(0),
    codRemitted: Money.fromRupiah(0),
    mismatchCount: 0,
  );

  @override
  Future<PlatformKpis> fetchKpis() async => PlatformKpis(
    ordersToday: 0,
    gmvToday: Money.fromRupiah(0),
    activeMerchants: 0,
    activeDrivers: 0,
    pendingSettlements: Money.fromRupiah(0),
    pendingPayouts: Money.fromRupiah(0),
  );
}
