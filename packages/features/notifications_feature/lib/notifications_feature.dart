/// notifications_feature — in-app notifications for PareFood (PF-DOC-11 §3.1).
///
/// ## Responsibility
/// Notification list, read-state handling and the derived unread count shown
/// on the app badge.
///
/// ## Boundaries — must NOT
/// - Import Supabase/Dio SDKs directly (MO-R02a).
/// - Depend on another feature package (MO-R02d).
library;

export 'src/application/notifications_providers.dart';
export 'src/data/notifications_repository.dart';
export 'src/domain/app_notification.dart';
export 'src/domain/notifications_use_cases.dart';
export 'src/presentation/pages/notifications_page.dart';
export 'src/presentation/widgets/notification_tile.dart';
