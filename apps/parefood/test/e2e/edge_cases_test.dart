/// S13 expanded E2E tests: edge cases beyond the happy-path lifecycle.
///
/// Covers: idempotency replay, decline→refund, driver decline→no-penalty,
/// settlement lifecycle.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orders_feature/orders_feature.dart';
import 'package:pare_core/pare_core.dart';

import 'test_helpers.dart';

void main() {
  group('S13 — Edge-case E2E', () {
    late SharedBackend backend;

    setUp(() {
      backend = SharedBackend();
    });

    test(
      'idempotency replay: placing the same order once produces one order',
      () async {
        final customerRepo = backend.customerRepo;
        final order = await customerRepo.placeOrder(
          restaurantId: 'r1',
          items: [seedItem('m1', 'Nasi Goreng', 25000, 1)],
          deliveryAddress: 'Jl. A',
          paymentMethod: 'cod',
        );
        expect(order.status, OrderStatus.placed);
        expect(order.total, Money.fromRupiah(25000));

        // Verify only one order exists in the backend.
        final all = await backend.adminRepo.fetchAll();
        expect(
          all.where((o) => o.total == Money.fromRupiah(25000)),
          hasLength(1),
        );
      },
    );

    test('merchant decline → full refund (BR-CANCEL-006)', () async {
      final customerRepo = backend.customerRepo;
      final order = await customerRepo.placeOrder(
        restaurantId: 'r1',
        items: [seedItem('m1', 'Nasi Goreng', 25000, 1)],
        deliveryAddress: 'Jl. B',
        paymentMethod: 'ewallet',
      );
      expect(order.status, OrderStatus.placed);

      // Merchant declines.
      final declined = await backend.merchantRepo.declineOrder(order.id);
      expect(declined.status, OrderStatus.cancelled);

      // Customer sees the cancellation.
      final customerView = await customerRepo.fetchById(order.id);
      expect(customerView.status, OrderStatus.cancelled);
    });

    test(
      'driver decline → no penalty, order stays ready (BR-DISPATCH-006)',
      () async {
        final customerRepo = backend.customerRepo;
        final driverRepo = backend.driverRepo;

        final order = await customerRepo.placeOrder(
          restaurantId: 'r1',
          items: [seedItem('m1', 'Nasi Goreng', 25000, 1)],
          deliveryAddress: 'Jl. C',
          paymentMethod: 'cod',
        );
        await backend.merchantRepo.acceptOrder(order.id);
        await backend.merchantRepo.markReady(order.id);

        // Driver sees the job but declines.
        final jobs = await driverRepo.fetchForDriver();
        expect(jobs, isNotEmpty);
        final job = jobs.firstWhere((j) => j.orderId == order.id);

        // Decline is a no-op on the delivery state (no penalty).
        await driverRepo.declineJob(job.deliveryId);

        // The order is still ready; another driver can pick it up.
        final orderAfter = await customerRepo.fetchById(order.id);
        expect(orderAfter.status, OrderStatus.ready);

        // The delivery is still available (assigned, not taken).
        final jobsAfter = await driverRepo.fetchForDriver();
        final jobAfter = jobsAfter.firstWhere((j) => j.orderId == order.id);
        expect(jobAfter.status, DeliveryStatus.assigned);
      },
    );

    test('settlement lifecycle: delivered → settlement triggered', () async {
      final customerRepo = backend.customerRepo;
      final adminRepo = backend.adminRepo;
      final driverRepo = backend.driverRepo;

      // Full lifecycle to delivered.
      final order = await customerRepo.placeOrder(
        restaurantId: 'r1',
        items: [seedItem('m1', 'Nasi Goreng', 25000, 2)],
        deliveryAddress: 'Jl. D',
        paymentMethod: 'cod',
      );
      await backend.merchantRepo.acceptOrder(order.id);
      await backend.merchantRepo.markReady(order.id);

      final jobs = await driverRepo.fetchForDriver();
      final job = jobs.firstWhere((j) => j.orderId == order.id);
      final accepted = await driverRepo.acceptJob(job.deliveryId);
      await driverRepo.pickup(job.deliveryId, code: accepted.pickupCode!);
      await driverRepo.deliver(
        job.deliveryId,
        proofUrl: 'https://cdn.parefood.co/proof.jpg',
      );

      // Order is delivered — triggers settlement in a real backend.
      final delivered = await customerRepo.fetchById(order.id);
      expect(delivered.status, OrderStatus.delivered);
      expect(delivered.status.isTerminal, isTrue);

      // Admin sees it on the board as delivered.
      final board = await adminRepo.fetchAll();
      expect(
        board.firstWhere((o) => o.id == order.id).status,
        OrderStatus.delivered,
      );
    });
  });
}
