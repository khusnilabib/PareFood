/// Router guard tests (PF-DOC-17): auth + business-role redirects against a
/// fake session stream (TS-R06).
library;

import 'package:app_parebisnis/src/app.dart';
import 'package:app_parebisnis/src/presentation/access_denied_page.dart';
import 'package:app_parebisnis/src/shell/home_shell.dart';
import 'package:auth_feature/auth_feature.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_feature/menu_feature.dart';
import 'package:merchant_feature/merchant_feature.dart';
import 'package:profile_feature/profile_feature.dart';

import 'fakes.dart';

const _merchant = AuthSession(
  userId: 'u1',
  email: 'budi@example.com',
  role: 'business',
);
const _customer = AuthSession(
  userId: 'u1',
  email: 'budi@example.com',
  role: 'customer',
);

final _testRestaurant = Restaurant(id: 'r1', name: 'Warung Budi', slug: 'wb');

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  AuthSession? session,
}) async {
  final container = ProviderContainer(
    overrides: [
      authSessionProvider.overrideWith((ref) => Stream.value(session)),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      menuRepositoryProvider.overrideWithValue(FakeMenuRepository()),
      profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
      restaurantRepositoryProvider.overrideWithValue(
        FakeRestaurantRepository(restaurants: [_testRestaurant]),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const PareBisnisApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('redirects signed-out visitors to the sign-in page', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(find.byType(SignInPage), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);
  });

  testWidgets('lands on the merchant shell for business accounts', (
    tester,
  ) async {
    await _pumpApp(tester, session: _merchant);

    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byType(SignInPage), findsNothing);
    expect(find.byType(AccessDeniedPage), findsNothing);
  });

  testWidgets('blocks non-business accounts on the access-denied page', (
    tester,
  ) async {
    await _pumpApp(tester, session: _customer);

    expect(find.byType(AccessDeniedPage), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);
  });

  testWidgets('the access-denied page signs out to switch accounts', (
    tester,
  ) async {
    final container = await _pumpApp(tester, session: _customer);

    await tester.tap(find.text('Ganti akun'));
    await tester.pumpAndSettle();

    // The fake session stream never re-emits, so the page stays; the call
    // itself is the contract under test.
    final fake = container.read(authRepositoryProvider) as FakeAuthRepository;
    expect(fake.signOutCount, 1);
  });
}
