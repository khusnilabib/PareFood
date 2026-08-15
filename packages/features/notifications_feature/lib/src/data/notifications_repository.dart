/// Notifications repository contract (PF-DOC-11 §3.1 data layer).
///
/// S6 expansion: adds [registerDeviceToken] (FR-NOTIF-005) and [markAllRead]
/// for the bulk-read action. Concrete implementations live in the app
/// composition root and delegate to `pare_data`; features never import the
/// SDKs directly (MO-R02a). Overrides of [notificationsRepositoryProvider]
/// are the only test seam (FL-R04).
library;

import '../domain/app_notification.dart';

/// Push notification platform (FR-NOTIF-005).
enum NotificationPlatform { fcm, apns }

/// Contract implemented by the composition root.
abstract interface class NotificationsRepository {
  /// Notifications for the current user, newest first. Empty when none.
  Future<List<AppNotification>> fetchNotifications();

  /// Marks one notification as read.
  Future<void> markRead(String id);

  /// Marks all unread notifications as read.
  Future<void> markAllRead();

  /// Registers (upserts) a device push token for the current user
  /// (FR-NOTIF-005). Never sent via PostgREST — always through an Edge
  /// Function (API-R01) so the token is validated server-side.
  Future<void> registerDeviceToken({
    required String token,
    required NotificationPlatform platform,
  });
}
