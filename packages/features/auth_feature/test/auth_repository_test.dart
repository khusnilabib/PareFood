import 'dart:async';

import 'package:auth_feature/auth_feature.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_data/pare_data.dart';

void main() {
  group('SupabaseAuthRepository.watchSession', () {
    test('maps emitted DTOs and null back to sessions', () async {
      final fake = _FakeAuthDataSource();
      final repo = SupabaseAuthRepository(fake);
      final emitted = <AuthSession?>[];
      final sub = repo.watchSession().listen(emitted.add);
      addTearDown(sub.cancel);

      fake.controller.add(
        const AuthSessionDto(
          userId: 'u1',
          email: 'a@b.com',
          role: 'customer',
          phone: '+6281200000001',
        ),
      );
      fake.controller.add(null);
      await pumpEventQueue();

      expect(emitted, const <AuthSession?>[
        AuthSession(userId: 'u1', email: 'a@b.com', phone: '+6281200000001'),
        null,
      ]);
    });
  });

  group('SupabaseAuthRepository.signInWithEmail', () {
    test('maps the session DTO to an AuthSession', () async {
      final fake = _FakeAuthDataSource(
        session: const AuthSessionDto(
          userId: 'u1',
          email: 'a@b.com',
          role: 'customer',
        ),
      );
      final repo = SupabaseAuthRepository(fake);

      final session = await repo.signInWithEmail(
        email: 'a@b.com',
        password: 'secret-password',
      );

      expect(session, const AuthSession(userId: 'u1', email: 'a@b.com'));
      expect(fake.signedInEmail, 'a@b.com');
      expect(fake.signedInPassword, 'secret-password');
    });

    test('propagates data source errors', () async {
      final fake = _FakeAuthDataSource(
        signInError: const PareAuthException('invalid credentials'),
      );
      final repo = SupabaseAuthRepository(fake);

      expect(
        () => repo.signInWithEmail(email: 'a@b.com', password: 'wrong'),
        throwsA(isA<PareAuthException>()),
      );
    });
  });

  group('SupabaseAuthRepository.signUpWithEmail', () {
    test('maps every sign-up outcome', () async {
      const cases = <AuthSignUpResult, AuthOutcome>{
        AuthSignUpResult.success: AuthOutcome.success,
        AuthSignUpResult.emailInUse: AuthOutcome.emailInUse,
        AuthSignUpResult.failure: AuthOutcome.failure,
      };
      for (final entry in cases.entries) {
        final repo = SupabaseAuthRepository(
          _FakeAuthDataSource(signUpOutcome: entry.key),
        );
        expect(
          await repo.signUpWithEmail(
            email: 'a@b.com',
            password: 'secret-password',
          ),
          entry.value,
        );
      }
    });

    test('signs up with the customer role', () async {
      final fake = _FakeAuthDataSource();
      final repo = SupabaseAuthRepository(fake);

      await repo.signUpWithEmail(email: 'a@b.com', password: 'secret-password');

      expect(fake.signUpRole, 'customer');
    });
  });

  group('SupabaseAuthRepository.requestPasswordReset', () {
    test('forwards the email to the data source', () async {
      final fake = _FakeAuthDataSource();
      final repo = SupabaseAuthRepository(fake);

      await repo.requestPasswordReset('a@b.com');

      expect(fake.resetEmail, 'a@b.com');
    });
  });

  group('SupabaseAuthRepository.sendPhoneOtp', () {
    test('forwards the phone number to the data source', () async {
      final fake = _FakeAuthDataSource();
      final repo = SupabaseAuthRepository(fake);

      await repo.sendPhoneOtp('081234567890');

      expect(fake.otpPhone, '081234567890');
    });

    test('propagates data source errors', () async {
      final fake = _FakeAuthDataSource(
        sendOtpError: const PareAuthException('rate limit'),
      );
      final repo = SupabaseAuthRepository(fake);

      expect(
        () => repo.sendPhoneOtp('081234567890'),
        throwsA(isA<PareAuthException>()),
      );
    });
  });

  group('SupabaseAuthRepository.verifyPhoneOtp', () {
    test('maps the session DTO including the phone number', () async {
      final fake = _FakeAuthDataSource(
        session: const AuthSessionDto(
          userId: 'u1',
          email: '',
          role: 'customer',
          phone: '+6281200000001',
        ),
      );
      final repo = SupabaseAuthRepository(fake);

      final session = await repo.verifyPhoneOtp(
        phone: '+6281200000001',
        token: '123456',
      );

      expect(
        session,
        const AuthSession(userId: 'u1', email: '', phone: '+6281200000001'),
      );
      expect(fake.verifyPhone, '+6281200000001');
      expect(fake.verifyToken, '123456');
    });

    test('propagates data source errors', () async {
      final fake = _FakeAuthDataSource(
        verifyOtpError: const PareAuthException('expired'),
      );
      final repo = SupabaseAuthRepository(fake);

      expect(
        () => repo.verifyPhoneOtp(phone: '081234567890', token: '123456'),
        throwsA(isA<PareAuthException>()),
      );
    });
  });

  group('SupabaseAuthRepository.signOut', () {
    test('delegates to the data source', () async {
      final fake = _FakeAuthDataSource();
      final repo = SupabaseAuthRepository(fake);

      await repo.signOut();

      expect(fake.signOutCalled, isTrue);
    });
  });
}

class _FakeAuthDataSource extends SupabaseAuthDataSource {
  _FakeAuthDataSource({
    this.session,
    this.signInError,
    this.signUpOutcome = AuthSignUpResult.success,
    this.sendOtpError,
    this.verifyOtpError,
  });

  final AuthSessionDto? session;
  final Object? signInError;
  final AuthSignUpResult signUpOutcome;
  final Object? sendOtpError;
  final Object? verifyOtpError;

  final StreamController<AuthSessionDto?> controller =
      StreamController<AuthSessionDto?>.broadcast();

  String? signedInEmail;
  String? signedInPassword;
  String? signUpRole;
  String? resetEmail;
  String? otpPhone;
  String? verifyPhone;
  String? verifyToken;
  bool signOutCalled = false;

  @override
  Stream<AuthSessionDto?> watchSession() => controller.stream;

  @override
  Future<AuthSessionDto> signInWithEmail({
    required String email,
    required String password,
  }) async {
    signedInEmail = email;
    signedInPassword = password;
    final error = signInError;
    if (error != null) throw error;
    return session!;
  }

  @override
  Future<AuthSignUpResult> signUpWithEmail({
    required String email,
    required String password,
    required String role,
  }) async {
    signUpRole = role;
    return signUpOutcome;
  }

  @override
  Future<void> sendPhoneOtp(String phone) async {
    otpPhone = phone;
    final error = sendOtpError;
    if (error != null) throw error;
  }

  @override
  Future<AuthSessionDto> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    verifyPhone = phone;
    verifyToken = token;
    final error = verifyOtpError;
    if (error != null) throw error;
    return session!;
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {
    resetEmail = email;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}
