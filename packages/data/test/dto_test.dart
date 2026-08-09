import 'package:pare_data/pare_data.dart';
import 'package:test/test.dart';

void main() {
  group('RestaurantDto', () {
    test('maps a database row', () {
      final dto = RestaurantDto.fromMap(<String, dynamic>{
        'id': 'r1',
        'name': 'Warung Nusantara',
        'slug': 'warung-nusantara',
        'status': 'active',
        'rating_avg': 4.5,
        'review_count': 12,
        'delivery_radius_km': 7.5,
      });
      expect(dto.id, 'r1');
      expect(dto.name, 'Warung Nusantara');
      expect(dto.status, 'active');
      expect(dto.ratingAvg, 4.5);
      expect(dto.reviewCount, 12);
      expect(dto.deliveryRadiusKm, 7.5);
    });

    test('round-trips through toMap', () {
      const dto = RestaurantDto(
        id: 'r1',
        name: 'Warung Nusantara',
        slug: 'warung-nusantara',
        description: 'Nasi padang',
        logoUrl: 'https://cdn/logo.png',
        status: 'pending',
      );
      final restored = RestaurantDto.fromMap(dto.toMap());
      expect(restored.id, dto.id);
      expect(restored.name, dto.name);
      expect(restored.slug, dto.slug);
      expect(restored.description, dto.description);
      expect(restored.logoUrl, dto.logoUrl);
      expect(restored.status, dto.status);
    });
  });

  group('MenuItemDto', () {
    test('defaults availability to true and price to 0', () {
      final dto = MenuItemDto.fromMap(<String, dynamic>{
        'id': 'm1',
        'restaurant_id': 'r1',
        'name': 'Rendang',
      });
      expect(dto.isAvailable, isTrue);
      expect(dto.price, 0);
      expect(dto.categoryId, isNull);
    });

    test('keeps bigint price and flags', () {
      final dto = MenuItemDto.fromMap(<String, dynamic>{
        'id': 'm1',
        'restaurant_id': 'r1',
        'category_id': 'c1',
        'name': 'Rendang',
        'price': 85000,
        'is_available': false,
        'is_featured': true,
      });
      expect(dto.price, 85000);
      expect(dto.isAvailable, isFalse);
      expect(dto.isFeatured, isTrue);
    });
  });

  group('ProfileDto', () {
    test('maps a profile row and defaults role', () {
      final dto = ProfileDto.fromMap(<String, dynamic>{
        'id': 'u1',
        'full_name': 'Budi',
        'phone': '081234567890',
        'avatar_url': 'https://cdn/avatar.png',
      });
      expect(dto.role, 'customer');
      expect(dto.fullName, 'Budi');
      expect(dto.phone, '081234567890');
      expect(dto.avatarUrl, 'https://cdn/avatar.png');
    });

    test('round-trips through toMap', () {
      const dto = ProfileDto(
        id: 'u1',
        role: 'business',
        fullName: 'Budi',
        phone: '081234567890',
        status: 'active',
      );
      final restored = ProfileDto.fromMap(dto.toMap());
      expect(restored.id, dto.id);
      expect(restored.role, dto.role);
      expect(restored.fullName, dto.fullName);
      expect(restored.phone, dto.phone);
    });
  });

  group('AuthSessionDto', () {
    test('reads role from app_metadata', () {
      final dto = AuthSessionDto.fromMap(<String, dynamic>{
        'sub': 'u1',
        'email': 'a@b.com',
        'app_metadata': <String, dynamic>{'role': 'business'},
      });
      expect(dto.userId, 'u1');
      expect(dto.role, 'business');
    });

    test('falls back to customer when role is absent', () {
      final dto = AuthSessionDto.fromMap(<String, dynamic>{
        'sub': 'u1',
        'email': 'a@b.com',
      });
      expect(dto.role, 'customer');
    });

    test('reads the phone number and defaults to empty', () {
      final withPhone = AuthSessionDto.fromMap(<String, dynamic>{
        'sub': 'u1',
        'email': 'a@b.com',
        'phone': '+6281200000001',
      });
      expect(withPhone.phone, '+6281200000001');

      final noPhone = AuthSessionDto.fromMap(<String, dynamic>{
        'sub': 'u1',
        'email': 'a@b.com',
      });
      expect(noPhone.phone, isEmpty);
    });
  });

  group('AuthUserDto', () {
    test('carries id, email and optional role', () {
      const user = AuthUserDto(id: 'u1', email: 'a@b.com');
      const merchant = AuthUserDto(
        id: 'u2',
        email: 'b@c.com',
        role: 'business',
      );
      expect(user.id, 'u1');
      expect(user.role, isNull);
      expect(merchant.role, 'business');
    });
  });

  group('MenuCategoryDto', () {
    test('maps a row with defaults', () {
      final dto = MenuCategoryDto.fromMap(<String, dynamic>{
        'id': 'c1',
        'restaurant_id': 'r1',
        'name': 'Main',
      });
      expect(dto.id, 'c1');
      expect(dto.restaurantId, 'r1');
      expect(dto.name, 'Main');
      expect(dto.sortOrder, 0);
    });

    test('round-trips through toMap', () {
      const dto = MenuCategoryDto(
        id: 'c1',
        restaurantId: 'r1',
        name: 'Main',
        sortOrder: 2,
      );
      final restored = MenuCategoryDto.fromMap(dto.toMap());
      expect(restored.id, dto.id);
      expect(restored.restaurantId, dto.restaurantId);
      expect(restored.name, dto.name);
      expect(restored.sortOrder, dto.sortOrder);
    });
  });

  group('MenuItemDto toMap', () {
    test('serialises write-side fields', () {
      const dto = MenuItemDto(
        id: 'm1',
        restaurantId: 'r1',
        categoryId: 'c1',
        name: 'Rendang',
        description: 'Pedas',
        price: 85000,
        imageUrl: 'https://cdn/r.png',
        isAvailable: false,
        isFeatured: true,
        sortOrder: 3,
      );
      final map = dto.toMap();
      expect(map['restaurant_id'], 'r1');
      expect(map['category_id'], 'c1');
      expect(map['name'], 'Rendang');
      expect(map['description'], 'Pedas');
      expect(map['price'], 85000);
      expect(map['image_url'], 'https://cdn/r.png');
      expect(map['is_available'], isFalse);
      expect(map['is_featured'], isTrue);
      expect(map['sort_order'], 3);
    });
  });

  group('MenuItemOptionDto', () {
    test('maps choices from a row', () {
      final dto = MenuItemOptionDto.fromMap(<String, dynamic>{
        'id': 'o1',
        'menu_item_id': 'm1',
        'group_name': 'Level Pedas',
        'is_required': true,
        'choices': <Map<String, dynamic>>[
          {'label': 'Sedang', 'price_adjust': 0, 'max_select': 1},
        ],
      });
      expect(dto.id, 'o1');
      expect(dto.menuItemId, 'm1');
      expect(dto.groupName, 'Level Pedas');
      expect(dto.isRequired, isTrue);
      expect(dto.choices, hasLength(1));
      expect(dto.choices.single['label'], 'Sedang');
    });

    test('defaults choices to empty when absent', () {
      final dto = MenuItemOptionDto.fromMap(<String, dynamic>{
        'id': 'o1',
        'menu_item_id': 'm1',
        'group_name': 'Topping',
      });
      expect(dto.isRequired, isFalse);
      expect(dto.choices, isEmpty);
    });

    test('round-trips through toMap', () {
      const dto = MenuItemOptionDto(
        id: 'o1',
        menuItemId: 'm1',
        groupName: 'Topping',
        isRequired: true,
        choices: [
          {'label': 'Keju', 'price_adjust': 5000, 'max_select': 2},
        ],
      );
      final map = dto.toMap();
      expect(map['menu_item_id'], 'm1');
      expect(map['group_name'], 'Topping');
      expect(map['is_required'], isTrue);
      final restored = MenuItemOptionDto.fromMap(map);
      expect(restored.groupName, dto.groupName);
      expect(restored.choices, dto.choices);
    });
  });
}
