import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';

double _contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('AppTheme', () {
    test('light theme exposes brand seed colour', () {
      final theme = AppTheme.light();
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, PfColors.primaryLight);
      expect(theme.useMaterial3, isTrue);
    });

    test('dark theme exposes dark tokens', () {
      final theme = AppTheme.dark();
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, PfColors.primaryDark);
      expect(theme.scaffoldBackgroundColor, PfColors.surfaceDark);
    });

    test('token contrast meets WCAG AA thresholds (NFR-030)', () {
      final light = AppTheme.light().colorScheme;
      final dark = AppTheme.dark().colorScheme;

      // Primary text on surfaces must meet AA normal (4.5:1).
      expect(
        _contrastRatio(light.onSurface, light.surface),
        greaterThanOrEqualTo(4.5),
        reason: 'light onSurface/surface',
      );
      expect(
        _contrastRatio(dark.onSurface, dark.surface),
        greaterThanOrEqualTo(4.5),
        reason: 'dark onSurface/surface',
      );
      expect(
        _contrastRatio(dark.onPrimary, dark.primary),
        greaterThanOrEqualTo(4.5),
        reason: 'dark onPrimary/primary',
      );

      // Brand CTA and secondary text meet AA large (3:1).
      expect(
        _contrastRatio(light.onPrimary, light.primary),
        greaterThanOrEqualTo(3.0),
        reason: 'light onPrimary/primary',
      );
      expect(
        _contrastRatio(light.onSurfaceVariant, light.surface),
        greaterThanOrEqualTo(3.0),
        reason: 'light onSurfaceVariant/surface',
      );
      expect(
        _contrastRatio(dark.onSurfaceVariant, dark.surface),
        greaterThanOrEqualTo(3.0),
        reason: 'dark onSurfaceVariant/surface',
      );
      expect(
        _contrastRatio(light.error, light.surfaceContainer),
        greaterThanOrEqualTo(3.0),
        reason: 'light error/surfaceContainer',
      );
      expect(
        _contrastRatio(dark.error, dark.surfaceContainer),
        greaterThanOrEqualTo(3.0),
        reason: 'dark error/surfaceContainer',
      );
    });
  });

  group('PfButton', () {
    testWidgets('renders label and fires onPressed', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: PfButton(label: 'Pesan', onPressed: () => tapped++),
          ),
        ),
      );
      expect(find.text('Pesan'), findsOneWidget);
      await tester.tap(find.text('Pesan'));
      expect(tapped, 1);
    });

    testWidgets('disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: PfButton(label: 'Pesan', onPressed: null)),
        ),
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows loading indicator and disables', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: PfButton(label: 'Pesan', onPressed: null, isLoading: true),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });

  group('PfStatusBadge', () {
    testWidgets('renders status colour, icon and label together', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: PfStatusBadge(status: PfStatus.active, label: 'Aktif'),
          ),
        ),
      );
      expect(find.text('Aktif'), findsOneWidget);
      expect(find.byIcon(Icons.circle), findsOneWidget);
    });
  });

  group('PfSkeleton', () {
    testWidgets('builds a placeholder block', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: PfSkeleton(height: 24)),
        ),
      );
      expect(find.byType(PfSkeleton), findsOneWidget);
    });
  });

  group('PfEmptyState / PfErrorState', () {
    testWidgets('empty state renders title and CTA', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: PfEmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Keranjang kosong',
              actionLabel: 'Lihat menu',
              onAction: () {},
            ),
          ),
        ),
      );
      expect(find.text('Keranjang kosong'), findsOneWidget);
      expect(find.text('Lihat menu'), findsOneWidget);
    });

    testWidgets('error state surfaces exception message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: PfErrorState(
              onRetry: () {},
              error: const PareNetworkException('Gagal memuat data.'),
            ),
          ),
        ),
      );
      expect(find.text('Gagal memuat data.'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });
  });
}
