import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orders_feature/orders_feature.dart';
import 'package:pare_core/pare_core.dart';

void main() {
  group('customerOrdersProvider', () {
    test('surfaces repository orders', () async {
      final container = ProviderContainer(
        overrides: [
          ordersRepositoryProvider.overrideWithValue(_FakeOrdersRepository()),
        ],
      );
      addTearDown(container.dispose);

      final orders = await container.read(customerOrdersProvider.future);
      expect(orders, hasLength(1));
      expect(orders.single.restaurantName, 'Bakso Joss');
      expect(orders.single.status, OrderStatus.delivered);
    });

    test('surfaces typed errors', () async {
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          ordersRepositoryProvider.overrideWithValue(
            _FakeOrdersRepository(
              fetchError: const PareServerException('down'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Read the provider's future and expect it to complete with an error.
      // We keep the container alive until the future settles.
      final future = container.read(customerOrdersProvider.future);
      await expectLater(future, throwsA(isA<PareException>()));
    });
  });

  group('DeliveryStatus', () {
    test('fromString/toWire round-trip', () {
      for (final s in DeliveryStatus.values) {
        expect(DeliveryStatus.fromString(s.toWire()), s);
      }
    });

    test('fromString falls back to assigned for unknown', () {
      expect(DeliveryStatus.fromString('nope'), DeliveryStatus.assigned);
      expect(DeliveryStatus.fromString(null), DeliveryStatus.assigned);
    });
  });
}

class _FakeOrdersRepository implements OrdersRepository {
  _FakeOrdersRepository({this.fetchError});

  final PareException? fetchError;

  @override
  Future<List<OrderSummary>> fetchForCustomer() {
    final error = fetchError;
    if (error != null) return Future.error(error);
    return Future.value([
      OrderSummary(
        id: 'o1',
        orderNo: 'PF-001',
        restaurantName: 'Bakso Joss',
        customerName: 'Budi',
        total: Money.fromRupiah(45000),
        status: OrderStatus.delivered,
        placedAt: DateTime(2026, 8, 5, 19, 5),
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
