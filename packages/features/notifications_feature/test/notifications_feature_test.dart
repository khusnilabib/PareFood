import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notifications_feature/notifications_feature.dart';

void main() {
  group('notificationsProvider', () {
    test('surfaces repository notifications', () async {
      final container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(
            _FakeNotificationsRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifications = await container.read(notificationsProvider.future);
      expect(notifications, hasLength(2));
    });
  });

  group('unreadNotificationsProvider', () {
    test('counts only unread items', () async {
      final container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(
            _FakeNotificationsRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(notificationsProvider.future);
      expect(container.read(unreadNotificationsProvider), 1);
    });
  });
}

class _FakeNotificationsRepository implements NotificationsRepository {
  @override
  Future<List<AppNotification>> fetchNotifications() async {
    return [
      AppNotification(
        id: 'n1',
        title: 'Pesanan diproses',
        body: 'Pesanan #123 sedang disiapkan.',
        createdAt: DateTime(2026, 8, 6, 10, 0),
      ),
      AppNotification(
        id: 'n2',
        title: 'Pesanan selesai',
        body: 'Pesanan #122 sudah diantar.',
        createdAt: DateTime(2026, 8, 5, 19, 5),
        isRead: true,
      ),
    ];
  }

  @override
  Future<void> markRead(String id) async {}
}
