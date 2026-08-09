/// Shell smoke test: the Sprint 1 driver shell hosts the profile page.
library;

import 'package:app_paredriver/src/shell/driver_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile_feature/profile_feature.dart';

import '../fakes.dart';

void main() {
  testWidgets('hosts the signed-in profile page', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
        ],
        child: const MaterialApp(home: DriverShell()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Edit profil'), findsOneWidget);
  });
}
