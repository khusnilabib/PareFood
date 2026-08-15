import 'dart:async';

import 'package:auth_feature/auth_feature.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthSession', () {
    test('is signed in only when it has a user id', () {
      const session = AuthSession(userId: 'u1', email: 'a@b.com');
      const empty = AuthSession(userId: '', email: 'a@b.com');
      expect(session.isSignedIn, isTrue);
      expect(empty.isSignedIn, isFalse);
    });

    test('compares by value', () {
      const a = AuthSession(userId: 'u1', email: 'a@b.com');
      const b = AuthSession(userId: 'u1', email: 'a@b.com');
      const c = AuthSession(
        userId: 'u1',
        email: 'a@b.com',
        displayName: 'Budi',
      );
      const d = AuthSession(
        userId: 'u1',
        email: 'a@b.com',
        phone: '+6281200000001',
      );
      expect(a, b);
      expect(a == c, isFalse);
      expect(a == d, isFalse);
      expect(a.hashCode, b.hashCode);
    });

    test('defaults role to customer and supports role guards', () {
      const customer = AuthSession(userId: 'u1', email: 'a@b.com');
      expect(customer.role, 'customer');
      expect(customer.hasRole('customer'), isTrue);
      expect(customer.hasRole('business'), isFalse);

      const merchant = AuthSession(
        userId: 'u1',
        email: 'a@b.com',
        role: 'business',
      );
      expect(merchant.hasRole('business'), isTrue);
      expect(customer == merchant, isFalse);
    });
  });

  group('SignInWithEmail', () {
    test('rejects invalid email and short password', () {
      final useCase = SignInWithEmail(_FakeAuthRepository());
      expect(useCase.validate(email: 'nope', password: 'short'), isNotNull);
      expect(useCase.validate(email: 'a@b.com', password: 'short'), isNotNull);
      expect(
        useCase.validate(email: 'a@b.com', password: 'long-enough'),
        isNull,
      );
    });

    test('forwards valid credentials to the repository', () async {
      final useCase = SignInWithEmail(_FakeAuthRepository());
      final session = await useCase(email: 'a@b.com', password: 'long-enough');
      expect(session.isSignedIn, isTrue);
    });
  });

  group('SignUpWithEmail', () {
    test('validates email, password length and confirmation', () {
      final useCase = SignUpWithEmail(_FakeAuthRepository());
      expect(
        useCase.validate(
          email: 'nope',
          password: 'long-enough',
          confirmPassword: 'long-enough',
        ),
        isNotNull,
      );
      expect(
        useCase.validate(
          email: 'a@b.com',
          password: 'short',
          confirmPassword: 'short',
        ),
        isNotNull,
      );
      expect(
        useCase.validate(
          email: 'a@b.com',
          password: 'long-enough',
          confirmPassword: 'different',
        ),
        'Konfirmasi kata sandi tidak sama.',
      );
      expect(
        useCase.validate(
          email: 'a@b.com',
          password: 'long-enough',
          confirmPassword: 'long-enough',
        ),
        isNull,
      );
    });

    test('returns the repository outcome', () async {
      final repo = _FakeAuthRepository(signUpOutcome: AuthOutcome.emailInUse);
      final useCase = SignUpWithEmail(repo);

      final outcome = await useCase(email: 'a@b.com', password: 'long-enough');

      expect(outcome, AuthOutcome.emailInUse);
      expect(repo.signedUpEmail, 'a@b.com');
    });
  });

  group('SendPhoneOtp', () {
    test('rejects empty and invalid phone numbers', () {
      final useCase = SendPhoneOtp(_FakeAuthRepository());
      expect(useCase.validate(phone: ''), 'Nomor HP wajib diisi.');
      expect(useCase.validate(phone: '   '), 'Nomor HP wajib diisi.');
      expect(useCase.validate(phone: '12345'), isNotNull);
      expect(useCase.validate(phone: '081234567890'), isNull);
      expect(useCase.validate(phone: '+62 812-3456-7890'), isNull);
    });

    test('forwards the phone number to the repository', () async {
      final repo = _FakeAuthRepository();
      await SendPhoneOtp(repo)(phone: '081234567890');
      expect(repo.otpPhone, '081234567890');
    });
  });

  group('VerifyPhoneOtp', () {
    test('rejects empty and malformed codes', () {
      final useCase = VerifyPhoneOtp(_FakeAuthRepository());
      expect(useCase.validate(token: ''), 'Kode OTP wajib diisi.');
      expect(useCase.validate(token: '12345'), isNotNull);
      expect(useCase.validate(token: 'abcdef'), isNotNull);
      expect(useCase.validate(token: '123456'), isNull);
    });

    test('forwards phone and token to the repository', () async {
      final repo = _FakeAuthRepository();
      final session = await VerifyPhoneOtp(repo)(
        phone: '081234567890',
        token: '123456',
      );
      expect(repo.verifyPhone, '081234567890');
      expect(repo.verifyToken, '123456');
      expect(session.isSignedIn, isTrue);
    });
  });

  group('RequestPasswordReset', () {
    test('rejects invalid emails and accepts valid ones', () {
      final useCase = RequestPasswordReset(_FakeAuthRepository());
      expect(useCase.validate(email: 'not-an-email'), isNotNull);
      expect(useCase.validate(email: 'a@b.com'), isNull);
    });

    test('forwards the email to the repository', () async {
      final repo = _FakeAuthRepository();
      final useCase = RequestPasswordReset(repo);
      await useCase(email: 'a@b.com');
      expect(repo.requestedEmail, 'a@b.com');
    });
  });

  group('authSessionProvider', () {
    test('surfaces the session stream', () async {
      final repo = _FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final completer = Completer<AuthSession?>();
      final sub = container.listen<AsyncValue<AuthSession?>>(
        authSessionProvider,
        (previous, next) {
          if (next.hasValue && !completer.isCompleted) {
            completer.complete(next.value);
          }
        },
        fireImmediately: true,
      );
      addTearDown(sub.close);

      repo.emit(const AuthSession(userId: 'u1', email: 'a@b.com'));
      final session = await completer.future.timeout(
        const Duration(seconds: 5),
      );
      expect(session, isA<AuthSession>());
    });

    test('surfaces null while signed out', () async {
      final repo = _FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final completer = Completer<AuthSession?>();
      final sub = container.listen<AsyncValue<AuthSession?>>(
        authSessionProvider,
        (previous, next) {
          if (next.hasValue && !completer.isCompleted) {
            completer.complete(next.value);
          }
        },
        fireImmediately: true,
      );
      addTearDown(sub.close);

      repo.emit(null);
      final session = await completer.future.timeout(
        const Duration(seconds: 5),
      );
      expect(session, isNull);
    });
  });

  group('auth providers', () {
    test('default to the Supabase-backed repository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(authRepositoryProvider),
        isA<SupabaseAuthRepository>(),
      );
    });

    test('resolve the use cases from the repository override', () {
      final repo = _FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      expect(container.read(signInUseCaseProvider), isA<SignInWithEmail>());
      expect(container.read(signUpUseCaseProvider), isA<SignUpWithEmail>());
      expect(container.read(sendPhoneOtpProvider), isA<SendPhoneOtp>());
      expect(container.read(verifyPhoneOtpProvider), isA<VerifyPhoneOtp>());
      expect(
        container.read(requestPasswordResetProvider),
        isA<RequestPasswordReset>(),
      );
    });

    test('signOutProvider ends the session via the repository', () async {
      final repo = _FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(signOutProvider)();
      expect(repo.signOutCount, 1);
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.signUpOutcome = AuthOutcome.success});

  final AuthOutcome signUpOutcome;

  final StreamController<AuthSession?> _controller =
      StreamController<AuthSession?>();

  String? requestedEmail;
  String? signedUpEmail;
  String? otpPhone;
  String? verifyPhone;
  String? verifyToken;
  int signOutCount = 0;

  void emit(AuthSession? session) => _controller.add(session);

  @override
  Stream<AuthSession?> watchSession() => _controller.stream;

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return AuthSession(userId: 'u1', email: email);
  }

  @override
  Future<AuthOutcome> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    signedUpEmail = email;
    return signUpOutcome;
  }

  @override
  Future<void> sendPhoneOtp(String phone) async {
    otpPhone = phone;
  }

  @override
  Future<AuthSession> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    verifyPhone = phone;
    verifyToken = token;
    return AuthSession(userId: 'u1', email: '', phone: phone);
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    requestedEmail = email;
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
  }

  @override
  Future<List<String>> fetchRoles() async => ['customer'];

  @override
  Future<void> switchRole(String role) async {}
}
