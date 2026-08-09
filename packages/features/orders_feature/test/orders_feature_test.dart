import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orders_feature/orders_feature.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';

void main() {
  group('activeOrdersProvider', () {
    test('surfaces repository orders', () async {
      final container = ProviderContainer(
        overrides: [
          ordersRepositoryProvider.overrideWithValue(_FakeOrdersRepository()),
        ],
      );
      addTearDown(container.dispose);

      final orders = await container.read(activeOrdersProvider.future);
      expect(orders, hasLength(1));
      expect(orders.single.restaurantName, 'Bakso Joss');
      expect(orders.single.status, OrderStatus.delivered);
    });
  });

  group('OrderCard status mapping', () {
    test('cancelled orders map to the cancelled badge status', () {
      expect(OrderCard.badgeStatus(OrderStatus.cancelled), PfStatus.cancelled);
      expect(OrderCard.statusLabel(OrderStatus.cancelled), 'Dibatalkan');
    });

    test('in-flight orders map to the active badge status', () {
      expect(OrderCard.badgeStatus(OrderStatus.preparing), PfStatus.active);
      expect(OrderCard.statusLabel(OrderStatus.preparing), 'Disiapkan');
    });
  });
}

class _FakeOrdersRepository implements OrdersRepository {
  @override
  Future<List<OrderSummary>> fetchActive() async {
    return [
      OrderSummary(
        id: 'o1',
        restaurantName: 'Bakso Joss',
        total: Money.fromRupiah(45000),
        status: OrderStatus.delivered,
        placedAt: DateTime(2026, 8, 5, 19, 5),
      ),
    ];
  }

  @override
  Future<OrderSummary> fetchById(String id) async {
    throw PareNotFoundException('Order $id not found.');
  }
}
