import 'dart:typed_data';

import 'package:merchant_feature/merchant_feature.dart';
import 'package:pare_data/pare_data.dart';
import 'package:test/test.dart';

void main() {
  group('RestaurantStatusX', () {
    test('maps DB values to enums', () {
      expect(RestaurantStatusX.fromDb('active'), RestaurantStatus.active);
      expect(RestaurantStatusX.fromDb('suspended'), RestaurantStatus.suspended);
      expect(RestaurantStatusX.fromDb('rejected'), RestaurantStatus.rejected);
      expect(RestaurantStatusX.fromDb(null), RestaurantStatus.pending);
      expect(RestaurantStatusX.fromDb('unknown'), RestaurantStatus.pending);
    });

    test('round-trips DB text', () {
      expect(RestaurantStatus.active.dbValue, 'active');
      expect(RestaurantStatus.pending.dbValue, 'pending');
      expect(RestaurantStatus.suspended.dbValue, 'suspended');
      expect(RestaurantStatus.rejected.dbValue, 'rejected');
    });
  });

  group('Restaurant value object', () {
    test('isActive reflects the status', () {
      const active = Restaurant(
        id: 'r1',
        name: 'N',
        slug: 'n',
        status: RestaurantStatus.active,
      );
      const pending = Restaurant(id: 'r1', name: 'N', slug: 'n');
      expect(active.isActive, isTrue);
      expect(pending.isActive, isFalse);
    });

    test('equality covers all fields', () {
      const a = Restaurant(
        id: 'r1',
        name: 'N',
        slug: 'n',
        description: 'd',
        logoUrl: 'l',
        coverUrl: 'c',
        status: RestaurantStatus.suspended,
        deliveryRadiusKm: 7.5,
      );
      const same = Restaurant(
        id: 'r1',
        name: 'N',
        slug: 'n',
        description: 'd',
        logoUrl: 'l',
        coverUrl: 'c',
        status: RestaurantStatus.suspended,
        deliveryRadiusKm: 7.5,
      );
      const different = Restaurant(id: 'r1', name: 'M', slug: 'n');
      expect(a, same);
      expect(a.hashCode, same.hashCode);
      expect(a, isNot(different));
      expect(a == Object(), isFalse);
    });
  });

  group('SupabaseRestaurantRepository', () {
    test('maps owner restaurants including status', () async {
      final fake = _FakeCatalog()
        ..owned = [
          const RestaurantDto(
            id: 'r1',
            name: 'Warung Nusantara',
            slug: 'warung-nusantara',
            status: 'pending',
            deliveryRadiusKm: 5,
          ),
        ];
      final repo = SupabaseRestaurantRepository(
        auth: _FakeAuth(),
        catalog: fake,
      );

      final restaurants = await repo.myRestaurants();
      expect(restaurants.single.name, 'Warung Nusantara');
      expect(restaurants.single.status, RestaurantStatus.pending);
      expect(restaurants.single.isActive, isFalse);
    });

    test('myRestaurants maps every restaurant field', () async {
      final fake = _FakeCatalog()
        ..owned = [
          const RestaurantDto(
            id: 'r1',
            name: 'Warung Nusantara',
            slug: 'warung-nusantara',
            description: 'Masakan Jawa',
            logoUrl: 'logo.png',
            coverUrl: 'cover.png',
            status: 'active',
            deliveryRadiusKm: 7.5,
          ),
        ];
      final repo = SupabaseRestaurantRepository(
        auth: _FakeAuth(),
        catalog: fake,
      );

      final r = (await repo.myRestaurants()).single;
      expect(r.id, 'r1');
      expect(r.description, 'Masakan Jawa');
      expect(r.logoUrl, 'logo.png');
      expect(r.coverUrl, 'cover.png');
      expect(r.status, RestaurantStatus.active);
      expect(r.deliveryRadiusKm, 7.5);
      expect(r.isActive, isTrue);
    });

    test('createRestaurant delegates and maps the created dto', () async {
      final fake = _FakeCatalog()
        ..created = const RestaurantDto(
          id: 'r9',
          name: 'Baru',
          slug: 'baru',
          status: 'pending',
        );
      final repo = SupabaseRestaurantRepository(
        auth: _FakeAuth(),
        catalog: fake,
      );

      final r = await repo.createRestaurant(
        name: 'Baru',
        description: 'Deskripsi',
        slug: 'baru',
        latitude: -6.2,
        longitude: 106.8,
        deliveryRadiusMeters: 4000,
      );
      expect(r.id, 'r9');
      expect(r.status, RestaurantStatus.pending);
      expect(fake.lastCreate?.name, 'Baru');
      expect(fake.lastCreate?.latitude, -6.2);
      expect(fake.lastCreate?.longitude, 106.8);
      expect(fake.lastCreate?.deliveryRadiusMeters, 4000);
    });

    test('updateRestaurant delegates optional profile fields', () async {
      final fake = _FakeCatalog()
        ..updated = const RestaurantDto(
          id: 'r1',
          name: 'Renamed',
          slug: 'warung-nusantara',
        );
      final repo = SupabaseRestaurantRepository(
        auth: _FakeAuth(),
        catalog: fake,
      );

      final r = await repo.updateRestaurant(
        restaurantId: 'r1',
        name: 'Renamed',
        description: 'd',
        logoUrl: 'l',
        coverUrl: 'c',
      );
      expect(r.name, 'Renamed');
      expect(fake.lastUpdate?.description, 'd');
      expect(fake.lastUpdate?.logoUrl, 'l');
      expect(fake.lastUpdate?.coverUrl, 'c');

      await repo.updateRestaurant(restaurantId: 'r1', name: 'x');
      expect(fake.lastUpdate?.description, isNull);
      expect(fake.lastUpdate?.logoUrl, isNull);
      expect(fake.lastUpdate?.coverUrl, isNull);
    });

    test('setHours delegates day, times and isClosed', () async {
      final fake = _FakeCatalog();
      final repo = SupabaseRestaurantRepository(
        auth: _FakeAuth(),
        catalog: fake,
      );

      await repo.setHours(
        restaurantId: 'r1',
        dayOfWeek: 2,
        openTime: '08:00',
        closeTime: '22:00',
        isClosed: true,
      );
      expect(fake.lastHours, (
        restaurantId: 'r1',
        day: 2,
        open: '08:00',
        close: '22:00',
        closed: true,
      ));

      await repo.setHours(
        restaurantId: 'r1',
        dayOfWeek: 3,
        openTime: '09:00',
        closeTime: '21:00',
      );
      expect(fake.lastHours?.day, 3);
      expect(fake.lastHours?.closed, isFalse);
    });

    test('uploadDocument delegates the raw bytes', () async {
      final fake = _FakeCatalog();
      final bytes = Uint8List.fromList([1, 2, 3]);
      final repo = SupabaseRestaurantRepository(
        auth: _FakeAuth(),
        catalog: fake,
      );

      await repo.uploadDocument(
        restaurantId: 'r1',
        fileName: 'ktp.pdf',
        bytes: bytes,
      );
      expect(fake.lastUpload?.restaurantId, 'r1');
      expect(fake.lastUpload?.fileName, 'ktp.pdf');
      expect(fake.lastUpload?.bytes, bytes);
    });

    test('submitDocument uses the signed-in user id', () async {
      final fake = _FakeCatalog();
      final repo = SupabaseRestaurantRepository(
        auth: _FakeAuth(),
        catalog: fake,
      );

      await repo.submitDocument(docType: 'nib', storagePath: 'r1/nib.pdf');
      expect(fake.lastSubmit, (
        userId: 'u1',
        docType: 'nib',
        path: 'r1/nib.pdf',
      ));
    });

    test('catalog errors propagate to the caller', () async {
      final fake = _FakeCatalog()..throwOnRead = true;
      final repo = SupabaseRestaurantRepository(
        auth: _FakeAuth(),
        catalog: fake,
      );

      await expectLater(repo.myRestaurants(), throwsA(isA<StateError>()));
    });
  });
}

class _FakeAuth extends SupabaseAuthDataSource {
  @override
  String get currentUserId => 'u1';
}

class _FakeCatalog extends SupabaseCatalogDataSource {
  List<RestaurantDto> owned = const [];
  RestaurantDto? created;
  RestaurantDto? updated;
  bool throwOnRead = false;

  ({
    String name,
    String description,
    String slug,
    double latitude,
    double longitude,
    int deliveryRadiusMeters,
  })?
  lastCreate;

  ({
    String restaurantId,
    String name,
    String? description,
    String? logoUrl,
    String? coverUrl,
  })?
  lastUpdate;

  ({String restaurantId, int day, String open, String close, bool closed})?
  lastHours;

  ({String restaurantId, String fileName, Uint8List bytes})? lastUpload;

  ({String userId, String docType, String path})? lastSubmit;

  @override
  Future<List<RestaurantDto>> restaurantsForOwner(String ownerId) async {
    if (throwOnRead) throw StateError('db down');
    return owned;
  }

  @override
  Future<RestaurantDto> createRestaurant({
    required String name,
    required String description,
    required String slug,
    required double latitude,
    required double longitude,
    required int deliveryRadiusMeters,
  }) async {
    lastCreate = (
      name: name,
      description: description,
      slug: slug,
      latitude: latitude,
      longitude: longitude,
      deliveryRadiusMeters: deliveryRadiusMeters,
    );
    return created ?? RestaurantDto(id: 'r1', name: name, slug: slug);
  }

  @override
  Future<RestaurantDto> updateRestaurant({
    required String restaurantId,
    required String name,
    String? description,
    String? logoUrl,
    String? coverUrl,
  }) async {
    lastUpdate = (
      restaurantId: restaurantId,
      name: name,
      description: description,
      logoUrl: logoUrl,
      coverUrl: coverUrl,
    );
    return updated ?? RestaurantDto(id: restaurantId, name: name, slug: 's');
  }

  @override
  Future<void> setRestaurantHours({
    required String restaurantId,
    required int dayOfWeek,
    required String openTime,
    required String closeTime,
    bool isClosed = false,
  }) async {
    lastHours = (
      restaurantId: restaurantId,
      day: dayOfWeek,
      open: openTime,
      close: closeTime,
      closed: isClosed,
    );
  }

  @override
  Future<void> uploadMerchantDocument({
    required String restaurantId,
    required String fileName,
    required Uint8List bytes,
    String contentType = 'application/pdf',
  }) async {
    lastUpload = (restaurantId: restaurantId, fileName: fileName, bytes: bytes);
  }

  @override
  Future<void> submitMerchantDocument({
    required String userId,
    required String docType,
    required String storagePath,
  }) async {
    lastSubmit = (userId: userId, docType: docType, path: storagePath);
  }
}
