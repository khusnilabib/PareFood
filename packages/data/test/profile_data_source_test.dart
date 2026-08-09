/// Hermetic tests for [SupabaseProfileDataSource] against a fake HTTP client.
library;

import 'dart:typed_data';

import 'package:pare_core/pare_core.dart';
import 'package:pare_data/pare_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

import 'helpers/fake_supabase_http.dart';

void main() {
  late FakeSupabaseHttp http;
  late SupabaseClient client;
  late SupabaseProfileDataSource dataSource;

  final profileRow = <String, dynamic>{
    'id': 'user-1',
    'role': 'customer',
    'full_name': 'Budi Santoso',
    'phone': '+6281234567890',
    'avatar_url': 'https://cdn/avatar.png',
    'status': 'active',
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
    dataSource = SupabaseProfileDataSource(client: client);
  });

  tearDown(() async {
    await client.dispose();
  });

  group('fetchProfile', () {
    test('maps the own profile row', () async {
      http.profileRows = [profileRow];

      final profile = await dataSource.fetchProfile(userId: 'user-1');

      expect(profile.id, 'user-1');
      expect(profile.role, 'customer');
      expect(profile.fullName, 'Budi Santoso');
      expect(profile.phone, '+6281234567890');
      expect(profile.avatarUrl, 'https://cdn/avatar.png');
      expect(profile.status, 'active');

      final request = http.recorded.single;
      expect(request.method, 'GET');
      expect(request.url.path, '/rest/v1/profiles');
      expect(request.url.queryParameters['id'], 'eq.user-1');
      expect(request.url.queryParameters['select'], isNotNull);
    });

    test('throws PareNotFoundException when the row is missing', () {
      http.profileRows = const [];

      expect(
        () => dataSource.fetchProfile(userId: 'user-1'),
        throwsA(isA<PareNotFoundException>()),
      );
    });

    test('surfaces RLS/server errors untouched', () {
      http.errors['GET /rest/v1/profiles'] = const ApiError(403, {
        'message': 'permission denied for table profiles',
        'details': null,
        'hint': null,
        'code': '42501',
      });

      expect(
        () => dataSource.fetchProfile(userId: 'user-1'),
        throwsA(isA<PostgrestException>()),
      );
    });
  });

  group('updateProfile', () {
    test('patches name, phone and avatar', () async {
      http.profilePatchRow = profileRow;

      final profile = await dataSource.updateProfile(
        userId: 'user-1',
        fullName: 'Budi S.',
        phone: '+6281299998888',
        avatarUrl: 'https://cdn/new.png',
      );

      expect(profile.fullName, 'Budi Santoso');
      final request = http.recorded.single;
      expect(request.method, 'PATCH');
      expect(request.url.path, '/rest/v1/profiles');
      expect(request.url.queryParameters['id'], 'eq.user-1');
      expect(request.json, containsPair('full_name', 'Budi S.'));
      expect(request.json, containsPair('phone', '+6281299998888'));
      expect(request.json, containsPair('avatar_url', 'https://cdn/new.png'));
    });

    test('omits empty phone values from the payload', () async {
      http.profilePatchRow = profileRow;

      await dataSource.updateProfile(
        userId: 'user-1',
        fullName: 'Budi S.',
        phone: '',
      );

      final body = http.recorded.single.json!;
      expect(body.containsKey('phone'), isFalse);
      expect(body.containsKey('avatar_url'), isFalse);
    });

    test('throws PareNotFoundException when no row is updated', () {
      http.profilePatchRow = null;

      expect(
        () => dataSource.updateProfile(userId: 'user-1', fullName: 'Budi S.'),
        throwsA(isA<PareNotFoundException>()),
      );
    });
  });

  group('uploadAvatar', () {
    test('uploads to the avatars bucket and returns the public URL', () async {
      final url = await dataSource.uploadAvatar(
        userId: 'user-1',
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        fileName: 'avatar.png',
        contentType: 'image/png',
      );

      expect(
        url,
        '${http.baseUrl}/storage/v1/object/public/avatars/user-1/avatar.png',
      );

      final request = http.recorded.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/storage/v1/object/avatars/user-1/avatar.png');
      expect(request.headers['x-upsert'], 'true');
      // Multipart body carries the content type and the raw bytes.
      expect(request.bodyText, contains('image/png'));
    });

    test('defaults the content type to image/jpeg', () async {
      await dataSource.uploadAvatar(
        userId: 'user-1',
        bytes: Uint8List.fromList(<int>[9, 9]),
        fileName: 'a.jpg',
      );

      expect(http.recorded.single.bodyText, contains('image/jpeg'));
    });
  });
}
