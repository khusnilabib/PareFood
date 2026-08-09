/// Router guard tests (PF-DOC-17): signed-out redirects, signed-in landing
/// and auth-route bounce, all against a fake session stream (TS-R06).
library;

import 'package:app_parefood/src/app.dart';
import 'package:app_parefood/src/router/app_router.dart';
import 'package:app_parefood/src/shell/home_shell.dart';
import 'package:auth_feature/auth_feature.dart';
import 'package:discovery_feature/discovery_feature.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile_feature/profile_feature.dart';

import 'fakes.dart';

const _customer = AuthSession(userId: 'u1', email: 'budi@example.com');

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  AuthSession? session,
}) async {
  final container = ProviderContainer(
    overrides: [
      authSessionProvider.overrideWith((ref) => Stream.value(session)),
      discoveryRepositoryProvider.overrideWithValue(FakeDiscoveryRepository()),
      profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const PareFoodApp()),
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

  testWidgets('lands on the home shell when signed in', (tester) async {
    await _pumpApp(tester, session: _customer);

    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byType(SignInPage), findsNothing);
  });

  testWidgets('sends signed-in users away from auth routes', (tester) async {
    final container = await _pumpApp(tester, session: _customer);

    container.read(appRouterProvider).go('/login');
    await tester.pumpAndSettle();

    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byType(SignInPage), findsNothing);
  });

  testWidgets('shows the not-found page for unknown routes', (tester) async {
    final container = await _pumpApp(tester, session: _customer);

    container.read(appRouterProvider).go('/tidak-ada');
    await tester.pumpAndSettle();

    expect(find.byType(NotFoundPage), findsOneWidget);
    expect(find.textContaining('/tidak-ada'), findsOneWidget);
  });
}
