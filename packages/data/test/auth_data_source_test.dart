/// Hermetic tests for [SupabaseAuthDataSource] against a fake HTTP client
/// (no network; PF-DOC-20 §3.3 unit tier).
library;

import 'package:pare_core/pare_core.dart';
import 'package:pare_data/pare_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

import 'helpers/fake_supabase_http.dart';

void main() {
  late FakeSupabaseHttp http;
  late SupabaseClient client;
  late SupabaseAuthDataSource dataSource;

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
    dataSource = SupabaseAuthDataSource(client: client);
  });

  tearDown(() async {
    await client.dispose();
  });

  group('signInWithEmail', () {
    test('returns the session DTO mapped from GoTrue', () async {
      http.sessionJson = fakeSessionJson(role: 'business');

      final session = await dataSource.signInWithEmail(
        email: 'budi@example.com',
        password: 'secret',
      );

      expect(session.userId, 'user-1');
      expect(session.email, 'budi@example.com');
      expect(session.phone, '+6281234567890');
      expect(session.role, 'business');

      final request = http.recorded.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/auth/v1/token');
      expect(request.url.queryParameters['grant_type'], 'password');
      expect(request.json, containsPair('email', 'budi@example.com'));
      expect(request.json, containsPair('password', 'secret'));
    });

    test('maps invalid credentials to the typed message', () {
      http.errors['POST /auth/v1/token'] = const ApiError(400, {
        'msg': 'Invalid login credentials',
      });

      expect(
        () => dataSource.signInWithEmail(
          email: 'budi@example.com',
          password: 'wrong',
        ),
        throwsA(
          isA<PareAuthException>().having(
            (e) => e.message,
            'message',
            'The email or password you entered is incorrect.',
          ),
        ),
      );
    });

    test('rejects a response without a session', () {
      http.sessionJson = null;

      expect(
        () => dataSource.signInWithEmail(
          email: 'budi@example.com',
          password: 'secret',
        ),
        throwsA(
          isA<PareAuthException>().having(
            (e) => e.message,
            'message',
            'Your credentials could not be verified.',
          ),
        ),
      );
    });

    test('falls back to the generic message for unknown errors', () {
      http.errors['POST /auth/v1/token'] = const ApiError(400, {
        'msg': 'Something unexpected',
      });

      expect(
        () => dataSource.signInWithEmail(
          email: 'budi@example.com',
          password: 'secret',
        ),
        throwsA(
          isA<PareAuthException>().having(
            (e) => e.message,
            'message',
            'Sign-in failed. Please try again.',
          ),
        ),
      );
    });
  });

  group('signUpWithEmail', () {
    test('forwards the role in user metadata', () async {
      final result = await dataSource.signUpWithEmail(
        email: 'budi@example.com',
        password: 'secret',
        role: 'business',
      );

      expect(result, AuthSignUpResult.success);
      final request = http.recorded.single;
      expect(request.url.path, '/auth/v1/signup');
      expect(request.json?['data'], containsPair('role', 'business'));
    });

    test('detects an existing email', () {
      http.errors['POST /auth/v1/signup'] = const ApiError(400, {
        'msg': 'User already registered',
      });

      expect(
        dataSource.signUpWithEmail(
          email: 'budi@example.com',
          password: 'secret',
          role: 'customer',
        ),
        completion(AuthSignUpResult.emailInUse),
      );
    });

    test('maps other failures to PareAuthException', () {
      http.errors['POST /auth/v1/signup'] = const ApiError(429, {
        'msg': 'Rate limit exceeded',
      });

      expect(
        () => dataSource.signUpWithEmail(
          email: 'budi@example.com',
          password: 'secret',
          role: 'customer',
        ),
        throwsA(
          isA<PareAuthException>().having(
            (e) => e.message,
            'message',
            'Too many attempts. Please wait a moment and try again.',
          ),
        ),
      );
    });

    test('succeeds when confirmation is pending (no session)', () async {
      http.sessionJson = null;

      final result = await dataSource.signUpWithEmail(
        email: 'budi@example.com',
        password: 'secret',
        role: 'customer',
      );

      expect(result, AuthSignUpResult.success);
    });
  });

  group('sendPhoneOtp', () {
    test('normalises an Indonesian number to E.164', () async {
      await dataSource.sendPhoneOtp('0812-3456-7890');

      final request = http.recorded.single;
      expect(request.url.path, '/auth/v1/otp');
      expect(request.json, containsPair('phone', '+6281234567890'));
    });

    test('normalises a 62-prefixed number', () async {
      await dataSource.sendPhoneOtp('62812 3456 7890');

      expect(
        http.recorded.single.json,
        containsPair('phone', '+6281234567890'),
      );
    });

    test('keeps an already E.164 number', () async {
      await dataSource.sendPhoneOtp('+62 812-3456');

      expect(http.recorded.single.json, containsPair('phone', '+628123456'));
    });

    test('passes unknown prefixes through untouched', () async {
      await dataSource.sendPhoneOtp('8123456');

      expect(http.recorded.single.json, containsPair('phone', '8123456'));
    });

    test('maps failures to PareAuthException', () {
      http.errors['POST /auth/v1/otp'] = const ApiError(422, {
        'msg': 'Invalid phone number',
      });

      expect(
        () => dataSource.sendPhoneOtp('081234567890'),
        throwsA(
          isA<PareAuthException>().having(
            (e) => e.message,
            'message',
            'The phone number could not be verified.',
          ),
        ),
      );
    });
  });

  group('verifyPhoneOtp', () {
    test('verifies the sms code and returns the session', () async {
      final session = await dataSource.verifyPhoneOtp(
        phone: '0812-3456-7890',
        token: '123456',
      );

      expect(session.userId, 'user-1');
      final request = http.recorded.single;
      expect(request.url.path, '/auth/v1/verify');
      expect(request.json, containsPair('phone', '+6281234567890'));
      expect(request.json, containsPair('token', '123456'));
      expect(request.json, containsPair('type', 'sms'));
    });

    test('maps an expired code', () {
      http.errors['POST /auth/v1/verify'] = const ApiError(400, {
        'msg': 'Token has expired',
      });

      expect(
        () => dataSource.verifyPhoneOtp(phone: '081234567890', token: '1'),
        throwsA(
          isA<PareAuthException>().having(
            (e) => e.message,
            'message',
            'The OTP code has expired. Request a new one.',
          ),
        ),
      );
    });

    test('maps an incorrect code', () {
      http.errors['POST /auth/v1/verify'] = const ApiError(400, {
        'msg': 'Token not found',
      });

      expect(
        () => dataSource.verifyPhoneOtp(phone: '081234567890', token: '1'),
        throwsA(
          isA<PareAuthException>().having(
            (e) => e.message,
            'message',
            'The OTP code is incorrect. Please try again.',
          ),
        ),
      );
    });

    test('rejects a verification without a session', () {
      http.sessionJson = null;

      expect(
        () => dataSource.verifyPhoneOtp(phone: '081234567890', token: '1'),
        throwsA(
          isA<PareAuthException>().having(
            (e) => e.message,
            'message',
            'The OTP code could not be verified.',
          ),
        ),
      );
    });
  });

  group('phone change (FR-AUTH-005)', () {
    test('requestPhoneChange requires a session', () {
      expect(
        () => dataSource.requestPhoneChange('081299998888'),
        throwsA(isA<PareAuthException>()),
      );
      expect(http.recorded, isEmpty);
    });

    test('requestPhoneChange updates the user with an E.164 number', () async {
      await dataSource.signInWithEmail(
        email: 'budi@example.com',
        password: 'secret',
      );

      await dataSource.requestPhoneChange('0812 9999 8888');

      final request = http.recorded.last;
      expect(request.method, 'PUT');
      expect(request.url.path, '/auth/v1/user');
      expect(request.json, containsPair('phone', '+6281299998888'));
    });

    test('requestPhoneChange maps failures', () async {
      await dataSource.signInWithEmail(
        email: 'budi@example.com',
        password: 'secret',
      );
      http.errors['PUT /auth/v1/user'] = const ApiError(429, {
        'msg': 'Too many requests',
      });

      expect(
        () => dataSource.requestPhoneChange('081299998888'),
        throwsA(
          isA<PareAuthException>().having(
            (e) => e.message,
            'message',
            'Too many attempts. Please wait a moment and try again.',
          ),
        ),
      );
    });

    test('verifyPhoneChange confirms with the phone_change type', () async {
      http.sessionJson = fakeSessionJson(phone: '+6281299998888');

      final session = await dataSource.verifyPhoneChange(
        newPhone: '081299998888',
        token: '654321',
      );

      expect(session.phone, '+6281299998888');
      final request = http.recorded.single;
      expect(request.json, containsPair('phone', '+6281299998888'));
      expect(request.json, containsPair('type', 'phone_change'));
    });

    test('verifyPhoneChange maps an incorrect code', () {
      http.errors['POST /auth/v1/verify'] = const ApiError(400, {
        'msg': 'Token is invalid',
      });

      expect(
        () =>
            dataSource.verifyPhoneChange(newPhone: '081299998888', token: '0'),
        throwsA(
          isA<PareAuthException>().having(
            (e) => e.message,
            'message',
            'The OTP code is incorrect. Please try again.',
          ),
        ),
      );
    });

    test('resendPhoneChangeOtp resends to the normalised number', () async {
      await dataSource.resendPhoneChangeOtp('62812-9999-8888');

      final request = http.recorded.single;
      expect(request.url.path, '/auth/v1/resend');
      expect(request.json, containsPair('phone', '+6281299998888'));
      expect(request.json, containsPair('type', 'phone_change'));
    });

    test('resendPhoneChangeOtp maps failures', () {
      http.errors['POST /auth/v1/resend'] = const ApiError(429, {
        'msg': 'Rate limit exceeded',
      });

      expect(
        () => dataSource.resendPhoneChangeOtp('081299998888'),
        throwsA(isA<PareAuthException>()),
      );
    });
  });

  group('resetPasswordForEmail', () {
    test('posts a recovery request', () async {
      await dataSource.resetPasswordForEmail('budi@example.com');

      final request = http.recorded.single;
      expect(request.url.path, '/auth/v1/recover');
      expect(request.json, containsPair('email', 'budi@example.com'));
    });

    test('maps failures', () {
      http.errors['POST /auth/v1/recover'] = const ApiError(429, {
        'msg': 'Too many attempts',
      });

      expect(
        () => dataSource.resetPasswordForEmail('budi@example.com'),
        throwsA(isA<PareAuthException>()),
      );
    });
  });

  group('signOut', () {
    test('revokes the session server-side', () async {
      await dataSource.signInWithEmail(
        email: 'budi@example.com',
        password: 'secret',
      );

      await dataSource.signOut();

      final request = http.recorded.last;
      expect(request.url.path, '/auth/v1/logout');
      expect(dataSource.currentUserEmail, isEmpty);
    });

    test('completes without a session and without HTTP', () async {
      await dataSource.signOut();

      expect(http.recorded, isEmpty);
    });

    test('ignores 403s from the server', () async {
      await dataSource.signInWithEmail(
        email: 'budi@example.com',
        password: 'secret',
      );
      http.errors['POST /auth/v1/logout'] = const ApiError(403, {
        'msg': 'User not found',
      });

      await dataSource.signOut();

      expect(dataSource.currentUserEmail, isEmpty);
    });

    test('rethrows unexpected logout failures', () async {
      await dataSource.signInWithEmail(
        email: 'budi@example.com',
        password: 'secret',
      );
      http.errors['POST /auth/v1/logout'] = const ApiError(500, {
        'msg': 'Boom',
      });

      await expectLater(
        dataSource.signOut(),
        throwsA(isA<PareAuthException>()),
      );
    });
  });

  group('current user accessors', () {
    test('currentUserId throws when signed out', () {
      expect(() => dataSource.currentUserId, throwsA(isA<PareAuthException>()));
    });

    test('expose the signed-in user', () async {
      await dataSource.signInWithEmail(
        email: 'budi@example.com',
        password: 'secret',
      );

      expect(dataSource.currentUserId, 'user-1');
      expect(dataSource.currentUserEmail, 'budi@example.com');
    });
  });

  group('watchSession', () {
    test('emits the session on sign-in and null on sign-out', () async {
      final events = <AuthSessionDto?>[];
      final subscription = dataSource.watchSession().listen(events.add);
      addTearDown(subscription.cancel);

      await dataSource.signInWithEmail(
        email: 'budi@example.com',
        password: 'secret',
      );
      await pumpEventQueue();
      expect(events, hasLength(1));
      expect(events.first!.userId, 'user-1');

      await dataSource.signOut();
      await pumpEventQueue();
      expect(events, hasLength(2));
      expect(events.last, isNull);
    });
  });
}
