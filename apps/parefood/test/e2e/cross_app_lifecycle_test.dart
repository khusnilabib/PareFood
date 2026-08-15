/// S9 Cross-app E2E test: validates the full order lifecycle across all 4
/// apps using fake repositories that share state (simulating a real backend).
///
/// Flow under test (PF-DOC-18 §3.3 state machine):
///   1. Customer (AP-PF) places an order  → status: placed
///   2. Merchant (AP-PB) accepts it       → placed → accepted → preparing
///   3. Merchant marks ready              → preparing → ready
///   4. Driver (AP-PD) accepts the job    → delivery assigned
///   5. Driver picks up (code verified)   → ready → picked_up
///   6. Driver delivers (photo proof)     → picked_up → delivered
///   7. Admin (AP-PA) sees it on the board→ board shows delivered
///
/// This is a hermetic unit-style E2E (TS-R06): no network, no Supabase, no
/// device. It proves the 4 apps' domain contracts are mutually consistent
/// and the state machine transitions compose correctly end-to-end.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orders_feature/orders_feature.dart';
import 'package:pare_core/pare_core.dart';

import 'test_helpers.dart';

void main() {
  group('S9 — Cross-app order lifecycle E2E', () {
    late SharedBackend backend;

    setUp(() {
      backend = SharedBackend();
    });

    test(
      'customer places → merchant accepts → driver delivers → admin sees',
      () async {
        // --- 1. Customer places an order ---
        final customerRepo = backend.customerRepo;
        final order = await customerRepo.placeOrder(
          restaurantId: 'r1',
          items: [
            seedItem('m1', 'Nasi Goreng', 25000, 2),
            seedItem('m2', 'Es Teh', 5000, 1),
          ],
          deliveryAddress: 'Jl. Merdeka No. 10',
          paymentMethod: 'cod',
        );
        expect(order.status, OrderStatus.placed);
        expect(order.total, Money.fromRupiah(55000));

        // --- 2. Merchant accepts the order ---
        final merchantRepo = backend.merchantRepo;
        final accepted = await merchantRepo.acceptOrder(order.id);
        expect(accepted.status, OrderStatus.preparing);

        final merchantOrders = await merchantRepo.fetchForRestaurant(
          restaurantId: 'r1',
        );
        expect(merchantOrders.any((o) => o.id == order.id), isTrue);

        // --- 3. Merchant marks ready ---
        final ready = await merchantRepo.markReady(order.id);
        expect(ready.status, OrderStatus.ready);

        // --- 4. Driver accepts the dispatch job ---
        final driverRepo = backend.driverRepo;
        final jobs = await driverRepo.fetchForDriver();
        expect(jobs, isNotEmpty);
        final job = jobs.firstWhere((j) => j.orderId == order.id);
        expect(job.status, DeliveryStatus.assigned);

        final acceptedJob = await driverRepo.acceptJob(job.deliveryId);
        expect(acceptedJob.status, DeliveryStatus.assigned);
        expect(acceptedJob.pickupCode, isNotNull);

        // --- 5. Driver picks up (code verified) ---
        final pickedUp = await driverRepo.pickup(
          job.deliveryId,
          code: acceptedJob.pickupCode!,
        );
        expect(pickedUp.status, DeliveryStatus.pickedUp);

        final orderAfterPickup = await customerRepo.fetchById(order.id);
        expect(orderAfterPickup.status, OrderStatus.pickedUp);

        // --- 6. Driver delivers (photo proof) ---
        final delivered = await driverRepo.deliver(
          job.deliveryId,
          proofUrl: 'https://cdn.parefood.co/proof/${job.deliveryId}.jpg',
        );
        expect(delivered.status, DeliveryStatus.delivered);

        // --- 7. Admin sees the delivered order on the board ---
        final adminRepo = backend.adminRepo;
        final board = await adminRepo.fetchAll();
        final adminOrder = board.firstWhere((o) => o.id == order.id);
        expect(adminOrder.status, OrderStatus.delivered);
      },
    );

    test(
      'customer can cancel before merchant accepts (BR-CANCEL-001)',
      () async {
        final customerRepo = backend.customerRepo;
        final order = await customerRepo.placeOrder(
          restaurantId: 'r1',
          items: [seedItem('m1', 'Nasi Goreng', 25000, 1)],
          deliveryAddress: 'Jl. Sudirman',
          paymentMethod: 'ewallet',
        );

        final cancelled = await customerRepo.cancelOrder(
          order.id,
          reason: 'changed mind',
        );
        expect(cancelled.status, OrderStatus.cancelled);

        final merchantOrders = await backend.merchantRepo.fetchForRestaurant(
          restaurantId: 'r1',
        );
        final merchantView = merchantOrders.firstWhere((o) => o.id == order.id);
        expect(merchantView.status, OrderStatus.cancelled);
      },
    );

    test('admin can force-cancel an active order (BR-CANCEL-003)', () async {
      final customerRepo = backend.customerRepo;
      final adminRepo = backend.adminRepo;

      final order = await customerRepo.placeOrder(
        restaurantId: 'r1',
        items: [seedItem('m1', 'Nasi Goreng', 25000, 1)],
        deliveryAddress: 'Jl. Thamrin',
        paymentMethod: 'cod',
      );

      await backend.merchantRepo.acceptOrder(order.id);

      final cancelled = await adminRepo.forceCancel(
        order.id,
        reason: 'restaurant fault',
      );
      expect(cancelled.status, OrderStatus.cancelled);
    });

    test('driver cannot pickup with wrong code (BR-PICKUP)', () async {
      final customerRepo = backend.customerRepo;
      final driverRepo = backend.driverRepo;

      final order = await customerRepo.placeOrder(
        restaurantId: 'r1',
        items: [seedItem('m1', 'Nasi Goreng', 25000, 1)],
        deliveryAddress: 'Jl. Diponegoro',
        paymentMethod: 'cod',
      );
      await backend.merchantRepo.acceptOrder(order.id);
      await backend.merchantRepo.markReady(order.id);

      final jobs = await driverRepo.fetchForDriver();
      final job = jobs.firstWhere((j) => j.orderId == order.id);
      await driverRepo.acceptJob(job.deliveryId);

      expect(
        () => driverRepo.pickup(job.deliveryId, code: '0000'),
        throwsA(isA<PareException>()),
      );
    });
  });
}
