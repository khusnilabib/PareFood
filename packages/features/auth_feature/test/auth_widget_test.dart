import 'dart:async';

import 'package:auth_feature/auth_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget signInApp(AuthRepository repo) {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: SignInPage()),
    );
  }

  Widget forgotApp(AuthRepository repo) {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: ForgotPasswordPage()),
    );
  }

  Finder emailField() => find.widgetWithText(TextFormField, 'Email');
  Finder passwordField() => find.widgetWithText(TextFormField, 'Kata sandi');

  group('SignInPage', () {
    testWidgets('renders the email and password fields', (tester) async {
      await tester.pumpWidget(signInApp(_FakeAuthRepository()));

      expect(find.text('Selamat datang di PareFood'), findsOneWidget);
      expect(emailField(), findsOneWidget);
      expect(passwordField(), findsOneWidget);
      expect(find.text('Masuk'), findsNWidgets(2));
    });

    testWidgets(
      'shows validation errors for an invalid email and short password',
      (tester) async {
        await tester.pumpWidget(signInApp(_FakeAuthRepository()));

        await tester.enterText(emailField(), 'nope');
        await tester.enterText(passwordField(), 'short');
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        expect(find.text('Format email tidak valid.'), findsOneWidget);
        expect(find.text('Minimal 8 karakter.'), findsOneWidget);
      },
    );

    testWidgets('signs in and shows a success message', (tester) async {
      final repo = _FakeAuthRepository();
      await tester.pumpWidget(signInApp(repo));

      await tester.enterText(emailField(), 'a@b.com');
      await tester.enterText(passwordField(), 'long-enough');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(repo.signedInEmail, 'a@b.com');
      expect(repo.signedInPassword, 'long-enough');
      expect(find.text('Berhasil masuk.'), findsOneWidget);
    });

    testWidgets('shows an error message when sign-in fails', (tester) async {
      final repo = _FakeAuthRepository(signInError: Exception('boom'));
      await tester.pumpWidget(signInApp(repo));

      await tester.enterText(emailField(), 'a@b.com');
      await tester.enterText(passwordField(), 'long-enough');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('Gagal masuk. Coba lagi.'), findsOneWidget);
    });

    testWidgets('disables the submit button while signing in', (tester) async {
      final completer = Completer<AuthSession>();
      final repo = _FakeAuthRepository()
        ..signInImpl = (email, password) => completer.future;
      await tester.pumpWidget(signInApp(repo));

      await tester.enterText(emailField(), 'a@b.com');
      await tester.enterText(passwordField(), 'long-enough');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      completer.complete(const AuthSession(userId: 'u1', email: 'a@b.com'));
      await tester.pumpAndSettle();
      expect(find.text('Berhasil masuk.'), findsOneWidget);
    });
  });

  group('ForgotPasswordPage', () {
    testWidgets('renders the email form', (tester) async {
      await tester.pumpWidget(forgotApp(_FakeAuthRepository()));

      expect(find.text('Lupa kata sandi'), findsOneWidget);
      expect(find.text('Masukkan email terdaftar Anda'), findsOneWidget);
      expect(
        find.text(
          'Kami akan mengirimkan tautan untuk mengatur ulang kata sandi Anda.',
        ),
        findsOneWidget,
      );
      expect(emailField(), findsOneWidget);
      expect(find.text('Kirim tautan reset'), findsOneWidget);
    });

    testWidgets('rejects an invalid email without calling the repository', (
      tester,
    ) async {
      final repo = _FakeAuthRepository();
      await tester.pumpWidget(forgotApp(repo));

      await tester.enterText(emailField(), 'not-an-email');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Format email tidak valid.'), findsOneWidget);
      expect(repo.requestedEmail, isNull);
    });

    testWidgets('requests a reset link and shows a success message', (
      tester,
    ) async {
      final repo = _FakeAuthRepository();
      await tester.pumpWidget(forgotApp(repo));

      await tester.enterText(emailField(), 'a@b.com');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(repo.requestedEmail, 'a@b.com');
      expect(
        find.text('Tautan reset telah dikirim ke email Anda.'),
        findsOneWidget,
      );
    });

    testWidgets('shows an error message when the request fails', (
      tester,
    ) async {
      final repo = _FakeAuthRepository(resetError: Exception('boom'));
      await tester.pumpWidget(forgotApp(repo));

      await tester.enterText(emailField(), 'a@b.com');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('Gagal mengirim. Coba lagi.'), findsOneWidget);
    });
  });

  group('PhoneSignInForm', () {
    Finder phoneField() => find.widgetWithText(TextFormField, 'Nomor HP');
    Finder otpField() => find.widgetWithText(TextFormField, 'Kode OTP');

    Future<void> openPhoneMode(WidgetTester tester, AuthRepository repo) async {
      await tester.pumpWidget(signInApp(repo));
      await tester.tap(find.text('Nomor HP'));
      await tester.pumpAndSettle();
    }

    testWidgets('switches between email and phone modes', (tester) async {
      await tester.pumpWidget(signInApp(_FakeAuthRepository()));

      expect(emailField(), findsOneWidget);
      expect(phoneField(), findsNothing);

      await tester.tap(find.text('Nomor HP'));
      await tester.pumpAndSettle();

      expect(phoneField(), findsOneWidget);
      expect(emailField(), findsNothing);
      expect(find.text('Kirim kode OTP'), findsOneWidget);
    });

    testWidgets('rejects an invalid phone without calling the repository', (
      tester,
    ) async {
      final repo = _FakeAuthRepository();
      await openPhoneMode(tester, repo);

      await tester.enterText(phoneField(), '12345');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Format nomor HP tidak valid.'), findsOneWidget);
      expect(repo.otpPhone, isNull);
    });

    testWidgets('sends the OTP and verifies the code', (tester) async {
      final repo = _FakeAuthRepository();
      await openPhoneMode(tester, repo);

      await tester.enterText(phoneField(), '081234567890');
      await tester.tap(find.text('Kirim kode OTP'));
      await tester.pumpAndSettle();

      expect(repo.otpPhone, '081234567890');
      expect(find.text('Kode OTP terkirim.'), findsOneWidget);
      expect(otpField(), findsOneWidget);

      await tester.enterText(otpField(), '123456');
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verifikasi'));
      await tester.pumpAndSettle();

      expect(repo.verifyPhone, '081234567890');
      expect(repo.verifyToken, '123456');
      expect(find.text('Berhasil masuk.'), findsOneWidget);
    });

    testWidgets('shows an error when sending the OTP fails', (tester) async {
      final repo = _FakeAuthRepository(sendOtpError: Exception('boom'));
      await openPhoneMode(tester, repo);

      await tester.enterText(phoneField(), '081234567890');
      await tester.tap(find.text('Kirim kode OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Gagal mengirim kode OTP. Coba lagi.'), findsOneWidget);
      expect(otpField(), findsNothing);
    });

    testWidgets('shows an error when verification fails', (tester) async {
      final repo = _FakeAuthRepository(verifyOtpError: Exception('boom'));
      await openPhoneMode(tester, repo);

      await tester.enterText(phoneField(), '081234567890');
      await tester.tap(find.text('Kirim kode OTP'));
      await tester.pumpAndSettle();

      await tester.enterText(otpField(), '123456');
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verifikasi'));
      await tester.pumpAndSettle();

      expect(find.text('Verifikasi gagal. Coba lagi.'), findsOneWidget);
    });

    testWidgets('can change the number before verifying', (tester) async {
      final repo = _FakeAuthRepository();
      await openPhoneMode(tester, repo);

      await tester.enterText(phoneField(), '081234567890');
      await tester.tap(find.text('Kirim kode OTP'));
      await tester.pumpAndSettle();
      expect(otpField(), findsOneWidget);

      await tester.tap(find.text('Ganti nomor'));
      await tester.pumpAndSettle();

      expect(otpField(), findsNothing);
      expect(find.text('Kirim kode OTP'), findsOneWidget);
      expect(tester.widget<TextFormField>(phoneField()).enabled, isTrue);
    });
  });

  group('RegisterPage', () {
    Widget registerApp(AuthRepository repo) {
      return ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: RegisterPage()),
      );
    }

    Finder emailField() => find.widgetWithText(TextFormField, 'Email');
    Finder passwordField() => find.widgetWithText(TextFormField, 'Kata sandi');
    Finder confirmField() =>
        find.widgetWithText(TextFormField, 'Konfirmasi kata sandi');

    testWidgets('registers and shows a success message', (tester) async {
      final repo = _FakeAuthRepository();
      await tester.pumpWidget(registerApp(repo));

      await tester.enterText(emailField(), 'a@b.com');
      await tester.enterText(passwordField(), 'long-enough');
      await tester.enterText(confirmField(), 'long-enough');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(repo.signUpEmail, 'a@b.com');
      expect(
        find.text('Pendaftaran berhasil. Cek email Anda untuk verifikasi.'),
        findsOneWidget,
      );
    });

    testWidgets('shows an error when the email is already registered', (
      tester,
    ) async {
      final repo = _FakeAuthRepository(signUpOutcome: AuthOutcome.emailInUse);
      await tester.pumpWidget(registerApp(repo));

      await tester.enterText(emailField(), 'a@b.com');
      await tester.enterText(passwordField(), 'long-enough');
      await tester.enterText(confirmField(), 'long-enough');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('Email sudah terdaftar.'), findsOneWidget);
    });

    testWidgets('shows validation errors for empty fields', (tester) async {
      await tester.pumpWidget(registerApp(_FakeAuthRepository()));

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Field wajib diisi.'), findsNWidgets(3));
    });

    testWidgets('shows an error when the confirmation does not match', (
      tester,
    ) async {
      final repo = _FakeAuthRepository();
      await tester.pumpWidget(registerApp(repo));

      await tester.enterText(emailField(), 'a@b.com');
      await tester.enterText(passwordField(), 'long-enough');
      await tester.enterText(confirmField(), 'different');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi kata sandi tidak sama.'), findsOneWidget);
      expect(repo.signUpEmail, isNull);
    });

    testWidgets('disables the submit button while registering', (tester) async {
      final completer = Completer<AuthOutcome>();
      final repo = _FakeAuthRepository()
        ..signUpImpl = (email, password) => completer.future;
      await tester.pumpWidget(registerApp(repo));

      await tester.enterText(emailField(), 'a@b.com');
      await tester.enterText(passwordField(), 'long-enough');
      await tester.enterText(confirmField(), 'long-enough');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      completer.complete(AuthOutcome.success);
      await tester.pumpAndSettle();
      expect(
        find.text('Pendaftaran berhasil. Cek email Anda untuk verifikasi.'),
        findsOneWidget,
      );
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.signInError,
    this.resetError,
    this.signUpOutcome = AuthOutcome.success,
    this.sendOtpError,
    this.verifyOtpError,
  });

  final Object? signInError;
  final Object? resetError;
  final AuthOutcome signUpOutcome;
  final Object? sendOtpError;
  final Object? verifyOtpError;

  Future<AuthSession> Function(String email, String password)? signInImpl;
  Future<AuthOutcome> Function(String email, String password)? signUpImpl;

  String? signedInEmail;
  String? signedInPassword;
  String? requestedEmail;
  String? signUpEmail;
  String? otpPhone;
  String? verifyPhone;
  String? verifyToken;

  @override
  Stream<AuthSession?> watchSession() => const Stream<AuthSession?>.empty();

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) {
    signedInEmail = email;
    signedInPassword = password;
    final impl = signInImpl;
    if (impl != null) return impl(email, password);
    final error = signInError;
    if (error != null) return Future<AuthSession>.error(error);
    return Future<AuthSession>.value(
      const AuthSession(userId: 'u1', email: 'a@b.com'),
    );
  }

  @override
  Future<AuthOutcome> signUpWithEmail({
    required String email,
    required String password,
  }) {
    signUpEmail = email;
    final impl = signUpImpl;
    if (impl != null) return impl(email, password);
    return Future<AuthOutcome>.value(signUpOutcome);
  }

  @override
  Future<void> sendPhoneOtp(String phone) async {
    otpPhone = phone;
    final error = sendOtpError;
    if (error != null) throw error;
  }

  @override
  Future<AuthSession> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    verifyPhone = phone;
    verifyToken = token;
    final error = verifyOtpError;
    if (error != null) throw error;
    return AuthSession(userId: 'u1', email: '', phone: phone);
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    requestedEmail = email;
    final error = resetError;
    if (error != null) throw error;
  }

  @override
  Future<void> signOut() async {}
}
