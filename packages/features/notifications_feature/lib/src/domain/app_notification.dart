/// A single push/in-app notification for the current user.
library;

/// Immutable notification item. Equality is value-based.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppNotification &&
        other.id == id &&
        other.title == title &&
        other.body == body &&
        other.createdAt == createdAt &&
        other.isRead == isRead;
  }

  @override
  int get hashCode => Object.hash(id, title, body, createdAt, isRead);
}
