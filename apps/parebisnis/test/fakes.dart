/// Fake repositories for hermetic app tests (TS-R06: no network/Supabase).
library;

import 'dart:typed_data';

import 'package:auth_feature/auth_feature.dart';
import 'package:menu_feature/menu_feature.dart';
import 'package:merchant_feature/merchant_feature.dart';
import 'package:profile_feature/profile_feature.dart';

/// Records sign-out calls; the session stream is overridden separately.
class FakeAuthRepository implements AuthRepository {
  int signOutCount = 0;

  @override
  Stream<AuthSession?> watchSession() => const Stream.empty();

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<AuthOutcome> signUpWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> sendPhoneOtp(String phone) => throw UnimplementedError();

  @override
  Future<AuthSession> verifyPhoneOtp({
    required String phone,
    required String token,
  }) => throw UnimplementedError();

  @override
  Future<void> requestPasswordReset(String email) => throw UnimplementedError();

  @override
  Future<void> signOut() async {
    signOutCount++;
  }

  @override
  Future<List<String>> fetchRoles() async => ['business'];

  @override
  Future<void> switchRole(String role) async {}
}

/// Fixed list of owned restaurants; empty by default (onboarding path).
class FakeRestaurantRepository implements RestaurantRepository {
  FakeRestaurantRepository({this.restaurants = const []});

  final List<Restaurant> restaurants;

  @override
  Future<List<Restaurant>> myRestaurants() async => restaurants;

  @override
  Future<Restaurant> createRestaurant({
    required String name,
    required String description,
    required String slug,
    required double latitude,
    required double longitude,
    required int deliveryRadiusMeters,
  }) => throw UnimplementedError();

  @override
  Future<Restaurant> updateRestaurant({
    required String restaurantId,
    required String name,
    String? description,
    String? logoUrl,
    String? coverUrl,
  }) => throw UnimplementedError();

  @override
  Future<void> setHours({
    required String restaurantId,
    required int dayOfWeek,
    required String openTime,
    required String closeTime,
    bool isClosed = false,
  }) => throw UnimplementedError();

  @override
  Future<void> uploadDocument({
    required String restaurantId,
    required String fileName,
    required Uint8List bytes,
  }) => throw UnimplementedError();

  @override
  Future<void> submitDocument({
    required String docType,
    required String storagePath,
  }) => throw UnimplementedError();
}

/// Empty menu; enough to render the management page.
class FakeMenuRepository implements MenuRepository {
  @override
  Future<({List<MenuCategory> categories, List<MenuItem> items})> loadMenu({
    required String restaurantId,
  }) async => (categories: const <MenuCategory>[], items: const <MenuItem>[]);

  @override
  Future<MenuItem> upsertItem({
    required String restaurantId,
    String? id,
    String? categoryId,
    required String name,
    String? description,
    required int price,
    String? imageUrl,
    bool isAvailable = true,
  }) => throw UnimplementedError();

  @override
  Future<MenuItem> setAvailability({
    required String restaurantId,
    required String itemId,
    required bool isAvailable,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteItem(String itemId) => throw UnimplementedError();

  @override
  Future<MenuCategory> createCategory({
    required String restaurantId,
    required String name,
  }) => throw UnimplementedError();

  @override
  Future<void> updateCategory({
    required String categoryId,
    required String name,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteCategory(String categoryId) => throw UnimplementedError();

  @override
  Future<MenuImportResult> importCsv({
    required String restaurantId,
    required List<Map<String, String>> rows,
  }) => throw UnimplementedError();
}

/// Returns a fixed profile; other operations are not exercised here.
class FakeProfileRepository implements ProfileRepository {
  static const profile = UserProfile(
    id: 'u1',
    name: 'Budi Santoso',
    phone: '+6281200000001',
    email: 'budi@example.com',
  );

  @override
  Future<UserProfile> fetchProfile() async => profile;

  @override
  Future<UserProfile> updateProfile({
    required String name,
    String? phone,
    String? address,
  }) => throw UnimplementedError();

  @override
  Future<String> updateAvatar({
    required Uint8List bytes,
    required String fileName,
  }) => throw UnimplementedError();

  @override
  Future<void> requestPhoneChange(String newPhone) =>
      throw UnimplementedError();

  @override
  Future<void> resendPhoneChangeOtp(String newPhone) =>
      throw UnimplementedError();

  @override
  Future<UserProfile> verifyPhoneChange({
    required String newPhone,
    required String token,
  }) => throw UnimplementedError();
}
