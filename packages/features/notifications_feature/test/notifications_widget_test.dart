/// Widget tests for the notifications surface (FL-R07: all four states).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notifications_feature/notifications_feature.dart';
import 'package:pare_core/pare_core.dart';

/// Riverpod 3 retries by default; disable it so error states can be asserted
/// deterministically in widget tests.
Duration? _noRetry(int attempt, Object error) => null;

void main() {
  group('NotificationsPage (FL-R07)', () {
    testWidgets('shows a spinner while notifications load', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: _noRetry,
          overrides: [
            notificationsRepositoryProvider.overrideWithValue(
              _FakeNotificationsRepository(pending: true),
            ),
          ],
          child: const MaterialApp(home: NotificationsPage()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders one tile per notification', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: _noRetry,
          overrides: [
            notificationsRepositoryProvider.overrideWithValue(
              _FakeNotificationsRepository(),
            ),
          ],
          child: const MaterialApp(home: NotificationsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NotificationTile), findsNWidgets(2));
      expect(find.text('Pesanan diproses'), findsOneWidget);
      expect(find.text('Pesanan #123 sedang disiapkan.'), findsOneWidget);
      // Unread rows use the active icon, read rows the outlined one.
      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('shows the empty state when there are no notifications', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: _noRetry,
          overrides: [
            notificationsRepositoryProvider.overrideWithValue(
              _FakeNotificationsRepository(empty: true),
            ),
          ],
          child: const MaterialApp(home: NotificationsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada notifikasi'), findsOneWidget);
      expect(
        find.text('Pembaruan pesanan akan muncul di sini.'),
        findsOneWidget,
      );
    });

    testWidgets('surfaces typed errors and recovers via retry', (tester) async {
      final repository = _FakeNotificationsRepository(
        fetchError: const PareNetworkException('Koneksi terputus.'),
      );
      await tester.pumpWidget(
        ProviderScope(
          retry: _noRetry,
          overrides: [
            notificationsRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: NotificationsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Koneksi terputus.'), findsOneWidget);
      expect(find.text('Gagal memuat notifikasi.'), findsNothing);

      repository.fetchError = null;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationTile), findsNWidgets(2));
    });
  });

  group('unreadNotificationsProvider', () {
    test('is 0 while notifications are still loading', () {
      final container = ProviderContainer(
        retry: _noRetry,
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(
            _FakeNotificationsRepository(pending: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(unreadNotificationsProvider), 0);
    });

    test('throws when the repository is not overridden (FL-R04)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(notificationsRepositoryProvider),
        throwsA(
          predicate<Object>(
            (e) => e.toString().contains(
              'must be overridden in the composition root',
            ),
          ),
        ),
      );
    });
  });

  group('AppNotification', () {
    test('copyWith only replaces isRead', () {
      final notification = AppNotification(
        id: 'n1',
        title: 'Pesanan diproses',
        body: 'Pesanan #123 sedang disiapkan.',
        createdAt: _createdAt,
      );

      final read = notification.copyWith(isRead: true);
      expect(read.isRead, isTrue);
      expect(read.id, notification.id);
      expect(read.title, notification.title);
      expect(read.body, notification.body);
      expect(read.createdAt, notification.createdAt);
      expect(notification.copyWith(), notification);
    });

    test('value equality and hashCode', () {
      final a = AppNotification(
        id: 'n1',
        title: 't',
        body: 'b',
        createdAt: _createdAt,
      );
      final b = AppNotification(
        id: 'n1',
        title: 't',
        body: 'b',
        createdAt: _createdAt,
      );
      final c = a.copyWith(isRead: true);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
      expect(a == 'n1', isFalse);
    });
  });
}

final _createdAt = DateTime(2026, 8, 6, 10);

class _FakeNotificationsRepository implements NotificationsRepository {
  _FakeNotificationsRepository({
    this.fetchError,
    this.pending = false,
    this.empty = false,
  });

  PareException? fetchError;
  final bool pending;
  final bool empty;

  @override
  Future<List<AppNotification>> fetchNotifications() {
    final error = fetchError;
    if (error != null) return Future.error(error);
    if (pending) return Completer<List<AppNotification>>().future;
    if (empty) return Future.value(const []);
    return Future.value([
      AppNotification(
        id: 'n1',
        title: 'Pesanan diproses',
        body: 'Pesanan #123 sedang disiapkan.',
        createdAt: _createdAt,
      ),
      AppNotification(
        id: 'n2',
        title: 'Pesanan selesai',
        body: 'Pesanan #122 sudah diantar.',
        createdAt: DateTime(2026, 8, 5, 19, 5),
        isRead: true,
      ),
    ]);
  }

  @override
  Future<void> markRead(String id) async {}
}
