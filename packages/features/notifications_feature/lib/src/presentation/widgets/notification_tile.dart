/// Single notification row with type-based icon + relative time (PF-DOC-16).
library;

import 'package:flutter/material.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../domain/app_notification.dart';

/// Compact row for one [AppNotification].
class NotificationTile extends StatelessWidget {
  const NotificationTile({required this.notification, this.onTap, super.key});

  final AppNotification notification;

  /// Called when the tile is tapped (e.g. to deep-link to the order).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        IconData(notification.type.icon),
        color: notification.isRead
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.primary,
      ),
      title: Text(
        notification.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body),
          const SizedBox(height: PfSpacing.xxs),
          Text(
            relativeTimeIndonesian(notification.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
