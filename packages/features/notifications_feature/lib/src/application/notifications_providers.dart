/// Notifications providers (PF-DOC-11 §3.2).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notifications_repository.dart';
import '../domain/app_notification.dart';
import '../domain/notifications_use_cases.dart';

/// Repository contract; override at the composition root (FL-R04).
final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  throw UnimplementedError(
    'notificationsRepositoryProvider must be overridden in the composition root.',
  );
});

/// Loads notifications for the current user.
final fetchNotificationsProvider = Provider<FetchNotifications>((ref) {
  return FetchNotifications(ref.watch(notificationsRepositoryProvider));
});

/// Notifications, newest first.
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  return ref.watch(fetchNotificationsProvider).call();
});

/// Unread count derived from the loaded list; 0 while unknown.
final unreadNotificationsProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).value;
  if (notifications == null) return 0;
  return notifications.where((n) => !n.isRead).length;
});

/// Marks all notifications as read. Returns a callable so the UI can retry.
final markAllReadProvider = Provider<Future<void> Function()>((ref) {
  return () => ref.read(notificationsRepositoryProvider).markAllRead();
});
