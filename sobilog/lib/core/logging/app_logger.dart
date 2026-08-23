import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

abstract final class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static bool get _enabled =>
      dotenv.env['ENABLE_DEBUG_LOG']?.toLowerCase() == 'true';

  static void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (_enabled) _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (_enabled) _logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
