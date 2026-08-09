/// Dashboard smoke test: the Sprint 1 placeholder announces Sprint 4.
library;

import 'package:app_pareadmin/src/presentation/admin_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the placeholder console message', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminDashboardPage()));

    expect(find.text('PareAdmin'), findsOneWidget);
    expect(find.text('Konsol admin — Sprint 4'), findsOneWidget);
    expect(find.textContaining('Sprint 4'), findsWidgets);
  });
}
