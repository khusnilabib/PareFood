/// Notifications repository contract (PF-DOC-11 §3.1 data layer).
///
/// Concrete implementations live in the app composition root and delegate to
/// `pare_data`; features never import the SDKs directly (MO-R02a). Overrides
/// of [notificationsRepositoryProvider] are the only test seam (FL-R04).
library;

import '../domain/app_notification.dart';

/// Contract implemented by the composition root.
abstract interface class NotificationsRepository {
  /// Notifications for the current user, newest first. Empty when none.
  Future<List<AppNotification>> fetchNotifications();

  /// Marks one notification as read.
  Future<void> markRead(String id);
}
