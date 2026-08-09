import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchant_feature/merchant_feature.dart';

void main() {
  Widget build(Restaurant restaurant) {
    return MaterialApp(home: MerchantStatusPage(restaurant: restaurant));
  }

  const restaurant = Restaurant(
    id: 'r1',
    name: 'Warung Nusantara',
    slug: 'warung-nusantara',
  );

  testWidgets('active status shows the active badge', (tester) async {
    await tester.pumpWidget(
      build(
        const Restaurant(
          id: 'r1',
          name: 'Warung Nusantara',
          slug: 'warung-nusantara',
          status: RestaurantStatus.active,
        ),
      ),
    );
    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Restoran Anda aktif!'), findsOneWidget);
    expect(find.text('Kelola Menu'), findsOneWidget);
  });

  testWidgets('pending status shows the waiting badge', (tester) async {
    await tester.pumpWidget(build(restaurant));
    expect(find.text('Menunggu Verifikasi'), findsOneWidget);
    expect(find.text('Verifikasi sedang berlangsung'), findsOneWidget);
    expect(find.text('Kelola Menu'), findsNothing);
  });

  testWidgets('rejected status shows the error badge', (tester) async {
    await tester.pumpWidget(
      build(
        const Restaurant(
          id: 'r1',
          name: 'Warung Nusantara',
          slug: 'warung-nusantara',
          status: RestaurantStatus.rejected,
        ),
      ),
    );
    expect(find.text('Verifikasi ditolak'), findsOneWidget);
  });

  testWidgets('suspended status shows the error badge', (tester) async {
    await tester.pumpWidget(
      build(
        const Restaurant(
          id: 'r1',
          name: 'Warung Nusantara',
          slug: 'warung-nusantara',
          status: RestaurantStatus.suspended,
        ),
      ),
    );
    expect(find.text('Ditolak'), findsOneWidget);
    expect(find.text('Verifikasi ditolak'), findsOneWidget);
    expect(
      find.text('Silakan periksa dokumen Anda dan daftar ulang.'),
      findsOneWidget,
    );
    expect(find.text('Kelola Menu'), findsNothing);
  });

  testWidgets('active page shows a snackbar when managing menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      build(
        const Restaurant(
          id: 'r1',
          name: 'Warung Nusantara',
          slug: 'warung-nusantara',
          status: RestaurantStatus.active,
        ),
      ),
    );
    await tester.tap(find.text('Kelola Menu'));
    await tester.pump();
    expect(find.text('Menu management di halaman terpisah.'), findsOneWidget);
  });
}
