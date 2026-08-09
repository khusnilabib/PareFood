import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merchant_feature/merchant_feature.dart';

void main() {
  late _FakeRestaurantRepository repo;

  setUp(() {
    repo = _FakeRestaurantRepository();
    FilePicker.platform = _FakeFilePicker(
      FilePickerResult([
        PlatformFile(
          name: 'ktp.pdf',
          size: 3,
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
      ]),
    );
  });

  Widget build() {
    return ProviderScope(
      overrides: [restaurantRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: MerchantOnboardingPage()),
    );
  }

  // All four step panels stay in the tree (Stepper uses AnimatedCrossFade), so
  // only the current step's widgets are non-zero-size and hit-testable.
  Finder current(String text) => find.text(text).hitTestable();

  Future<void> pumpOnboarding(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(build());
  }

  // TextFormField tree order is stable: info step fields 0-2, location 3-5.
  Future<void> fillInfo(WidgetTester tester) async {
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Warung Nusantara',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Masakan rumahan');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'warung-nusantara',
    );
  }

  Future<void> fillLocation(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(3), '-6.2');
    await tester.enterText(find.byType(TextFormField).at(4), '106.8');
    await tester.enterText(find.byType(TextFormField).at(5), '5');
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(current('Lanjut'));
    await tester.pumpAndSettle();
  }

  Future<void> toDocumentsStep(WidgetTester tester) async {
    await pumpOnboarding(tester);
    await fillInfo(tester);
    await next(tester);
    await fillLocation(tester);
    await next(tester);
    await next(tester);
  }

  testWidgets('renders the first step with business fields', (tester) async {
    await pumpOnboarding(tester);
    expect(find.text('Daftar Restoran'), findsOneWidget);
    expect(find.text('Info Bisnis'), findsOneWidget);
    expect(find.text('Nama restoran'), findsOneWidget);
    expect(find.text('Deskripsi'), findsOneWidget);
    expect(find.text('Slug (cth: warung-nusantara)'), findsOneWidget);
    expect(current('Lanjut'), findsOneWidget);
    expect(current('Kirim'), findsNothing);
    expect(current('Kembali'), findsNothing);
  });

  testWidgets('validation blocks the submit when required fields are empty', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    await next(tester);
    await next(tester);
    await next(tester);

    await tester.tap(current('Kirim'));
    await tester.pumpAndSettle();

    expect(find.text('Field wajib diisi.'), findsNWidgets(2));
    expect(repo.created, isNull);
    expect(
      current('Unggah KTP dan/atau NIB untuk verifikasi.'),
      findsOneWidget,
    );
  });

  testWidgets('validation blocks the submit with an invalid location', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    await fillInfo(tester);
    await next(tester);
    await tester.enterText(find.byType(TextFormField).at(3), 'abc');
    await tester.enterText(find.byType(TextFormField).at(4), '106.8');
    await next(tester);
    await next(tester);

    await tester.tap(current('Kirim'));
    await tester.pumpAndSettle();

    expect(find.text('Masukkan latitude yang valid.'), findsOneWidget);
    expect(repo.created, isNull);
  });

  testWidgets('navigates between steps with Lanjut and Kembali', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    expect(current('Kembali'), findsNothing);

    await fillInfo(tester);
    await next(tester);
    expect(current('Kembali'), findsOneWidget);
    expect(current('Senin'), findsNothing);

    await tester.tap(current('Kembali'));
    await tester.pumpAndSettle();
    expect(current('Kembali'), findsNothing);

    await next(tester);
    await next(tester);
    expect(current('Jam Operasional'), findsOneWidget);
    expect(current('Senin'), findsOneWidget);
    expect(current('Atur jam'), findsNWidgets(7));

    await next(tester);
    expect(
      current('Unggah KTP dan/atau NIB untuk verifikasi.'),
      findsOneWidget,
    );
    expect(current('Kirim'), findsOneWidget);
    expect(current('Lanjut'), findsNothing);
  });

  testWidgets('submit without a document shows the upload reminder', (
    tester,
  ) async {
    await toDocumentsStep(tester);
    await tester.tap(current('Kirim'));
    await tester.pumpAndSettle();

    expect(
      find.text('Unggah minimal satu dokumen (KTP atau NIB).'),
      findsOneWidget,
    );
    expect(repo.created, isNull);
  });

  testWidgets('full submit uploads documents and opens the status page', (
    tester,
  ) async {
    await toDocumentsStep(tester);

    await tester.tap(current('Pilih').first);
    await tester.pumpAndSettle();

    await tester.tap(current('Kirim'));
    await tester.pumpAndSettle();

    expect(repo.created, isNotNull);
    expect(repo.created!.name, 'Warung Nusantara');
    expect(repo.created!.slug, 'warung-nusantara');
    expect(repo.created!.latitude, -6.2);
    expect(repo.created!.longitude, 106.8);
    expect(repo.created!.deliveryRadiusMeters, 5000);

    expect(repo.uploads, hasLength(1));
    expect(repo.uploads.single.restaurantId, 'r1');
    expect(repo.uploads.single.fileName, 'ktp.pdf');

    expect(repo.submits, hasLength(1));
    expect(repo.submits.single.docType, 'ktp');
    expect(repo.submits.single.storagePath, 'r1/ktp.pdf');

    expect(find.text('Status Restoran'), findsOneWidget);
    expect(find.text('Restoran Anda aktif!'), findsOneWidget);
  });

  testWidgets('submit failure shows the generic error snackbar', (
    tester,
  ) async {
    repo.failCreate = true;
    await toDocumentsStep(tester);
    await tester.tap(current('Pilih').first);
    await tester.pumpAndSettle();

    await tester.tap(current('Kirim'));
    await tester.pumpAndSettle();

    expect(find.text('Gagal mengirim. Coba lagi.'), findsOneWidget);
    expect(find.text('Status Restoran'), findsNothing);
  });

  testWidgets('opening hours can be set from the time picker', (tester) async {
    await pumpOnboarding(tester);
    await fillInfo(tester);
    await next(tester);
    await fillLocation(tester);
    await next(tester);

    if (TimeOfDay.now().hour == 23) {
      expect(current('Atur jam'), findsNWidgets(7));
      return;
    }

    await tester.tap(current('Senin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(current('Atur jam'), findsNWidgets(6));
    expect(repo.hoursCalls, 0);
  });
}

class _FakeFilePicker extends FilePicker {
  _FakeFilePicker(this._result);

  final FilePickerResult _result;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    void Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    return _result;
  }
}

class _FakeRestaurantRepository implements RestaurantRepository {
  bool failCreate = false;
  int hoursCalls = 0;

  ({
    String name,
    String description,
    String slug,
    double latitude,
    double longitude,
    int deliveryRadiusMeters,
  })?
  created;

  final uploads = <({String restaurantId, String fileName, Uint8List bytes})>[];
  final submits = <({String docType, String storagePath})>[];

  @override
  Future<List<Restaurant>> myRestaurants() async => const [];

  @override
  Future<Restaurant> createRestaurant({
    required String name,
    required String description,
    required String slug,
    required double latitude,
    required double longitude,
    required int deliveryRadiusMeters,
  }) async {
    if (failCreate) throw StateError('create failed');
    created = (
      name: name,
      description: description,
      slug: slug,
      latitude: latitude,
      longitude: longitude,
      deliveryRadiusMeters: deliveryRadiusMeters,
    );
    return Restaurant(
      id: 'r1',
      name: name,
      slug: slug,
      status: RestaurantStatus.active,
    );
  }

  @override
  Future<Restaurant> updateRestaurant({
    required String restaurantId,
    required String name,
    String? description,
    String? logoUrl,
    String? coverUrl,
  }) async {
    return Restaurant(id: restaurantId, name: name, slug: 's');
  }

  @override
  Future<void> setHours({
    required String restaurantId,
    required int dayOfWeek,
    required String openTime,
    required String closeTime,
    bool isClosed = false,
  }) async {
    hoursCalls++;
  }

  @override
  Future<void> uploadDocument({
    required String restaurantId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    uploads.add((restaurantId: restaurantId, fileName: fileName, bytes: bytes));
  }

  @override
  Future<void> submitDocument({
    required String docType,
    required String storagePath,
  }) async {
    submits.add((docType: docType, storagePath: storagePath));
  }
}
