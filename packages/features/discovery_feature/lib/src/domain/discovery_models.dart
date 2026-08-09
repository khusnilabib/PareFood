/// Discovery domain models (PF-DOC-11 §3.2). Sprint 1 ships the read-side only
/// (plan §Scope: Discovery read-only; ordering/write flow deferred).
library;

import 'package:pare_core/pare_core.dart';

/// A restaurant card in the discovery list (nearest-first).
class RestaurantSummary {
  const RestaurantSummary({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.coverUrl,
    this.description,
    this.ratingAvg = 0,
    this.reviewCount = 0,
    this.deliveryRadiusKm = 5,
  });

  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? coverUrl;
  final String? description;
  final double ratingAvg;
  final int reviewCount;
  final double deliveryRadiusKm;

  @override
  bool operator ==(Object other) {
    return other is RestaurantSummary &&
        other.id == id &&
        other.name == name &&
        other.slug == slug &&
        other.logoUrl == logoUrl &&
        other.coverUrl == coverUrl &&
        other.description == description &&
        other.ratingAvg == ratingAvg &&
        other.reviewCount == reviewCount &&
        other.deliveryRadiusKm == deliveryRadiusKm;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    slug,
    logoUrl,
    coverUrl,
    description,
    ratingAvg,
    reviewCount,
    deliveryRadiusKm,
  );
}

/// A menu item shown on the restaurant detail screen.
class DiscoveryMenuItem {
  const DiscoveryMenuItem({
    required this.id,
    required this.name,
    required this.price,
    this.categoryName,
    this.description,
    this.imageUrl,
    this.isAvailable = true,
  });

  final String id;
  final String name;
  final Money price;
  final String? categoryName;
  final String? description;
  final String? imageUrl;
  final bool isAvailable;

  @override
  bool operator ==(Object other) {
    return other is DiscoveryMenuItem &&
        other.id == id &&
        other.name == name &&
        other.price == price &&
        other.categoryName == categoryName &&
        other.description == description &&
        other.imageUrl == imageUrl &&
        other.isAvailable == isAvailable;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    price,
    categoryName,
    description,
    imageUrl,
    isAvailable,
  );
}

/// Restaurant detail: summary + its menu.
class RestaurantDetail {
  const RestaurantDetail({required this.restaurant, required this.menu});

  final RestaurantSummary restaurant;

  /// Items grouped by category name, preserving sort order.
  final List<DiscoveryMenuItem> menu;
}
