import 'package:discovery_feature/discovery_feature.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_data/pare_data.dart';
import 'package:test/test.dart';

void main() {
  group('SupabaseDiscoveryRepository', () {
    test('nearbyRestaurants maps DTOs to summaries', () async {
      final fake = _FakeCatalog()
        ..nearby = [
          const RestaurantDto(
            id: 'r1',
            name: 'Warung Nusantara',
            slug: 'warung-nusantara',
            ratingAvg: 4.5,
            reviewCount: 8,
            deliveryRadiusKm: 5,
          ),
        ];
      final repo = SupabaseDiscoveryRepository(catalog: fake);

      final list = await repo.nearbyRestaurants(lat: -6.2, lng: 106.8);
      expect(list.single.name, 'Warung Nusantara');
      expect(list.single.ratingAvg, 4.5);
      expect(list.single.reviewCount, 8);
    });

    test(
      'restaurantDetail builds menu with category names and Money price',
      () async {
        final fake = _FakeCatalog()
          ..restaurant = const RestaurantDto(
            id: 'r1',
            name: 'Warung Nusantara',
            slug: 'warung-nusantara',
          )
          ..categories = [
            const MenuCategoryDto(
              id: 'c1',
              restaurantId: 'r1',
              name: 'Main',
              sortOrder: 1,
            ),
          ]
          ..items = [
            const MenuItemDto(
              id: 'm1',
              restaurantId: 'r1',
              categoryId: 'c1',
              name: 'Rendang',
              price: 85000,
            ),
          ];
        final repo = SupabaseDiscoveryRepository(catalog: fake);

        final detail = await repo.restaurantDetail('r1');
        expect(detail, isNotNull);
        expect(detail!.restaurant.name, 'Warung Nusantara');
        final item = detail.menu.single;
        expect(item.name, 'Rendang');
        expect(item.price, Money.fromRupiah(85000));
        expect(item.categoryName, 'Main');
      },
    );

    test('restaurantDetail returns null for a missing restaurant', () async {
      final fake = _FakeCatalog();
      final repo = SupabaseDiscoveryRepository(catalog: fake);
      expect(await repo.restaurantDetail('missing'), isNull);
    });

    test(
      'restaurantDetail maps uncategorised items and optional fields',
      () async {
        final fake = _FakeCatalog()
          ..restaurant = const RestaurantDto(
            id: 'r1',
            name: 'Soto Enak',
            slug: 'soto-enak',
            description: 'Khas Semarang',
            logoUrl: 'logo.png',
            coverUrl: 'cover.png',
            ratingAvg: 4.9,
            reviewCount: 120,
            deliveryRadiusKm: 7,
          )
          ..items = [
            const MenuItemDto(
              id: 'm1',
              restaurantId: 'r1',
              name: 'Soto Ayam',
              price: 25000,
              description: 'Dengan nasi',
              imageUrl: 'item.png',
            ),
          ];
        final repo = SupabaseDiscoveryRepository(catalog: fake);

        final detail = await repo.restaurantDetail('r1');
        expect(detail, isNotNull);
        expect(detail!.restaurant.description, 'Khas Semarang');
        expect(detail.restaurant.logoUrl, 'logo.png');
        expect(detail.restaurant.coverUrl, 'cover.png');
        expect(detail.restaurant.ratingAvg, 4.9);
        expect(detail.restaurant.reviewCount, 120);
        expect(detail.restaurant.deliveryRadiusKm, 7);

        final item = detail.menu.single;
        expect(item.categoryName, isNull);
        expect(item.description, 'Dengan nasi');
        expect(item.imageUrl, 'item.png');
      },
    );

    test('defaults to a real data source when none is injected', () {
      final repo = SupabaseDiscoveryRepository();
      expect(repo, isNotNull);
    });
  });
}

class _FakeCatalog extends SupabaseCatalogDataSource {
  List<RestaurantDto> nearby = const [];
  RestaurantDto? restaurant;
  List<MenuCategoryDto> categories = const [];
  List<MenuItemDto> items = const [];

  @override
  Future<List<RestaurantDto>> nearbyRestaurants({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async {
    return nearby;
  }

  @override
  Future<RestaurantDto?> restaurantById(String restaurantId) async =>
      restaurant;

  @override
  Future<({List<MenuCategoryDto> categories, List<MenuItemDto> items})>
  menuForRestaurant(String restaurantId) async {
    return (categories: categories, items: items);
  }
}
