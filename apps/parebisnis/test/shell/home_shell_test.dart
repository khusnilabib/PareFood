/// Shell smoke tests: tab labels, onboarding when no restaurant exists and
/// status/menu pages once one does (FR-ONB-001, FR-MENU-001).
library;

import 'package:app_parebisnis/src/shell/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_feature/menu_feature.dart';
import 'package:merchant_feature/merchant_feature.dart';
import 'package:profile_feature/profile_feature.dart';

import '../fakes.dart';

Future<void> _pumpShell(
  WidgetTester tester, {
  required List<Restaurant> restaurants,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        menuRepositoryProvider.overrideWithValue(FakeMenuRepository()),
        profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
        restaurantRepositoryProvider.overrideWithValue(
          FakeRestaurantRepository(restaurants: restaurants),
        ),
      ],
      child: const MaterialApp(home: HomeShell()),
    ),
  );
}

void main() {
  testWidgets('shows onboarding and menu guidance without a restaurant', (
    tester,
  ) async {
    await _pumpShell(tester, restaurants: const []);
    await tester.pumpAndSettle();

    expect(find.text('Restoran'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Akun'), findsOneWidget);
    // No restaurant yet: the Restoran tab offers the onboarding wizard.
    expect(find.byType(MerchantOnboardingPage), findsOneWidget);

    // Switch to the Menu tab: it guides the merchant to register first.
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada restoran'), findsOneWidget);
  });

  testWidgets('switches between status, menu and profile tabs', (tester) async {
    await _pumpShell(
      tester,
      restaurants: const [Restaurant(id: 'r1', name: 'Warung Budi', slug: 'wb')],
    );
    await tester.pumpAndSettle();

    expect(find.byType(MerchantStatusPage), findsOneWidget);

    final stack = find.byType(IndexedStack);
    expect(tester.widget<IndexedStack>(stack).index, 0);

    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    expect(tester.widget<IndexedStack>(stack).index, 1);
    expect(find.byType(MenuManagementPage), findsOneWidget);

    await tester.tap(find.text('Akun'));
    await tester.pumpAndSettle();
    expect(tester.widget<IndexedStack>(stack).index, 2);
    expect(find.text('Profil'), findsOneWidget);
  });
}
