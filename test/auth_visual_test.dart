import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/auth/presentation/email_login_screen.dart';
import 'package:sobilog/features/auth/presentation/email_signup_screen.dart';
import 'package:sobilog/features/auth/presentation/password_reset_complete_screen.dart';
import 'package:sobilog/features/auth/presentation/password_reset_password_screen.dart';
import 'package:sobilog/features/auth/presentation/signup_name_screen.dart';
import 'package:sobilog/features/auth/presentation/signup_password_screen.dart';
import 'package:sobilog/features/auth/presentation/terms_screen.dart';
import 'package:sobilog/features/auth/presentation/verification_screen.dart';
import 'package:sobilog/features/home/presentation/home_screen.dart';
import 'package:sobilog/features/analysis/presentation/analysis_overview_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_detail_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_screen.dart';
import 'package:sobilog/features/profile/presentation/account_settings_screen.dart';
import 'package:sobilog/features/profile/presentation/password_change_screen.dart';
import 'package:sobilog/features/profile/presentation/profile_edit_screen.dart';
import 'package:sobilog/features/profile/presentation/profile_screen.dart';
import 'package:sobilog/features/register/presentation/register_type_screen.dart';
import 'package:sobilog/features/register/presentation/register_method_screen.dart';
import 'package:sobilog/features/register/presentation/register_direct_screen.dart';
import 'package:sobilog/features/register/presentation/receipt_scan_loading_screen.dart';
import 'package:sobilog/features/register/presentation/receipt_result_screen.dart';
import 'package:sobilog/features/splash/presentation/splash_screen.dart';

void main() {
  setUpAll(() async {
    final pretendard = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Medium.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'));
    final amarante = FontLoader('Amarante')
      ..addFont(rootBundle.load('assets/fonts/Amarante-Regular.ttf'));
    final bujangnim = FontLoader('BujangnimNunchi')
      ..addFont(rootBundle.load('assets/fonts/BujangnimNunchi-Regular.ttf'));
    await Future.wait([pretendard.load(), amarante.load(), bujangnim.load()]);
  });

  Future<void> configureViewport(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.reset);
  }

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark, home: screen));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }

  testWidgets('splash matches its visual baseline', (tester) async {
    await configureViewport(tester);
    await pumpScreen(tester, const SplashScreen(autoAdvance: false));

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/splash.png'),
    );
  });

  testWidgets('email signup matches its visual baseline', (tester) async {
    await configureViewport(tester);
    await pumpScreen(tester, const EmailSignupScreen());

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/email_signup.png'),
    );
  });

  testWidgets('email login matches its visual baseline', (tester) async {
    await configureViewport(tester);
    await pumpScreen(tester, const EmailLoginScreen());

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/email_login.png'),
    );
  });

  testWidgets('verification matches its visual baseline', (tester) async {
    await configureViewport(tester);
    await pumpScreen(tester, const VerificationScreen());

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/verification.png'),
    );
  });

  testWidgets('signup password matches its visual baseline', (tester) async {
    await configureViewport(tester);
    await pumpScreen(
      tester,
      const SignupPasswordScreen(email: 'user@test.com'),
    );

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/signup_password.png'),
    );
  });

  testWidgets('signup name matches its visual baseline', (tester) async {
    await configureViewport(tester);
    await pumpScreen(
      tester,
      const SignupNameScreen(email: 'user@test.com', password: 'Password1!'),
    );

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/signup_name.png'),
    );
  });

  testWidgets('terms matches its visual baseline', (tester) async {
    await configureViewport(tester);
    await pumpScreen(tester, const TermsScreen());

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/terms.png'),
    );
  });

  testWidgets('reset password matches its visual baseline', (tester) async {
    await configureViewport(tester);
    await pumpScreen(
      tester,
      const PasswordResetPasswordScreen(email: 'user@test.com'),
    );

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/password_reset.png'),
    );
  });

  testWidgets('password reset complete matches its visual baseline', (
    tester,
  ) async {
    await configureViewport(tester);
    await pumpScreen(tester, const PasswordResetCompleteScreen());

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/password_reset_complete.png'),
    );
  });

  testWidgets('home matches its visual baseline', (tester) async {
    await configureViewport(tester);
    await pumpScreen(tester, const HomeScreen());

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/home.png'),
    );
  });

  testWidgets('ledger matches its visual baseline', (tester) async {
    await configureViewport(tester);
    await pumpScreen(tester, const LedgerScreen());

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/ledger.png'),
    );
  });

  testWidgets('register type matches its visual baseline', (tester) async {
    await configureViewport(tester);
    await pumpScreen(tester, const RegisterTypeScreen());

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/register_type.png'),
    );
  });

  testWidgets('register method matches its visual baseline', (tester) async {
    await configureViewport(tester);
    await pumpScreen(tester, const RegisterMethodScreen());
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/register_method.png'),
    );
  });

  testWidgets('receipt loading matches its visual baseline', (tester) async {
    await configureViewport(tester);
    await pumpScreen(
      tester,
      const ReceiptScanLoadingScreen(imagePath: 'receipt.jpg'),
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/receipt_loading.png'),
    );
  });

  testWidgets('receipt result matches its visual baseline', (tester) async {
    await configureViewport(tester);
    await pumpScreen(
      tester,
      const ReceiptResultScreen(imagePath: 'receipt.jpg'),
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/receipt_result.png'),
    );
  });

  testWidgets('direct register matches its visual baseline', (tester) async {
    await configureViewport(tester);
    await pumpScreen(tester, const RegisterDirectScreen());
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/register_direct.png'),
    );
  });

  testWidgets('ledger detail matches its visual baseline', (tester) async {
    await configureViewport(tester);
    await pumpScreen(tester, const LedgerDetailScreen());
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/ledger_detail.png'),
    );
  });

  testWidgets('analysis matches its visual baseline', (tester) async {
    await configureViewport(tester);
    await pumpScreen(tester, const AnalysisOverviewScreen());
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/analysis.png'),
    );
  });

  testWidgets('profile matches its visual baseline', (tester) async {
    await configureViewport(tester);
    await pumpScreen(tester, const ProfileScreen());
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/profile.png'),
    );
  });

  testWidgets('profile edit matches its visual baseline', (tester) async {
    await configureViewport(tester);
    await pumpScreen(tester, const ProfileEditScreen());
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/profile_edit.png'),
    );
  });

  testWidgets('account settings matches its visual baseline', (tester) async {
    await configureViewport(tester);
    await pumpScreen(tester, const AccountSettingsScreen());
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/account_settings.png'),
    );
  });

  testWidgets('password change matches its visual baseline', (tester) async {
    await configureViewport(tester);
    await pumpScreen(tester, const PasswordChangeScreen());
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/password_change.png'),
    );
  });
}
