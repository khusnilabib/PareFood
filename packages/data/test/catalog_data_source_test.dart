/// Hermetic tests for [SupabaseCatalogDataSource] against a fake HTTP client.
library;

import 'dart:typed_data';

import 'package:pare_data/pare_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

import 'helpers/fake_supabase_http.dart';

void main() {
  late FakeSupabaseHttp http;
  late SupabaseClient client;
  late SupabaseCatalogDataSource dataSource;

  final restaurantRow = <String, dynamic>{
    'id': 'r1',
    'name': 'Warung Nusantara',
    'slug': 'warung-nusantara',
    'status': 'active',
    'rating_avg': 4.5,
    'review_count': 12,
    'delivery_radius_km': 7.5,
    'is_featured': true,
  };
  final categoryRow = <String, dynamic>{
    'id': 'c1',
    'restaurant_id': 'r1',
    'name': 'Main',
    'sort_order': 1,
  };
  final itemRow = <String, dynamic>{
    'id': 'i1',
    'restaurant_id': 'r1',
    'category_id': 'c1',
    'name': 'Nasi Goreng',
    'price': 25000,
    'is_available': true,
    'is_featured': false,
    'sort_order': 2,
  };

  setUp(() {
    http = FakeSupabaseHttp();
    client = SupabaseClient(
      http.baseUrl,
      'fake-anon-key',
      httpClient: http,
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
    dataSource = SupabaseCatalogDataSource(client: client);
  });

  tearDown(() async {
    await client.dispose();
  });

  group('read-side (discovery)', () {
    test('nearbyRestaurants calls the PostGIS RPC', () async {
      http.rpcRows = [restaurantRow];

      final result = await dataSource.nearbyRestaurants(
        lat: -6.2,
        lng: 106.8,
        radiusKm: 3,
      );

      expect(result, hasLength(1));
      expect(result.single.name, 'Warung Nusantara');
      expect(result.single.isFeatured, isTrue);

      final request = http.recorded.single;
      expect(request.url.path, '/rest/v1/rpc/nearby_restaurants');
      expect(request.json, containsPair('lat', -6.2));
      expect(request.json, containsPair('lng', 106.8));
      expect(request.json, containsPair('radius_km', 3));
    });

    test('restaurantById maps an active restaurant', () async {
      http.restaurantRows = [restaurantRow];

      final restaurant = await dataSource.restaurantById('r1');

      expect(restaurant, isNotNull);
      expect(restaurant!.slug, 'warung-nusantara');
      expect(restaurant.ratingAvg, 4.5);

      final request = http.recorded.single;
      expect(request.url.path, '/rest/v1/restaurants');
      expect(request.url.queryParameters['id'], 'eq.r1');
      expect(request.url.queryParameters['status'], 'eq.active');
    });

    test('restaurantById returns null when nothing matches', () async {
      http.restaurantRows = const [];

      expect(await dataSource.restaurantById('missing'), isNull);
    });

    test('menuForRestaurant loads categories and items', () async {
      http.categoryRows = [categoryRow];
      http.itemRows = [itemRow];

      final menu = await dataSource.menuForRestaurant('r1');

      expect(menu.categories, hasLength(1));
      expect(menu.categories.single.name, 'Main');
      expect(menu.items, hasLength(1));
      expect(menu.items.single.name, 'Nasi Goreng');
      expect(menu.items.single.price, 25000);

      final paths = http.recorded.map((r) => r.url.path).toList();
      expect(paths, contains('/rest/v1/menu_categories'));
      expect(paths, contains('/rest/v1/menu_items'));
    });
  });

  group('write-side (merchant)', () {
    test('createRestaurant posts a WKT point', () async {
      http.restaurantWriteRow = restaurantRow;

      final restaurant = await dataSource.createRestaurant(
        name: 'Warung Nusantara',
        description: 'Nasi padang',
        slug: 'warung-nusantara',
        latitude: -6.2,
        longitude: 106.8,
        deliveryRadiusMeters: 7500,
      );

      expect(restaurant.id, 'r1');
      final request = http.recorded.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/rest/v1/restaurants');
      expect(request.json, containsPair('location', 'POINT(106.8 -6.2)'));
      expect(request.json, containsPair('delivery_radius_km', 7.5));
    });

    test('updateRestaurant sends only provided fields', () async {
      http.restaurantWriteRow = restaurantRow;

      await dataSource.updateRestaurant(
        restaurantId: 'r1',
        name: 'Warung Baru',
        logoUrl: 'https://cdn/logo.png',
      );

      final body = http.recorded.single.json!;
      expect(body, containsPair('name', 'Warung Baru'));
      expect(body, containsPair('logo_url', 'https://cdn/logo.png'));
      expect(body.containsKey('description'), isFalse);
      expect(body.containsKey('cover_url'), isFalse);
    });

    test('setRestaurantHours upserts a hours row', () async {
      await dataSource.setRestaurantHours(
        restaurantId: 'r1',
        dayOfWeek: 1,
        openTime: '08:00',
        closeTime: '22:00',
      );

      final request = http.recorded.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/rest/v1/restaurant_hours');
      expect(request.json, containsPair('day_of_week', 1));
      expect(request.json, containsPair('is_closed', false));
    });

    test('restaurantsForOwner filters by owner_id', () async {
      http.restaurantRows = [restaurantRow];

      final result = await dataSource.restaurantsForOwner('owner-1');

      expect(result, hasLength(1));
      expect(
        http.recorded.single.url.queryParameters['owner_id'],
        'eq.owner-1',
      );
    });

    test('createCategory inserts and returns the row', () async {
      http.categoryWriteRow = categoryRow;

      final category = await dataSource.createCategory(
        restaurantId: 'r1',
        name: 'Main',
        sortOrder: 1,
      );

      expect(category.id, 'c1');
      expect(http.recorded.single.method, 'POST');
      expect(http.recorded.single.url.path, '/rest/v1/menu_categories');
    });

    test('updateCategory patches name and order', () async {
      http.categoryWriteRow = categoryRow;

      await dataSource.updateCategory(
        categoryId: 'c1',
        name: 'Drinks',
        sortOrder: 3,
      );

      final request = http.recorded.single;
      expect(request.method, 'PATCH');
      expect(request.url.queryParameters['id'], 'eq.c1');
      expect(request.json, containsPair('name', 'Drinks'));
      expect(request.json, containsPair('sort_order', 3));
    });

    test('deleteCategory deletes by id', () async {
      await dataSource.deleteCategory('c1');

      final request = http.recorded.single;
      expect(request.method, 'DELETE');
      expect(request.url.path, '/rest/v1/menu_categories');
      expect(request.url.queryParameters['id'], 'eq.c1');
    });

    test('upsertMenuItem posts the full payload', () async {
      http.itemWriteRow = itemRow;

      final item = await dataSource.upsertMenuItem(
        restaurantId: 'r1',
        categoryId: 'c1',
        name: 'Nasi Goreng',
        priceMinor: 25000,
        sortOrder: 2,
      );

      expect(item.id, 'i1');
      final request = http.recorded.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/rest/v1/menu_items');
      expect(request.json, containsPair('price', 25000));
      expect(request.json, containsPair('is_available', true));
    });

    test('setMenuItemAvailability toggles only availability', () async {
      http.itemWriteRow = itemRow;

      await dataSource.setMenuItemAvailability(
        itemId: 'i1',
        isAvailable: false,
      );

      final request = http.recorded.single;
      expect(request.method, 'PATCH');
      expect(request.url.queryParameters['id'], 'eq.i1');
      expect(request.json, containsPair('is_available', false));
    });

    test('deleteMenuItem deletes by id', () async {
      await dataSource.deleteMenuItem('i1');

      final request = http.recorded.single;
      expect(request.method, 'DELETE');
      expect(request.url.path, '/rest/v1/menu_items');
      expect(request.url.queryParameters['id'], 'eq.i1');
    });

    test('uploadMerchantDocument uploads to merchant-docs', () async {
      await dataSource.uploadMerchantDocument(
        restaurantId: 'r1',
        fileName: 'ktp.pdf',
        bytes: Uint8List.fromList(<int>[1, 2]),
      );

      final request = http.recorded.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/storage/v1/object/merchant-docs/r1/ktp.pdf');
      expect(request.headers['x-upsert'], 'true');
      expect(request.bodyText, contains('application/pdf'));
    });

    test('submitMerchantDocument registers the row', () async {
      await dataSource.submitMerchantDocument(
        userId: 'owner-1',
        docType: 'ktp',
        storagePath: 'merchant-docs/r1/ktp.pdf',
      );

      final request = http.recorded.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/rest/v1/merchant_documents');
      expect(request.json, containsPair('doc_type', 'ktp'));
    });
  });
}
