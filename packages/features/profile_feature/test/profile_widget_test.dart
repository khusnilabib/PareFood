import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pare_core/pare_core.dart';
import 'package:profile_feature/profile_feature.dart';

const _defaultProfile = UserProfile(
  id: 'u1',
  name: 'Budi Santoso',
  phone: '081234567890',
  email: 'budi@example.com',
);

final Uint8List _transparentPng = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  // Riverpod 3 auto-retries failed builds by default, which would silently
  // re-fetch past the error states these tests assert on.
  Duration? noRetry(int attempt, Object error) => null;

  Widget profileApp(ProfileRepository repo) {
    return ProviderScope(
      retry: noRetry,
      overrides: [profileRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: ProfilePage()),
    );
  }

  Widget editApp(
    ProfileRepository repo, {
    UserProfile profile = _defaultProfile,
  }) {
    return ProviderScope(
      retry: noRetry,
      overrides: [profileRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: EditProfilePage(profile: profile)),
    );
  }

  Widget headerApp(UserProfile profile) {
    return MaterialApp(
      home: Scaffold(body: ProfileHeader(profile: profile)),
    );
  }

  Future<void> mockImagePicker(WidgetTester tester, {String? path}) {
    const channel = MethodChannel('plugins.flutter.io/image_picker');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall call) async => call.method == 'pickImage' ? path : null,
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    });
    return Future<void>.value();
  }

  /// Fully dismisses the visible snackbar. The auto-hide timer is only
  /// created once the entry animation completes and the messenger rebuilds
  /// (scaffold.dart), so entry, hold and exit each need their own pumps.
  Future<void> dismissSnackBar(WidgetTester tester) async {
    await tester.pumpAndSettle(); // Entry finishes; rebuild starts the timer.
    await tester.pump(
      const Duration(seconds: 4, milliseconds: 100),
    ); // Timer fires.
    await tester.pumpAndSettle(); // Exit animation.
  }

  group('ProfilePage', () {
    testWidgets('data state shows the profile summary', (tester) async {
      await tester.pumpWidget(profileApp(_FakeProfileRepository()));
      await tester.pumpAndSettle();

      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('budi@example.com'), findsOneWidget);
      expect(find.text('Edit profil'), findsOneWidget);
      expect(find.text('Bantuan & Dukungan'), findsOneWidget);
    });

    testWidgets('loading state shows a spinner', (tester) async {
      final completer = Completer<UserProfile>();
      final repo = _FakeProfileRepository()..fetchImpl = () => completer.future;
      await tester.pumpWidget(profileApp(repo));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error state shows the typed message and a retry button', (
      tester,
    ) async {
      final repo = _FakeProfileRepository(
        fetchError: const PareAuthException('Not signed in.'),
      );
      await tester.pumpWidget(profileApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Not signed in.'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets('untyped errors fall back to the title and retry reloads', (
      tester,
    ) async {
      final repo = _FakeProfileRepository();
      var calls = 0;
      repo.fetchImpl = () async {
        calls++;
        if (calls == 1) throw Exception('boom');
        return repo.profile;
      };
      await tester.pumpWidget(profileApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Gagal memuat profil.'), findsOneWidget);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(repo.fetchCount, 2);
    });
  });

  group('EditProfilePage', () {
    testWidgets('edit entry opens the form and saving returns to the profile', (
      tester,
    ) async {
      final repo = _FakeProfileRepository();
      await tester.pumpWidget(profileApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit profil'));
      await tester.pumpAndSettle();
      expect(find.text('Simpan perubahan'), findsOneWidget);

      await tester.tap(find.text('Simpan perubahan'));
      await tester.pumpAndSettle();

      expect(find.text('Profil disimpan.'), findsOneWidget);
      expect(find.text('Edit profil'), findsOneWidget);
      expect(repo.updatedName, 'Budi Santoso');
    });

    testWidgets('loads the existing profile values', (tester) async {
      await tester.pumpWidget(editApp(_FakeProfileRepository()));
      await tester.pumpAndSettle();

      final name = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Nama'),
      );
      final phone = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Telepon'),
      );
      expect(name.controller!.text, 'Budi Santoso');
      expect(phone.controller!.text, '081234567890');
    });

    testWidgets('shows a validation error for an empty name', (tester) async {
      await tester.pumpWidget(editApp(_FakeProfileRepository()));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Nama'), ' ');
      await tester.tap(find.text('Simpan perubahan'));
      await tester.pump();

      expect(find.text('Field wajib diisi.'), findsOneWidget);
    });

    testWidgets('keeps the phone read-only behind the OTP change flow', (
      tester,
    ) async {
      await tester.pumpWidget(editApp(_FakeProfileRepository()));
      await tester.pumpAndSettle();

      final phone = tester.widget<TextField>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Telepon'),
          matching: find.byType(TextField),
        ),
      );
      expect(phone.readOnly, isTrue);
      expect(find.text('Ganti nomor HP'), findsOneWidget);
    });

    testWidgets('shows an error message when saving fails', (tester) async {
      final repo = _FakeProfileRepository(updateError: Exception('boom'));
      await tester.pumpWidget(editApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan perubahan'));
      await tester.pumpAndSettle();

      expect(find.text('Gagal menyimpan. Coba lagi.'), findsOneWidget);
      expect(find.text('Simpan perubahan'), findsOneWidget);
    });

    testWidgets('picking no image leaves the form unchanged', (tester) async {
      await mockImagePicker(tester);
      final repo = _FakeProfileRepository();
      await tester.pumpWidget(editApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Ganti foto profil'));
      await tester.pumpAndSettle();

      expect(find.text('Simpan foto'), findsNothing);
    });

    testWidgets('picking an image uploads it', (tester) async {
      // Sync IO: async file operations never complete in the fake-async zone.
      // Use the platform separator so XFile.name resolves to 'avatar.png'.
      final dir = Directory.systemTemp.createTempSync('pf_avatar');
      final file = File('${dir.path}${Platform.pathSeparator}avatar.png');
      file.writeAsBytesSync(_transparentPng);
      addTearDown(() => dir.deleteSync(recursive: true));

      await mockImagePicker(tester, path: file.path);
      final repo = _FakeProfileRepository();
      await tester.pumpWidget(editApp(repo));
      await tester.pumpAndSettle();

      // The picker and readAsBytes are real async; let them complete in
      // runAsync, then drive the frame loop with bounded pumps (the pending
      // MemoryImage decode never settles pumpAndSettle in the fake zone).
      await tester.runAsync(() async {
        await tester.tap(find.byTooltip('Ganti foto profil'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      expect(find.text('Simpan foto'), findsOneWidget);

      await tester.tap(find.text('Simpan foto'));
      await tester.pump();

      expect(repo.uploadedFileName, 'avatar.png');
      expect(repo.uploadedBytes, _transparentPng);
      expect(find.text('Foto profil diperbarui.'), findsOneWidget);
    });
  });

  group('phone change (FR-AUTH-005)', () {
    testWidgets('rejects an empty or invalid new number', (tester) async {
      final repo = _FakeProfileRepository();
      await tester.pumpWidget(editApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ganti nomor HP'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kirim kode OTP'));
      await tester.pump();
      expect(find.text('Nomor HP wajib diisi.'), findsOneWidget);
      expect(repo.requestedPhone, isNull);

      await dismissSnackBar(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nomor HP baru'),
        '12345',
      );
      await tester.tap(find.text('Kirim kode OTP'));
      await tester.pump();
      expect(find.text('Format nomor HP tidak valid.'), findsOneWidget);
      expect(repo.requestedPhone, isNull);
    });

    testWidgets('sends the OTP and saves the verified number', (tester) async {
      final repo = _FakeProfileRepository();
      await tester.pumpWidget(editApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ganti nomor HP'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nomor HP baru'),
        '081299998888',
      );
      await tester.tap(find.text('Kirim kode OTP'));
      await tester.pump();
      expect(find.text('Kode OTP terkirim.'), findsOneWidget);
      expect(repo.requestedPhone, '081299998888');

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Kode OTP'),
        '654321',
      );

      // Expire the send snackbar so the success one is not queued behind it.
      await dismissSnackBar(tester);

      await tester.tap(find.text('Verifikasi nomor'));
      await tester.pump();

      expect(repo.verifiedPhone, '081299998888');
      expect(repo.verifiedToken, '654321');
      final phone = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Telepon'),
      );
      expect(phone.controller!.text, '081299998888');
      expect(find.text('Ganti nomor HP'), findsOneWidget);
      expect(find.text('Kirim ulang kode'), findsNothing);
      expect(find.text('Nomor HP diperbarui.'), findsOneWidget);
    });

    testWidgets('resends the OTP and can cancel the flow', (tester) async {
      final repo = _FakeProfileRepository();
      await tester.pumpWidget(editApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ganti nomor HP'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nomor HP baru'),
        '081299998888',
      );
      await tester.tap(find.text('Kirim kode OTP'));
      await tester.pump();

      await tester.tap(find.text('Kirim ulang kode'));
      await tester.pump();
      expect(repo.resentPhone, '081299998888');

      await tester.tap(find.text('Batal'));
      await tester.pump();
      expect(find.text('Ganti nomor HP'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Kode OTP'), findsNothing);
    });

    testWidgets('surfaces send and verify failures', (tester) async {
      final repo = _FakeProfileRepository(requestPhoneError: Exception('boom'));
      await tester.pumpWidget(editApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ganti nomor HP'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nomor HP baru'),
        '081299998888',
      );
      await tester.tap(find.text('Kirim kode OTP'));
      await tester.pump();
      expect(find.text('Gagal mengirim kode OTP. Coba lagi.'), findsOneWidget);

      repo.requestPhoneError = null;
      await dismissSnackBar(tester);

      await tester.tap(find.text('Kirim kode OTP'));
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Kode OTP'),
        '654321',
      );

      repo.verifyPhoneError = Exception('boom');

      // Expire the send snackbar so the failure one is not queued behind it.
      await dismissSnackBar(tester);

      await tester.tap(find.text('Verifikasi nomor'));
      await tester.pump();
      expect(repo.verifiedToken, '654321');
      expect(find.text('Verifikasi gagal. Coba lagi.'), findsOneWidget);
      // The flow stays open for another attempt.
      expect(find.text('Kirim ulang kode'), findsOneWidget);
    });
  });

  group('ProfileHeader', () {
    testWidgets('shows the avatar initial and email', (tester) async {
      await tester.pumpWidget(headerApp(_defaultProfile));

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.foregroundImage, isNull);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('budi@example.com'), findsOneWidget);
    });

    testWidgets('renders a network avatar when avatarUrl is set', (
      tester,
    ) async {
      // The test binding blocks real HTTP with a 400; serve the avatar
      // through a fake client instead. Reset it before the test ends: the
      // binding verifies painting debug flags before teardowns run.
      debugNetworkImageHttpClientProvider = _FakeHttpClient.new;

      const withAvatar = UserProfile(
        id: 'u1',
        name: 'Siti Aminah',
        phone: '081234567890',
        avatarUrl: 'https://example.com/avatars/u1.png',
      );
      await tester.pumpWidget(headerApp(withAvatar));
      await tester.pump();
      debugNetworkImageHttpClientProvider = null;

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.foregroundImage, isA<NetworkImage>());
      expect(find.text('S'), findsOneWidget);
      expect(find.text('Siti Aminah'), findsOneWidget);
    });
  });
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository({
    this.fetchError,
    this.updateError,
    this.requestPhoneError,
  });

  UserProfile profile = _defaultProfile;
  Object? fetchError;
  Object? updateError;
  Object? requestPhoneError;
  Object? verifyPhoneError;
  Future<UserProfile> Function()? fetchImpl;

  int fetchCount = 0;
  String? updatedName;
  String? updatedPhone;
  String? uploadedFileName;
  Uint8List? uploadedBytes;
  String? requestedPhone;
  String? resentPhone;
  String? verifiedPhone;
  String? verifiedToken;

  @override
  Future<UserProfile> fetchProfile() async {
    fetchCount++;
    final impl = fetchImpl;
    if (impl != null) return impl();
    final error = fetchError;
    if (error != null) throw error;
    return profile;
  }

  @override
  Future<UserProfile> updateProfile({
    required String name,
    String? phone,
    String? address,
  }) async {
    final error = updateError;
    if (error != null) throw error;
    updatedName = name;
    updatedPhone = phone;
    return UserProfile(
      id: profile.id,
      name: name,
      phone: phone ?? profile.phone,
      email: profile.email,
      avatarUrl: profile.avatarUrl,
      address: address,
    );
  }

  @override
  Future<String> updateAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    uploadedBytes = bytes;
    uploadedFileName = fileName;
    return 'https://example.com/avatars/$fileName';
  }

  @override
  Future<void> requestPhoneChange(String newPhone) async {
    requestedPhone = newPhone;
    final error = requestPhoneError;
    if (error != null) throw error;
  }

  @override
  Future<void> resendPhoneChangeOtp(String newPhone) async {
    resentPhone = newPhone;
  }

  @override
  Future<UserProfile> verifyPhoneChange({
    required String newPhone,
    required String token,
  }) async {
    verifiedPhone = newPhone;
    verifiedToken = token;
    final error = verifyPhoneError;
    if (error != null) throw error;
    return UserProfile(
      id: profile.id,
      name: profile.name,
      phone: newPhone,
      email: profile.email,
    );
  }
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    return Future.value(_FakeHttpClientRequest());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() {
    return Future.value(_FakeHttpClientResponse());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _transparentPng.length;

  @override
  HttpClientResponseCompressionState get compressionState {
    return HttpClientResponseCompressionState.notCompressed;
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(<Uint8List>[_transparentPng]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
