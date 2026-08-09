/// The merchant's restaurant and its onboarding/verification state
/// (PF-DOC-11 §3.2).
library;

/// Immutable restaurant owned by the signed-in business profile.
class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.coverUrl,
    this.status = RestaurantStatus.pending,
    this.deliveryRadiusKm = 5,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? coverUrl;
  final RestaurantStatus status;
  final double deliveryRadiusKm;

  bool get isActive => status == RestaurantStatus.active;

  @override
  bool operator ==(Object other) {
    return other is Restaurant &&
        other.id == id &&
        other.name == name &&
        other.slug == slug &&
        other.description == description &&
        other.logoUrl == logoUrl &&
        other.coverUrl == coverUrl &&
        other.status == status &&
        other.deliveryRadiusKm == deliveryRadiusKm;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    slug,
    description,
    logoUrl,
    coverUrl,
    status,
    deliveryRadiusKm,
  );
}

/// Lifecycle status of a restaurant (PF-DOC-13 `restaurants.status`).
enum RestaurantStatus { pending, active, suspended, rejected }

/// Helpers for mapping DB text status <-> enum.
extension RestaurantStatusX on RestaurantStatus {
  String get dbValue => switch (this) {
    RestaurantStatus.pending => 'pending',
    RestaurantStatus.active => 'active',
    RestaurantStatus.suspended => 'suspended',
    RestaurantStatus.rejected => 'rejected',
  };

  static RestaurantStatus fromDb(String? value) {
    return switch (value) {
      'active' => RestaurantStatus.active,
      'suspended' => RestaurantStatus.suspended,
      'rejected' => RestaurantStatus.rejected,
      _ => RestaurantStatus.pending,
    };
  }
}
