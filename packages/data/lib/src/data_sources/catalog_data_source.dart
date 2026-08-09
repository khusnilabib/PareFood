/// Supabase-backed catalog data source (PF-DOC-11 §3.3).
///
/// Covers the Sprint 1 read-side (discovery) and merchant write-side (menu)
/// surfaces. All reads go through PostgREST + RLS (PF-DOC-14 §3.2); menu
/// writes are permitted for the owning restaurant only.
library;

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_bootstrap.dart';
import 'dto/catalog_dto.dart';

/// Concrete Supabase implementation of the catalog surface.
class SupabaseCatalogDataSource {
  SupabaseCatalogDataSource({SupabaseClient? client}) : _override = client;

  /// Injected client, resolved lazily so constructing a data source does not
  /// require [SupabaseBootstrap] to be initialised (test seam).
  final SupabaseClient? _override;

  SupabaseClient get _client => _override ?? SupabaseBootstrap.client;

  /// Restaurants sorted by proximity to a customer location via PostGIS
  /// `nearby_restaurants` RPC (FR-DISC-001, NFR-003).
  Future<List<RestaurantDto>> nearbyRestaurants({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async {
    final res = await _client.rpc<List<dynamic>>(
      'nearby_restaurants',
      params: <String, dynamic>{'lat': lat, 'lng': lng, 'radius_km': radiusKm},
    );
    return res.cast<Map<String, dynamic>>().map(RestaurantDto.fromMap).toList();
  }

  /// One restaurant by id (read-side detail).
  Future<RestaurantDto?> restaurantById(String restaurantId) async {
    final res = await _client
        .from('restaurants')
        .select()
        .eq('id', restaurantId)
        .eq('status', 'active')
        .maybeSingle();
    return res == null ? null : RestaurantDto.fromMap(res);
  }

  /// Full menu (categories + items) for a restaurant.
  Future<({List<MenuCategoryDto> categories, List<MenuItemDto> items})>
  menuForRestaurant(String restaurantId) async {
    final categoriesRes = await _client
        .from('menu_categories')
        .select()
        .eq('restaurant_id', restaurantId)
        .order('sort_order');
    final itemsRes = await _client
        .from('menu_items')
        .select()
        .eq('restaurant_id', restaurantId)
        .eq('is_available', true)
        .order('sort_order');

    final categories = (categoriesRes as List)
        .cast<Map<String, dynamic>>()
        .map(MenuCategoryDto.fromMap)
        .toList();
    final items = (itemsRes as List)
        .cast<Map<String, dynamic>>()
        .map(MenuItemDto.fromMap)
        .toList();
    return (categories: categories, items: items);
  }

  // ---------------------------------------------------------------------------
  // Merchant write-side (owner RLS; used by merchant/menu features).
  // ---------------------------------------------------------------------------

  Future<RestaurantDto> createRestaurant({
    required String name,
    required String description,
    required String slug,
    required double latitude,
    required double longitude,
    required int deliveryRadiusMeters,
  }) async {
    final res = await _client
        .from('restaurants')
        .insert(<String, dynamic>{
          'name': name,
          'description': description,
          'slug': slug,
          'location': 'POINT($longitude $latitude)',
          'delivery_radius_km': deliveryRadiusMeters / 1000,
        })
        .select()
        .single();
    return RestaurantDto.fromMap(res);
  }

  Future<RestaurantDto> updateRestaurant({
    required String restaurantId,
    required String name,
    String? description,
    String? logoUrl,
    String? coverUrl,
  }) async {
    final payload = <String, dynamic>{'name': name};
    if (description != null) payload['description'] = description;
    if (logoUrl != null) payload['logo_url'] = logoUrl;
    if (coverUrl != null) payload['cover_url'] = coverUrl;

    final res = await _client
        .from('restaurants')
        .update(payload)
        .eq('id', restaurantId)
        .select()
        .single();
    return RestaurantDto.fromMap(res);
  }

  Future<void> setRestaurantHours({
    required String restaurantId,
    required int dayOfWeek,
    required String openTime,
    required String closeTime,
    bool isClosed = false,
  }) async {
    await _client.from('restaurant_hours').upsert(<String, dynamic>{
      'restaurant_id': restaurantId,
      'day_of_week': dayOfWeek,
      'open_time': openTime,
      'close_time': closeTime,
      'is_closed': isClosed,
    });
  }

  /// Restaurants owned by [ownerId] (merchant my-restaurant lookup).
  Future<List<RestaurantDto>> restaurantsForOwner(String ownerId) async {
    final res = await _client
        .from('restaurants')
        .select()
        .eq('owner_id', ownerId);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(RestaurantDto.fromMap)
        .toList();
  }

  Future<MenuCategoryDto> updateCategory({
    required String categoryId,
    required String name,
    required int sortOrder,
  }) async {
    final res = await _client
        .from('menu_categories')
        .update(<String, dynamic>{'name': name, 'sort_order': sortOrder})
        .eq('id', categoryId)
        .select()
        .single();
    return MenuCategoryDto.fromMap(res);
  }

  Future<void> deleteCategory(String categoryId) async {
    await _client.from('menu_categories').delete().eq('id', categoryId);
  }

  Future<MenuCategoryDto> createCategory({
    required String restaurantId,
    required String name,
    required int sortOrder,
  }) async {
    final res = await _client
        .from('menu_categories')
        .insert(<String, dynamic>{
          'restaurant_id': restaurantId,
          'name': name,
          'sort_order': sortOrder,
        })
        .select()
        .single();
    return MenuCategoryDto.fromMap(res);
  }

  Future<MenuItemDto> upsertMenuItem({
    required String restaurantId,
    String? id,
    String? categoryId,
    required String name,
    String? description,
    required int priceMinor,
    String? imageUrl,
    bool isAvailable = true,
    bool isFeatured = false,
    int sortOrder = 0,
  }) async {
    final payload = <String, dynamic>{
      'id': ?id,
      'restaurant_id': restaurantId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': priceMinor,
      'image_url': imageUrl,
      'is_available': isAvailable,
      'is_featured': isFeatured,
      'sort_order': sortOrder,
    };
    final res = await _client
        .from('menu_items')
        .upsert(payload)
        .select()
        .single();
    return MenuItemDto.fromMap(res);
  }

  /// Toggles availability only (FR-MENU-002 out-of-stock), preserving the rest
  /// of the row.
  Future<MenuItemDto> setMenuItemAvailability({
    required String itemId,
    required bool isAvailable,
  }) async {
    final res = await _client
        .from('menu_items')
        .update(<String, dynamic>{'is_available': isAvailable})
        .eq('id', itemId)
        .select()
        .single();
    return MenuItemDto.fromMap(res);
  }

  Future<void> deleteMenuItem(String id) async {
    await _client.from('menu_items').delete().eq('id', id);
  }

  /// Merchant document for onboarding/verification (FR-ONB-001, docs bucket).
  Future<void> uploadMerchantDocument({
    required String restaurantId,
    required String fileName,
    required Uint8List bytes,
    String contentType = 'application/pdf',
  }) async {
    final path = '$restaurantId/$fileName';
    await _client.storage
        .from('merchant-docs')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
  }

  /// Registers a submitted verification document row (FR-ONB-001/002).
  /// Status starts `submitted`; only admins may change it (RLS).
  Future<void> submitMerchantDocument({
    required String userId,
    required String docType,
    required String storagePath,
  }) async {
    await _client.from('merchant_documents').insert(<String, dynamic>{
      'user_id': userId,
      'doc_type': docType,
      'storage_path': storagePath,
    });
  }
}
