import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color main = Color(0xFF5E56FF);
  static const Color background = Color(0xFF121215);
  static const Color selected = Color(0xFF272932);
  static const Color secondary = Color(0xFF191A1F);
  static const Color outline = Color(0xFF292A33);
  static const Color text = Color(0xFFE2E2F9);
  static const Color resource = Colors.white;

  static Color get text80 => text.withValues(alpha: 0.8);
  static Color get text50 => text.withValues(alpha: 0.5);
  static Color get text30 => text.withValues(alpha: 0.3);
}
