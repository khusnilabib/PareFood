/// Default [AuthRepository] implementation backed by `pare_data` (PF-DOC-11
/// §3.1 / PF-DOC-10 §3.2). The app composition root may override
/// [authRepositoryProvider] with its own implementation; tests override it as
/// the FL-R04 seam. This adapter only touches `pare_data` (MO-R02a).
library;

import 'package:pare_data/pare_data.dart';

import '../domain/auth_session.dart';
import 'auth_repository.dart';

/// Adapts the feature-agnostic [SupabaseAuthDataSource] to [AuthRepository].
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository([SupabaseAuthDataSource? dataSource])
    : _dataSource = dataSource ?? SupabaseAuthDataSource();

  final SupabaseAuthDataSource _dataSource;

  @override
  Stream<AuthSession?> watchSession() {
    return _dataSource.watchSession().map(
      (dto) => dto == null ? null : _toSession(dto),
    );
  }

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final dto = await _dataSource.signInWithEmail(
      email: email,
      password: password,
    );
    return _toSession(dto);
  }

  @override
  Future<AuthOutcome> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final result = await _dataSource.signUpWithEmail(
      email: email,
      password: password,
      role: 'customer',
    );
    return switch (result) {
      AuthSignUpResult.success => AuthOutcome.success,
      AuthSignUpResult.emailInUse => AuthOutcome.emailInUse,
      AuthSignUpResult.failure => AuthOutcome.failure,
    };
  }

  @override
  Future<void> sendPhoneOtp(String phone) {
    return _dataSource.sendPhoneOtp(phone);
  }

  @override
  Future<AuthSession> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    final dto = await _dataSource.verifyPhoneOtp(phone: phone, token: token);
    return _toSession(dto);
  }

  @override
  Future<void> requestPasswordReset(String email) {
    return _dataSource.resetPasswordForEmail(email);
  }

  @override
  Future<void> signOut() => _dataSource.signOut();

  AuthSession _toSession(AuthSessionDto dto) {
    return AuthSession(
      userId: dto.userId,
      email: dto.email,
      phone: dto.phone,
      role: dto.role,
    );
  }
}
