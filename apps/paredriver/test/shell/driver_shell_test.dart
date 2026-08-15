/// Shell smoke test: the driver shell hosts the job feed and profile tabs.
library;

import 'package:app_paredriver/src/shell/driver_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orders_feature/orders_feature.dart';
import 'package:pare_core/pare_core.dart';
import 'package:profile_feature/profile_feature.dart';

import '../fakes.dart';

void main() {
  testWidgets('shows Pekerjaan and Akun tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersRepositoryProvider.overrideWithValue(_EmptyOrdersRepository()),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
        ],
        child: const MaterialApp(home: DriverShell()),
      ),
    );
    await tester.pumpAndSettle();

    // "Pekerjaan" appears as both the tab label and the AppBar title.
    expect(find.text('Pekerjaan'), findsNWidgets(2));
    expect(find.text('Akun'), findsOneWidget);

    // Default tab is Pekerjaan → empty jobs state.
    expect(find.text('Belum ada pekerjaan'), findsOneWidget);

    // Switch to Akun tab.
    await tester.tap(find.text('Akun'));
    await tester.pumpAndSettle();
    expect(find.text('Budi Santoso'), findsOneWidget);
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
