import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Environment { development, staging, production }

class EnvironmentConfig {
  static Environment get current {
    final raw = (dotenv.env['APP_ENVIRONMENT'] ?? 'sandbox').toLowerCase();
    switch (raw) {
      case 'production':
      case 'prod':
        return Environment.production;
      case 'staging':
        return Environment.staging;
      default:
        return Environment.development;
    }
  }

  static String _choose({String? dev, String? staging, String? prod, String? fallback}) {
    switch (current) {
      case Environment.production:
        return prod ?? fallback ?? '';
      case Environment.staging:
        return staging ?? fallback ?? '';
      case Environment.development:
      default:
        return dev ?? fallback ?? '';
    }
  }

  static String get apiBaseUrl => _choose(
        dev: dotenv.env['API_BASE_URL_DEV'],
        staging: dotenv.env['API_BASE_URL_STAGING'],
        prod: dotenv.env['API_BASE_URL_PROD'],
        fallback: dotenv.env['API_BASE_URL'],
      );

  static String get websocketBaseUrl => _choose(
        dev: dotenv.env['WEBSOCKET_BASE_URL_DEV'],
        staging: dotenv.env['WEBSOCKET_BASE_URL_STAGING'],
        prod: dotenv.env['WEBSOCKET_BASE_URL_PROD'],
        fallback: dotenv.env['WEBSOCKET_BASE_URL'],
      );

  static String get webAppBaseUrl => _choose(
        dev: dotenv.env['WEB_APP_BASE_URL_DEV'],
        staging: dotenv.env['WEB_APP_BASE_URL_STAGING'],
        prod: dotenv.env['WEB_APP_BASE_URL_PROD'],
        fallback: dotenv.env['WEB_APP_BASE_URL'],
      );
}
