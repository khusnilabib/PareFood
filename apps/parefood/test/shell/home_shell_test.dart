/// Shell smoke test: tab labels render and selection switches the content.
library;

import 'package:app_parefood/src/shell/home_shell.dart';
import 'package:discovery_feature/discovery_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orders_feature/orders_feature.dart';
import 'package:profile_feature/profile_feature.dart';

import '../fakes.dart';

void main() {
  testWidgets('shows Beranda/Keranjang/Pesanan/Akun tabs and switches', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(
            FakeDiscoveryRepository(),
          ),
          ordersRepositoryProvider.overrideWithValue(FakeOrdersRepository()),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
        ],
        child: const MaterialApp(home: HomeShell()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Keranjang'), findsOneWidget);
    expect(find.text('Pesanan'), findsOneWidget);
    expect(find.text('Akun'), findsOneWidget);
    expect(find.text('Belum ada restoran'), findsOneWidget);
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);

    await tester.tap(find.text('Keranjang'));
    await tester.pumpAndSettle();
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);
    expect(find.text('Keranjang masih kosong'), findsOneWidget);

    await tester.tap(find.text('Pesanan'));
    await tester.pumpAndSettle();
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 2);
    expect(find.text('Belum ada pesanan'), findsOneWidget);

    await tester.tap(find.text('Akun'));
    await tester.pumpAndSettle();
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 3);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
  });
}
