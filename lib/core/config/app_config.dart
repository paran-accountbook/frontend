import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class AppConfig {
  static String get environment => dotenv.env['APP_ENV'] ?? 'development';
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';

  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
}
