import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/onboarding/presentation/onboarding_screen.dart';
import 'package:sobilog/features/splash/presentation/splash_screen.dart';

void main() {
  testWidgets('renders the splash logo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const SplashScreen(autoAdvance: false),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
  });

  testWidgets('advances from splash to onboarding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const SplashScreen()),
    );

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('소비 습관'), findsOneWidget);
  });
}
