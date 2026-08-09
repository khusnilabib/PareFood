/// Runtime environment + app configuration (PF-DOC-22 §3.5).
///
/// Config is injected at the composition root via `--dart-define`/runtime
/// config — never committed, never hard-coded in widgets (DEP-R06).
library;

/// Deployment environment.
enum PareEnvironment { dev, staging, production }

extension PareEnvironmentX on PareEnvironment {
  String get name => switch (this) {
    PareEnvironment.dev => 'dev',
    PareEnvironment.staging => 'staging',
    PareEnvironment.production => 'production',
  };

  /// Log level verbosity per environment (PF-DOC-22 §3.5): debug in dev,
  /// info in staging/production.
  String get logLevel => this == PareEnvironment.dev ? 'debug' : 'info';
}

/// Immutable runtime configuration for one app build.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.apiBaseUrl,
    this.sentryDsn,
    this.featureFlags = const <String, bool>{},
  });

  /// Current deployment environment.
  final PareEnvironment environment;

  /// Supabase project URL (anon key only, SUP-R02).
  final String supabaseUrl;

  /// Supabase anon/public key.
  final String supabaseAnonKey;

  /// Base URL for Dio calls (Supabase REST / Edge Functions gateway).
  final String apiBaseUrl;

  /// Optional Sentry DSN for error reporting (PF-DOC-09 §3.1).
  final String? sentryDsn;

  /// Feature flags for guarded rollout (PF-DOC-22 §3.5).
  final Map<String, bool> featureFlags;

  /// Reads a [flag] with a safe default for unregistered flags.
  bool isFeatureEnabled(String flag, {bool fallback = false}) {
    return featureFlags[flag] ?? fallback;
  }
}
