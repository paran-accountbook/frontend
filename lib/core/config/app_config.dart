import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class AppConfig {
  static String get environment => dotenv.isInitialized
      ? dotenv.env['APP_ENV'] ?? 'development'
      : 'development';
  static String get apiBaseUrl => dotenv.isInitialized
      ? dotenv.env['API_BASE_URL'] ?? ''
      : 'https://api.sobilog.kr/';
  static String get termsDocumentUrl =>
      dotenv.isInitialized ? dotenv.env['TERMS_DOCUMENT_URL'] ?? '' : '';

  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
}
