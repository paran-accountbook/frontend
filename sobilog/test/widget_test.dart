import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/auth/presentation/login_screen.dart';
import 'package:sobilog/features/auth/presentation/terms_screen.dart';
import 'package:sobilog/features/auth/presentation/verification_screen.dart';
import 'package:sobilog/features/dutch/presentation/dutch_people_screen.dart';
import 'package:sobilog/features/dutch/presentation/dutch_assignment_screen.dart';
import 'package:sobilog/features/home/presentation/home_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_detail_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_edit_screen.dart';
import 'package:sobilog/features/register/presentation/register_type_screen.dart';
import 'package:sobilog/features/register/presentation/register_method_screen.dart';
import 'package:sobilog/features/register/presentation/register_direct_screen.dart';
import 'package:sobilog/features/register/presentation/register_income_screen.dart';
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

  testWidgets('renders ledger entries and filters', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const LedgerScreen()),
    );

    expect(find.byType(LedgerScreen), findsOneWidget);
    expect(find.text('가계부'), findsOneWidget);
    expect(find.text('아주대학교 카페'), findsNWidgets(4));
  });

  testWidgets('renders ledger detail', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const LedgerDetailScreen()),
    );

    expect(find.text('상세 내역'), findsOneWidget);
    expect(find.text('더치페이 하기'), findsOneWidget);
    expect(find.text('메모 남기기'), findsOneWidget);
  });

  testWidgets('renders ledger edit receipt', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const LedgerEditScreen()),
    );

    expect(find.text('내역 수정'), findsOneWidget);
    expect(find.text('저장'), findsOneWidget);
    expect(find.text('커피'), findsNWidgets(5));
  });

  testWidgets('renders register type choices', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const RegisterTypeScreen()),
    );

    expect(find.text('소비 등록'), findsOneWidget);
    expect(find.text('수입 등록'), findsOneWidget);
  });

  testWidgets('renders register method choices', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const RegisterMethodScreen()),
    );

    expect(find.text('카메라로 촬영'), findsOneWidget);
    expect(find.text('갤러리에서 선택'), findsOneWidget);
    expect(find.text('직접 등록'), findsOneWidget);
  });

  testWidgets('renders direct expense receipt', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const RegisterDirectScreen()),
    );

    expect(find.text('소비로그'), findsOneWidget);
    expect(find.text('저장'), findsOneWidget);
    expect(find.text('커피'), findsNWidgets(5));
  });

  testWidgets('renders income receipt', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const RegisterIncomeScreen()),
    );

    expect(find.text('용돈'), findsOneWidget);
    expect(find.text('수입일'), findsOneWidget);
    expect(find.text('저장'), findsOneWidget);
  });

  testWidgets('renders dutch people', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const DutchPeopleScreen()),
    );
    expect(find.text('인원등록'), findsOneWidget);
    expect(find.text('정산하기'), findsOneWidget);
  });

  testWidgets('renders dutch item assignment', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const DutchAssignmentScreen()),
    );
    expect(find.text('항목별 인원 배정'), findsOneWidget);
    expect(find.text('이전'), findsOneWidget);
    expect(find.text('다음'), findsOneWidget);
  });
}
