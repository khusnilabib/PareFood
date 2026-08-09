/// Build-time configuration mapping (DEP-R06, PF-DOC-12 §3.1).
///
/// Values arrive via `--dart-define`; pure functions map them onto an
/// [AppConfig] so the mapping is unit-testable without the VM defines.
library;

import 'package:pare_data/pare_data.dart';

/// Shared dev Supabase project used when no defines are passed. Real builds
/// always pass explicit defines (DEP-R06); the fallback only keeps a bare
/// `flutter run` frictionless.
const _defaultSupabaseUrl = 'https://parefood-dev.supabase.co';
const _defaultAnonKey = 'dev-anon-key-placeholder';

/// Maps build-time define values onto the runtime [AppConfig].
///
/// Empty values fall back to the dev project; [apiBaseUrl] defaults to the
/// Supabase REST endpoint of the resolved project.
AppConfig appConfigFromDefines({
  required String pareEnv,
  required String supabaseUrl,
  required String supabaseAnonKey,
  required String apiBaseUrl,
  String sentryDsn = '',
}) {
  final url = supabaseUrl.trim().isEmpty
      ? _defaultSupabaseUrl
      : supabaseUrl.trim();
  return AppConfig(
    environment: parsePareEnvironment(pareEnv),
    supabaseUrl: url,
    supabaseAnonKey: supabaseAnonKey.trim().isEmpty
        ? _defaultAnonKey
        : supabaseAnonKey.trim(),
    apiBaseUrl: apiBaseUrl.trim().isEmpty ? '$url/rest/v1' : apiBaseUrl.trim(),
    sentryDsn: sentryDsn.trim().isEmpty ? null : sentryDsn.trim(),
  );
}

/// Resolves the compiled `--dart-define` values into the runtime config.
AppConfig resolveAppConfig() {
  return appConfigFromDefines(
    pareEnv: const String.fromEnvironment('PARE_ENV', defaultValue: 'dev'),
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
    sentryDsn: const String.fromEnvironment('SENTRY_DSN'),
  );
}
