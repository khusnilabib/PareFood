/// Catalog data transfer objects (PF-DOC-11 §3.3).
///
/// Mirrors the Sprint 1 table shapes from PF-DOC-13 §3.2 (restaurants, menu_*,
/// restaurant_hours). Money is `bigint` minor units (DB-R02); conversion to a
/// display model happens in the consuming feature.
library;

/// Restaurant read model (read-side, PF-DOC-14 §3.2).
class RestaurantDto {
  const RestaurantDto({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.coverUrl,
    this.status = 'active',
    this.ratingAvg = 0,
    this.reviewCount = 0,
    this.deliveryRadiusKm = 5,
    this.isFeatured = false,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? coverUrl;
  final String status;
  final double ratingAvg;
  final int reviewCount;
  final double deliveryRadiusKm;
  final bool isFeatured;

  factory RestaurantDto.fromMap(Map<String, dynamic> map) {
    return RestaurantDto(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
      description: map['description'] as String?,
      logoUrl: map['logo_url'] as String?,
      coverUrl: map['cover_url'] as String?,
      status: map['status'] as String? ?? 'active',
      ratingAvg: (map['rating_avg'] as num?)?.toDouble() ?? 0,
      reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
      deliveryRadiusKm: (map['delivery_radius_km'] as num?)?.toDouble() ?? 5,
      isFeatured: map['is_featured'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'name': name,
    'slug': slug,
    'description': description,
    'logo_url': logoUrl,
    'cover_url': coverUrl,
    'status': status,
    'rating_avg': ratingAvg,
    'review_count': reviewCount,
    'delivery_radius_km': deliveryRadiusKm,
    'is_featured': isFeatured,
  };
}

/// Menu category DTO (PF-DOC-13 menu_categories).
class MenuCategoryDto {
  const MenuCategoryDto({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.sortOrder = 0,
  });

  final String id;
  final String restaurantId;
  final String name;
  final int sortOrder;

  factory MenuCategoryDto.fromMap(Map<String, dynamic> map) {
    return MenuCategoryDto(
      id: map['id'] as String? ?? '',
      restaurantId: map['restaurant_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'restaurant_id': restaurantId,
    'name': name,
    'sort_order': sortOrder,
  };
}

/// Menu item DTO (PF-DOC-13 menu_items). Price is bigint minor units.
class MenuItemDto {
  const MenuItemDto({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.price,
    this.categoryId,
    this.description,
    this.imageUrl,
    this.isAvailable = true,
    this.isFeatured = false,
    this.sortOrder = 0,
  });

  final String id;
  final String restaurantId;
  final String? categoryId;
  final String name;
  final String? description;
  final int price;
  final String? imageUrl;
  final bool isAvailable;
  final bool isFeatured;
  final int sortOrder;

  factory MenuItemDto.fromMap(Map<String, dynamic> map) {
    return MenuItemDto(
      id: map['id'] as String? ?? '',
      restaurantId: map['restaurant_id'] as String? ?? '',
      categoryId: map['category_id'] as String?,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      price: (map['price'] as num?)?.toInt() ?? 0,
      imageUrl: map['image_url'] as String?,
      isAvailable: map['is_available'] as bool? ?? true,
      isFeatured: map['is_featured'] as bool? ?? false,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'restaurant_id': restaurantId,
    'category_id': categoryId,
    'name': name,
    'description': description,
    'price': price,
    'image_url': imageUrl,
    'is_available': isAvailable,
    'is_featured': isFeatured,
    'sort_order': sortOrder,
  };
}

/// Option group DTO (PF-DOC-13 menu_item_options).
class MenuItemOptionDto {
  const MenuItemOptionDto({
    required this.id,
    required this.menuItemId,
    required this.groupName,
    this.isRequired = false,
    this.choices = const <Map<String, dynamic>>[],
  });

  final String id;
  final String menuItemId;
  final String groupName;
  final bool isRequired;

  /// Array of {label, price_adjust, max_select} (PF-DOC-13).
  final List<Map<String, dynamic>> choices;

  factory MenuItemOptionDto.fromMap(Map<String, dynamic> map) {
    final rawChoices = map['choices'];
    return MenuItemOptionDto(
      id: map['id'] as String? ?? '',
      menuItemId: map['menu_item_id'] as String? ?? '',
      groupName: map['group_name'] as String? ?? '',
      isRequired: map['is_required'] as bool? ?? false,
      choices: rawChoices is List
          ? rawChoices.cast<Map<String, dynamic>>()
          : const [],
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'menu_item_id': menuItemId,
    'group_name': groupName,
    'is_required': isRequired,
    'choices': choices,
  };
}
