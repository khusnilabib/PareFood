/// Menu domain models (PF-DOC-11 §3.2).
library;

import 'package:pare_core/pare_core.dart';

/// Price expressed in minor units (PF-DOC-13 DB-R02, PF-DOC-16 money).
typedef MenuPrice = Money;

/// A menu category grouping items.
class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.sortOrder = 0,
  });

  final String id;
  final String restaurantId;
  final String name;
  final int sortOrder;

  @override
  bool operator ==(Object other) {
    return other is MenuCategory &&
        other.id == id &&
        other.restaurantId == restaurantId &&
        other.name == name &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode => Object.hash(id, restaurantId, name, sortOrder);
}

/// A sellable menu item.
class MenuItem {
  const MenuItem({
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
  final MenuPrice price;
  final String? imageUrl;
  final bool isAvailable;
  final bool isFeatured;
  final int sortOrder;

  MenuItem copyWith({bool? isAvailable, int? price}) {
    return MenuItem(
      id: id,
      restaurantId: restaurantId,
      categoryId: categoryId,
      name: name,
      description: description,
      price: price == null ? this.price : Money.fromRupiah(price),
      imageUrl: imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured,
      sortOrder: sortOrder,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MenuItem &&
        other.id == id &&
        other.restaurantId == restaurantId &&
        other.categoryId == categoryId &&
        other.name == name &&
        other.description == description &&
        other.price == price &&
        other.imageUrl == imageUrl &&
        other.isAvailable == isAvailable &&
        other.isFeatured == isFeatured &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode => Object.hash(
    id,
    restaurantId,
    categoryId,
    name,
    description,
    price,
    imageUrl,
    isAvailable,
    isFeatured,
    sortOrder,
  );
}

/// Result of a CSV menu import (FR-MENU-003).
class MenuImportResult {
  const MenuImportResult({required this.created, required this.skipped});

  final int created;
  final int skipped;
}
