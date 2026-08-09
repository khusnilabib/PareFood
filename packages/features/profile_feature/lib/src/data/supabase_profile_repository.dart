/// Default [ProfileRepository] implementation backed by `pare_data` (PF-DOC-11
/// §3.1 / PF-DOC-10 §3.2). The app composition root may override
/// [profileRepositoryProvider] with its own implementation; tests override it
/// as the FL-R04 seam. This adapter only touches `pare_data` (MO-R02a).
library;

import 'dart:typed_data';

import 'package:pare_data/pare_data.dart';

import '../domain/user_profile.dart';
import 'profile_repository.dart';

/// Adapts the feature-agnostic data sources to [ProfileRepository].
///
/// Sprint 1 persists `name`, `phone` and `avatar`; the free-text `address` is
/// accepted by the contract but not yet persisted (the `addresses` table needs
/// a PostGIS geocoded point, deferred to a later sprint).
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository({
    SupabaseAuthDataSource? auth,
    SupabaseProfileDataSource? profiles,
  }) : _auth = auth ?? SupabaseAuthDataSource(),
       _profiles = profiles ?? SupabaseProfileDataSource();

  final SupabaseAuthDataSource _auth;
  final SupabaseProfileDataSource _profiles;

  @override
  Future<UserProfile> fetchProfile() async {
    final dto = await _profiles.fetchProfile(userId: _auth.currentUserId);
    return _toProfile(dto);
  }

  @override
  Future<UserProfile> updateProfile({
    required String name,
    String? phone,
    String? address,
  }) async {
    final dto = await _profiles.updateProfile(
      userId: _auth.currentUserId,
      fullName: name,
      phone: phone,
    );
    return _toProfile(dto);
  }

  @override
  Future<String> updateAvatar({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _profiles.uploadAvatar(
      userId: _auth.currentUserId,
      bytes: bytes,
      fileName: fileName,
    );
  }

  @override
  Future<void> requestPhoneChange(String newPhone) {
    return _auth.requestPhoneChange(newPhone);
  }

  @override
  Future<void> resendPhoneChangeOtp(String newPhone) {
    return _auth.resendPhoneChangeOtp(newPhone);
  }

  @override
  Future<UserProfile> verifyPhoneChange({
    required String newPhone,
    required String token,
  }) async {
    final session = await _auth.verifyPhoneChange(
      newPhone: newPhone,
      token: token,
    );
    // Mirror the verified number into `profiles`; the session is the source
    // of truth, falling back to the entered number if GoTrue returns none.
    final current = await _profiles.fetchProfile(userId: _auth.currentUserId);
    final phone = session.phone.isNotEmpty ? session.phone : newPhone;
    final dto = await _profiles.updateProfile(
      userId: _auth.currentUserId,
      fullName: current.fullName,
      phone: phone,
    );
    return _toProfile(dto);
  }

  UserProfile _toProfile(ProfileDto dto) {
    return UserProfile(
      id: dto.id,
      name: dto.fullName,
      phone: dto.phone,
      email: _auth.currentUserEmail,
      avatarUrl: dto.avatarUrl,
    );
  }
}
