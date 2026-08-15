/// Default [NotificationsRepository] backed by Supabase PostgREST + Edge
/// Functions (PF-DOC-11 §3.1, PF-DOC-14 §3.2). Reads via PostgREST (RLS);
/// device-token registration via the `register-device-token` Edge Function
/// (API-R01, FR-NOTIF-005).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_notification.dart';
import 'notifications_repository.dart';

/// Adapts the Supabase client to [NotificationsRepository].
class SupabaseNotificationsRepository implements NotificationsRepository {
  SupabaseNotificationsRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<AppNotification>> fetchNotifications() async {
    final rows = await _client
        .from('notifications')
        .select('id, title, body, type, is_read, order_id, data, created_at')
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map(_toNotification).toList();
  }

  @override
  Future<void> markRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  @override
  Future<void> markAllRead() async {
    // PostgREST update with a filter: update all unread rows for the current
    // user (RLS scopes to self).
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('is_read', false);
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    required NotificationPlatform platform,
  }) async {
    await _client.functions.invoke(
      'register-device-token',
      body: {
        'token': token,
        'platform': platform == NotificationPlatform.fcm ? 'fcm' : 'apns',
      },
    );
  }

  AppNotification _toNotification(Map<String, dynamic> row) {
    return AppNotification(
      id: row['id'] as String,
      title: (row['title'] as String?) ?? '',
      body: (row['body'] as String?) ?? '',
      createdAt: DateTime.parse(row['created_at'] as String),
      type: NotificationType.fromString(row['type'] as String?),
      isRead: (row['is_read'] as bool?) ?? false,
      orderId: row['order_id'] as String?,
      data: row['data'] as Map<String, dynamic>?,
    );
  }
}
