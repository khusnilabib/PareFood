# notifications_feature

In-app notifications for PareFood (PF-DOC-11 §3.1): notification list,
read-state and unread count.

## Layers

- `data/` — `NotificationsRepository` contract. Implementations live in the
  app composition root and delegate to `pare_data` (Dio/Supabase, MO-R02a).
- `domain/` — `AppNotification`, `FetchNotifications` use case.
- `application/` — `notificationsRepositoryProvider`, `notificationsProvider`,
  `unreadNotificationsProvider`.
- `presentation/` — `NotificationsPage` + `NotificationTile`.

## Boundaries

- Never imports Supabase/Dio SDKs directly (MO-R02a).
- Never depends on another feature package (MO-R02d).
- Presentation never imports `data`; it consumes providers only (PF-DOC-11 §3.1).
