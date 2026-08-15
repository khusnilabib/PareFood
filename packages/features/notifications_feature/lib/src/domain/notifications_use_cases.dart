/// Notifications use cases (PF-DOC-11 §3.1 domain layer). Pure Dart.
library;

import '../data/notifications_repository.dart';
import 'app_notification.dart';

/// Loads notifications for the current user.
class FetchNotifications {
  const FetchNotifications(this._repository);

  final NotificationsRepository _repository;

  Future<List<AppNotification>> call() => _repository.fetchNotifications();
}

/// Marks all unread notifications as read.
class MarkAllRead {
  const MarkAllRead(this._repository);

  final NotificationsRepository _repository;

  Future<void> call() => _repository.markAllRead();
}
