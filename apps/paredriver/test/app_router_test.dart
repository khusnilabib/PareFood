/// Router guard tests (PF-DOC-17): signed-out redirects and signed-in
/// landing against a fake session stream (TS-R06).
library;

import 'package:app_paredriver/src/app.dart';
import 'package:app_paredriver/src/shell/driver_shell.dart';
import 'package:auth_feature/auth_feature.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile_feature/profile_feature.dart';

import 'fakes.dart';

const _driver = AuthSession(userId: 'u1', email: 'budi@example.com');

Future<void> _pumpApp(WidgetTester tester, {AuthSession? session}) async {
  final container = ProviderContainer(
    overrides: [
      authSessionProvider.overrideWith((ref) => Stream.value(session)),
      profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const PareDriverApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('redirects signed-out visitors to the sign-in page', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(find.byType(SignInPage), findsOneWidget);
    expect(find.byType(DriverShell), findsNothing);
  });

  testWidgets('lands on the driver shell when signed in', (tester) async {
    await _pumpApp(tester, session: _driver);

    expect(find.byType(DriverShell), findsOneWidget);
    expect(find.byType(SignInPage), findsNothing);
  });
}
