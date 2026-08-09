/// Supabase-backed profile data source (PF-DOC-11 §3.3).
library;

import 'dart:typed_data';

import 'package:pare_core/pare_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_bootstrap.dart';
import 'dto/profile_dto.dart';

/// Concrete Supabase implementation of the profile surface.
class SupabaseProfileDataSource {
  SupabaseProfileDataSource({SupabaseClient? client}) : _override = client;

  /// Injected client, resolved lazily so constructing a data source does not
  /// require [SupabaseBootstrap] to be initialised (test seam).
  final SupabaseClient? _override;

  SupabaseClient get _client => _override ?? SupabaseBootstrap.client;

  /// Reads the signed-in user's own profile (RLS self policy).
  Future<ProfileDto> fetchProfile({required String userId}) async {
    final res = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (res == null) {
      throw const PareNotFoundException('Profile not found.');
    }
    return ProfileDto.fromMap(res);
  }

  /// Applies an edit to non-role fields of the caller's own profile.
  Future<ProfileDto> updateProfile({
    required String userId,
    required String fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final payload = <String, dynamic>{'full_name': fullName};
    if (phone != null && phone.isNotEmpty) payload['phone'] = phone;
    if (avatarUrl != null) payload['avatar_url'] = avatarUrl;

    final res = await _client
        .from('profiles')
        .update(payload)
        .eq('id', userId)
        .select()
        .maybeSingle();
    if (res == null) {
      throw const PareNotFoundException('Profile not found.');
    }
    return ProfileDto.fromMap(res);
  }

  /// Uploads an avatar and returns its public URL (bucket `avatars`, RLS owner
  /// write). Path `<user_id>/<file>` (SUP-R05).
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    final path = '$userId/$fileName';
    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return _client.storage.from('avatars').getPublicUrl(path);
  }
}
