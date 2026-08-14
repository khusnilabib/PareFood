/// Tests for the Supabase bootstrap (PF-DOC-12 §3.1).
///
/// `initialize` is exercised with mocked SharedPreferences so no plugin
/// channels are needed; the network is never touched.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pare_data/pare_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(SupabaseBootstrap.reset);

  test('client throws StateError before initialize', () {
    expect(() => SupabaseBootstrap.client, throwsStateError);
  });

  // A plain `test` (not `testWidgets`) so the supabase_flutter lifecycle
  // timers do not trip the binding's pending-timer invariant.
  test('initialize builds and caches the shared client', () async {
    SharedPreferences.setMockInitialValues({});

    final client = await SupabaseBootstrap.initialize(
      const AppConfig(
        environment: PareEnvironment.dev,
        supabaseUrl: 'https://fake.supabase.co',
        supabaseAnonKey: 'fake-anon-key',
        apiBaseUrl: 'https://api.parefood.test',
      ),
    );
    expect(identical(SupabaseBootstrap.client, client), isTrue);

    // Idempotent: a second call returns the cached client.
    final again = await SupabaseBootstrap.initialize(
      const AppConfig(
        environment: PareEnvironment.dev,
        supabaseUrl: 'https://fake.supabase.co',
        supabaseAnonKey: 'fake-anon-key',
        apiBaseUrl: 'https://api.parefood.test',
      ),
    );
    expect(identical(again, client), isTrue);

    // Reset returns the guard to its uninitialised state.
    SupabaseBootstrap.reset();
    expect(() => SupabaseBootstrap.client, throwsStateError);
  });
}
