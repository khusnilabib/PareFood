import 'package:discovery_feature/discovery_feature.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pare_core/pare_core.dart';

void main() {
  group('RestaurantSummary', () {
    const base = RestaurantSummary(
      id: 'r1',
      name: 'Warung Nusantara',
      slug: 'warung-nusantara',
    );

    test('is value-equal when fields match', () {
      const other = RestaurantSummary(
        id: 'r1',
        name: 'Warung Nusantara',
        slug: 'warung-nusantara',
      );
      expect(base, other);
      expect(base.hashCode, other.hashCode);
    });

    test('differs when a required field changes', () {
      expect(
        const RestaurantSummary(id: 'r2', name: 'Warung', slug: 'warung'),
        isNot(equals(base)),
      );
      expect(
        const RestaurantSummary(id: 'r1', name: 'Lain', slug: 'warung'),
        isNot(equals(base)),
      );
      expect(
        const RestaurantSummary(id: 'r1', name: 'Warung Nusantara', slug: 'x'),
        isNot(equals(base)),
      );
    });

    test('nullable and numeric fields participate in equality', () {
      const full = RestaurantSummary(
        id: 'r1',
        name: 'Warung Nusantara',
        slug: 'warung-nusantara',
        logoUrl: 'logo',
        coverUrl: 'cover',
        description: 'desc',
        ratingAvg: 4.5,
        reviewCount: 8,
        deliveryRadiusKm: 7,
      );
      expect(base, isNot(equals(full)));
      expect(full, full);
      expect(full.hashCode, full.hashCode);
    });

    test('uses default rating and radius', () {
      const summary = RestaurantSummary(
        id: 'r1',
        name: 'Warung Nusantara',
        slug: 'warung-nusantara',
      );
      expect(summary.ratingAvg, 0);
      expect(summary.reviewCount, 0);
      expect(summary.deliveryRadiusKm, 5);
    });
  });

  group('DiscoveryMenuItem', () {
    final base = DiscoveryMenuItem(
      id: 'm1',
      name: 'Rendang',
      price: Money.fromRupiah(85000),
    );

    test('is value-equal when fields match', () {
      final same = DiscoveryMenuItem(
        id: 'm1',
        name: 'Rendang',
        price: Money.fromRupiah(85000),
      );
      expect(base, same);
      expect(base.hashCode, same.hashCode);
    });

    test('differs when any field changes', () {
      expect(
        DiscoveryMenuItem(
          id: 'm2',
          name: 'Rendang',
          price: Money.fromRupiah(85000),
        ),
        isNot(equals(base)),
      );
      expect(
        DiscoveryMenuItem(
          id: 'm1',
          name: 'Sate',
          price: Money.fromRupiah(85000),
        ),
        isNot(equals(base)),
      );
      expect(
        DiscoveryMenuItem(
          id: 'm1',
          name: 'Rendang',
          price: Money.fromRupiah(90000),
        ),
        isNot(equals(base)),
      );
      expect(
        DiscoveryMenuItem(
          id: 'm1',
          name: 'Rendang',
          price: Money.fromRupiah(85000),
          categoryName: 'Main',
        ),
        isNot(equals(base)),
      );
      expect(
        DiscoveryMenuItem(
          id: 'm1',
          name: 'Rendang',
          price: Money.fromRupiah(85000),
          description: 'Daging sapi',
        ),
        isNot(equals(base)),
      );
      expect(
        DiscoveryMenuItem(
          id: 'm1',
          name: 'Rendang',
          price: Money.fromRupiah(85000),
          imageUrl: 'img',
        ),
        isNot(equals(base)),
      );
      expect(
        DiscoveryMenuItem(
          id: 'm1',
          name: 'Rendang',
          price: Money.fromRupiah(85000),
          isAvailable: false,
        ),
        isNot(equals(base)),
      );
    });
  });

  group('RestaurantDetail', () {
    test('holds the summary and ordered menu', () {
      const restaurant = RestaurantSummary(
        id: 'r1',
        name: 'Warung Nusantara',
        slug: 'warung-nusantara',
      );
      final menu = [
        DiscoveryMenuItem(
          id: 'm1',
          name: 'Rendang',
          price: Money.fromRupiah(85000),
        ),
      ];
      final detail = RestaurantDetail(restaurant: restaurant, menu: menu);
      expect(detail.restaurant, restaurant);
      expect(detail.menu, hasLength(1));
      expect(detail.menu.single.name, 'Rendang');
    });
  });
}
