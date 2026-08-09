/// Router guard tests (PF-DOC-17): auth + admin-role redirects against a
/// fake session stream (TS-R06).
library;

import 'package:app_pareadmin/src/app.dart';
import 'package:app_pareadmin/src/presentation/access_denied_page.dart';
import 'package:app_pareadmin/src/presentation/admin_dashboard_page.dart';
import 'package:auth_feature/auth_feature.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

const _admin = AuthSession(
  userId: 'u1',
  email: 'admin@parefood.co',
  role: 'admin',
);
const _customer = AuthSession(
  userId: 'u1',
  email: 'budi@example.com',
  role: 'customer',
);

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  AuthSession? session,
}) async {
  final container = ProviderContainer(
    overrides: [
      authSessionProvider.overrideWith((ref) => Stream.value(session)),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const PareAdminApp(),
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
    expect(find.byType(AdminDashboardPage), findsNothing);
  });

  testWidgets('lands on the dashboard for admin accounts', (tester) async {
    await _pumpApp(tester, session: _admin);

    expect(find.byType(AdminDashboardPage), findsOneWidget);
    expect(find.text('Konsol admin — Sprint 4'), findsOneWidget);
    expect(find.byType(SignInPage), findsNothing);
  });

  testWidgets('blocks non-admin accounts on the access-denied page', (
    tester,
  ) async {
    await _pumpApp(tester, session: _customer);

    expect(find.byType(AccessDeniedPage), findsOneWidget);
    expect(find.byType(AdminDashboardPage), findsNothing);
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
