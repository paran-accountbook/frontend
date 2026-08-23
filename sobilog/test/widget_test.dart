import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/splash/presentation/splash_screen.dart';

void main() {
  testWidgets('renders the splash logo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const SplashScreen()),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
