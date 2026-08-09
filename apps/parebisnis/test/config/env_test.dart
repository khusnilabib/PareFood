import 'package:app_parebisnis/src/config/env.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pare_data/pare_data.dart';

void main() {
  group('appConfigFromDefines', () {
    test('maps explicit defines onto AppConfig', () {
      final config = appConfigFromDefines(
        pareEnv: 'staging',
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'anon-key',
        apiBaseUrl: 'https://example.supabase.co/rest/v1',
        sentryDsn: 'https://sentry.example/1',
      );

      expect(config.environment, PareEnvironment.staging);
      expect(config.supabaseUrl, 'https://example.supabase.co');
      expect(config.supabaseAnonKey, 'anon-key');
      expect(config.apiBaseUrl, 'https://example.supabase.co/rest/v1');
      expect(config.sentryDsn, 'https://sentry.example/1');
    });

    test('falls back to the dev project for empty defines', () {
      final config = appConfigFromDefines(
        pareEnv: '',
        supabaseUrl: '',
        supabaseAnonKey: '',
        apiBaseUrl: '',
      );

      expect(config.environment, PareEnvironment.dev);
      expect(config.supabaseUrl, isNotEmpty);
      expect(config.supabaseAnonKey, isNotEmpty);
      expect(config.apiBaseUrl, endsWith('/rest/v1'));
      expect(config.sentryDsn, isNull);
    });

    test('accepts the prod alias', () {
      final config = appConfigFromDefines(
        pareEnv: 'prod',
        supabaseUrl: 'https://p.supabase.co',
        supabaseAnonKey: 'k',
        apiBaseUrl: '',
      );

      expect(config.environment, PareEnvironment.production);
    });
  });

  test('resolveAppConfig defaults to the dev environment', () {
    // No --dart-define is compiled into tests, so every value falls back.
    final config = resolveAppConfig();
    expect(config.environment, PareEnvironment.dev);
    expect(config.apiBaseUrl, endsWith('/rest/v1'));
  });
}
