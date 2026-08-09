/// Shell smoke test: tab labels render and selection switches the content.
library;

import 'package:app_parefood/src/shell/home_shell.dart';
import 'package:discovery_feature/discovery_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile_feature/profile_feature.dart';

import '../fakes.dart';

void main() {
  testWidgets('shows Beranda/Akun tabs and switches between them', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(
            FakeDiscoveryRepository(),
          ),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
        ],
        child: const MaterialApp(home: HomeShell()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Akun'), findsOneWidget);
    // Empty discovery results render the FL-R07 empty state.
    expect(find.text('Belum ada restoran'), findsOneWidget);
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);

    await tester.tap(find.text('Akun'));
    await tester.pumpAndSettle();

    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
  });
}
