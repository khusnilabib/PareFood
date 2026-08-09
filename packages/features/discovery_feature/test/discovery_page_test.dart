import 'dart:async';

import 'package:discovery_feature/discovery_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sample = [
    const RestaurantSummary(
      id: 'r1',
      name: 'Warung Nusantara',
      slug: 'warung-nusantara',
      ratingAvg: 4.5,
      reviewCount: 8,
      deliveryRadiusKm: 5,
    ),
  ];

  Widget build(DiscoveryRepository repo) {
    return ProviderScope(
      overrides: [discoveryRepositoryProvider.overrideWithValue(repo)],
      retry: (retryCount, error) => null,
      child: const MaterialApp(home: DiscoveryPage()),
    );
  }

  testWidgets('data state lists restaurants', (tester) async {
    final repo = _FakeDiscoveryRepository(() async => sample);
    await tester.pumpWidget(build(repo));
    await tester.pumpAndSettle();
    expect(find.text('Warung Nusantara'), findsOneWidget);
    expect(find.text('4.5 (8)'), findsOneWidget);
  });

  testWidgets('loading state shows a spinner', (tester) async {
    final completer = Completer<List<RestaurantSummary>>();
    final repo = _FakeDiscoveryRepository(() => completer.future);
    await tester.pumpWidget(build(repo));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error state shows retry', (tester) async {
    final repo = _FakeDiscoveryRepository(() async => throw Exception('boom'));
    await tester.pumpWidget(build(repo));
    await tester.pumpAndSettle();
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.text('Gagal memuat restoran.'), findsOneWidget);
  });

  testWidgets('empty state shows empty view', (tester) async {
    final repo = _FakeDiscoveryRepository(() async => []);
    await tester.pumpWidget(build(repo));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada restoran'), findsOneWidget);
  });

  testWidgets('data state shows description, rating and delivery range', (
    tester,
  ) async {
    final repo = _FakeDiscoveryRepository(
      () async => [
        const RestaurantSummary(
          id: 'r2',
          name: 'Soto Enak',
          slug: 'soto-enak',
          description: 'Khas Semarang',
          ratingAvg: 4.9,
          reviewCount: 120,
          deliveryRadiusKm: 7,
        ),
      ],
    );
    await tester.pumpWidget(build(repo));
    await tester.pumpAndSettle();
    expect(find.text('Soto Enak'), findsOneWidget);
    expect(find.text('Khas Semarang'), findsOneWidget);
    expect(find.text('4.9 (120)'), findsOneWidget);
    expect(find.text('Jangkauan 7 km'), findsOneWidget);
  });

  testWidgets('data state shows "Baru" for unreviewed restaurants', (
    tester,
  ) async {
    final repo = _FakeDiscoveryRepository(
      () async => [
        const RestaurantSummary(id: 'r3', name: 'Baru Buka', slug: 'baru'),
      ],
    );
    await tester.pumpWidget(build(repo));
    await tester.pumpAndSettle();
    expect(find.text('Baru'), findsOneWidget);
    expect(find.text('Jangkauan 5 km'), findsOneWidget);
  });

  testWidgets('data state separates multiple restaurants', (tester) async {
    final repo = _FakeDiscoveryRepository(
      () async => [
        ...sample,
        const RestaurantSummary(id: 'r4', name: 'Kedua', slug: 'kedua'),
      ],
    );
    await tester.pumpWidget(build(repo));
    await tester.pumpAndSettle();
    expect(find.text('Warung Nusantara'), findsOneWidget);
    expect(find.text('Kedua'), findsOneWidget);
  });

  testWidgets('tapping a restaurant opens its detail page', (tester) async {
    final repo = _FakeDiscoveryRepository(() async => sample);
    await tester.pumpWidget(build(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Warung Nusantara'));
    await tester.pumpAndSettle();

    expect(find.text('Detail'), findsOneWidget);
    expect(find.text('Restoran tidak ditemukan.'), findsOneWidget);
  });

  testWidgets('retry reloads after an error', (tester) async {
    var calls = 0;
    final repo = _FakeDiscoveryRepository(() async {
      calls++;
      if (calls == 1) throw Exception('boom');
      return sample;
    });
    await tester.pumpWidget(build(repo));
    await tester.pumpAndSettle();
    expect(find.text('Gagal memuat restoran.'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Warung Nusantara'), findsOneWidget);
  });
}

class _FakeDiscoveryRepository implements DiscoveryRepository {
  _FakeDiscoveryRepository(this._nearby);

  final Future<List<RestaurantSummary>> Function() _nearby;

  @override
  Future<List<RestaurantSummary>> nearbyRestaurants({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) {
    return _nearby();
  }

  @override
  Future<RestaurantDetail?> restaurantDetail(String restaurantId) async => null;
}
