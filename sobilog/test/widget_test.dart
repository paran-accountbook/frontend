import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/auth/presentation/login_screen.dart';
import 'package:sobilog/features/auth/presentation/terms_screen.dart';
import 'package:sobilog/features/auth/presentation/verification_screen.dart';
import 'package:sobilog/features/home/presentation/home_screen.dart';
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

  testWidgets('opens login from onboarding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const OnboardingScreen()),
    );

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('카카오로 로그인'), findsOneWidget);
    expect(find.text('이메일로 로그인'), findsOneWidget);
  });

  testWidgets('opens verification from email login', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const LoginScreen()),
    );

    await tester.tap(find.text('이메일로 로그인'));
    await tester.pumpAndSettle();

    expect(find.byType(VerificationScreen), findsOneWidget);
    expect(find.text('인증번호를 입력하세요'), findsOneWidget);
  });

  testWidgets('opens terms from verification', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const VerificationScreen()),
    );

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    expect(find.byType(TermsScreen), findsOneWidget);
    expect(find.text('약관동의'), findsOneWidget);
    expect(find.text('예시'), findsNWidgets(5));
  });

  testWidgets('opens home after terms agreement', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const TermsScreen()),
    );

    await tester.tap(find.text('동의합니다'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('최근 등록 내역'), findsOneWidget);
  });
}
