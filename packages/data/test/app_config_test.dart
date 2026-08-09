import 'package:pare_data/pare_data.dart';
import 'package:test/test.dart';

void main() {
  group('PareEnvironmentX', () {
    test('exposes stable names', () {
      expect(PareEnvironment.dev.name, 'dev');
      expect(PareEnvironment.staging.name, 'staging');
      expect(PareEnvironment.production.name, 'production');
    });

    test('log level follows PF-DOC-22 §3.5', () {
      expect(PareEnvironment.dev.logLevel, 'debug');
      expect(PareEnvironment.staging.logLevel, 'info');
      expect(PareEnvironment.production.logLevel, 'info');
    });
  });

  group('AppConfig', () {
    const base = AppConfig(
      environment: PareEnvironment.dev,
      supabaseUrl: 'https://demo.supabase.co',
      supabaseAnonKey: 'anon',
      apiBaseUrl: 'https://api.parefood.test',
    );

    test('defaults to empty feature flags and no Sentry DSN', () {
      expect(base.featureFlags, isEmpty);
      expect(base.sentryDsn, isNull);
    });

    test('isFeatureEnabled honours flags and fallback', () {
      const config = AppConfig(
        environment: PareEnvironment.dev,
        supabaseUrl: 'https://demo.supabase.co',
        supabaseAnonKey: 'anon',
        apiBaseUrl: 'https://api.parefood.test',
        featureFlags: <String, bool>{'checkout': true},
      );

      expect(config.isFeatureEnabled('checkout'), isTrue);
      expect(config.isFeatureEnabled('dark_mode'), isFalse);
      expect(config.isFeatureEnabled('dark_mode', fallback: true), isTrue);
    });
  });
}
