import 'dart:async';

import 'package:discovery_feature/discovery_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pare_core/pare_core.dart';

void main() {
  const restaurant = RestaurantSummary(
    id: 'r1',
    name: 'Warung Nusantara',
    slug: 'warung-nusantara',
    description: 'Makanan khas Indonesia.',
    ratingAvg: 4.5,
    reviewCount: 8,
  );

  RestaurantDetail detail({List<DiscoveryMenuItem> menu = const []}) {
    return RestaurantDetail(restaurant: restaurant, menu: menu);
  }

  Widget build(DiscoveryRepository repo) {
    return ProviderScope(
      overrides: [discoveryRepositoryProvider.overrideWithValue(repo)],
      retry: (retryCount, error) => null,
      child: const MaterialApp(home: RestaurantDetailPage(restaurantId: 'r1')),
    );
  }

  testWidgets('data state shows restaurant and menu with prices', (
    tester,
  ) async {
    final repo = _FakeDiscoveryRepository(
      detail: () async => detail(
        menu: [
          DiscoveryMenuItem(
            id: 'm1',
            name: 'Rendang',
            price: Money.fromRupiah(85000),
            description: 'Daging sapi',
            isAvailable: true,
          ),
          DiscoveryMenuItem(
            id: 'm2',
            name: 'Sate Ayam',
            price: Money.fromRupiah(30000),
            isAvailable: false,
          ),
        ],
      ),
    );
    await tester.pumpWidget(build(repo));
    await tester.pumpAndSettle();

    expect(find.text('Warung Nusantara'), findsOneWidget);
    expect(find.text('4.5 · 8 ulasan'), findsOneWidget);
    expect(find.text('Makanan khas Indonesia.'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Rendang'), findsOneWidget);
    expect(find.text('Daging sapi'), findsOneWidget);
    expect(find.text('Rp 85.000'), findsOneWidget);
    expect(find.text('Sate Ayam'), findsOneWidget);
    expect(find.text('Rp 30.000'), findsOneWidget);
  });

  testWidgets('data state without rating or description stays minimal', (
    tester,
  ) async {
    final repo = _FakeDiscoveryRepository(
      detail: () async => const RestaurantDetail(
        restaurant: RestaurantSummary(
          id: 'r1',
          name: 'Soto Enak',
          slug: 'soto-enak',
        ),
        menu: [],
      ),
    );
    await tester.pumpWidget(build(repo));
    await tester.pumpAndSettle();

    expect(find.text('Soto Enak'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Belum ada menu.'), findsOneWidget);
    expect(find.textContaining('ulasan'), findsNothing);
  });

  testWidgets('not-found data shows not-found error state', (tester) async {
    final repo = _FakeDiscoveryRepository(detail: () async => null);
    await tester.pumpWidget(build(repo));
    await tester.pumpAndSettle();
    expect(find.text('Restoran tidak ditemukan.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('loading state shows a spinner', (tester) async {
    final completer = Completer<RestaurantDetail?>();
    final repo = _FakeDiscoveryRepository(detail: () => completer.future);
    await tester.pumpWidget(build(repo));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error state shows retry and reloads on tap', (tester) async {
    var calls = 0;
    final repo = _FakeDiscoveryRepository(
      detail: () async {
        calls++;
        if (calls == 1) throw Exception('boom');
        return detail(
          menu: [
            DiscoveryMenuItem(
              id: 'm1',
              name: 'Rendang',
              price: Money.fromRupiah(85000),
            ),
          ],
        );
      },
    );
    await tester.pumpWidget(build(repo));
    await tester.pumpAndSettle();

    expect(find.text('Gagal memuat detail.'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Rendang'), findsOneWidget);
  });
}

class _FakeDiscoveryRepository implements DiscoveryRepository {
  _FakeDiscoveryRepository({
    Future<List<RestaurantSummary>> Function()? nearby,
    Future<RestaurantDetail?> Function()? detail,
  }) : _nearby = nearby ?? (() async => const <RestaurantSummary>[]),
       _detail = detail ?? (() async => null);

  final Future<List<RestaurantSummary>> Function() _nearby;
  final Future<RestaurantDetail?> Function() _detail;

  @override
  Future<List<RestaurantSummary>> nearbyRestaurants({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) {
    return _nearby();
  }

  @override
  Future<RestaurantDetail?> restaurantDetail(String restaurantId) {
    return _detail();
  }
}
