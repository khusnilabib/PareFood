/// Supabase bootstrap for all four apps (PF-DOC-12 §3.1).
library;

import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Initialises the Supabase client from [config].
///
/// Idempotent: calling more than once returns the existing client. The anon
/// key is the only credential shipped to clients (SUP-R02); privileged access
/// happens server-side in Edge Functions.
class SupabaseBootstrap {
  const SupabaseBootstrap._();

  static SupabaseClient? _client;

  /// The initialised client, or throws [StateError] before [initialize] runs.
  static SupabaseClient get client {
    final existing = _client;
    if (existing == null) {
      throw StateError('SupabaseBootstrap.initialize must be called first.');
    }
    return existing;
  }

  /// Initialises Supabase once per process using [config].
  static Future<SupabaseClient> initialize(AppConfig config) async {
    if (_client != null) {
      return _client!;
    }
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabaseAnonKey,
    );
    return _client = Supabase.instance.client;
  }

  /// Test seam: resets the cached client between tests.
  @visibleForTesting
  static void reset() {
    _client = null;
  }
}
