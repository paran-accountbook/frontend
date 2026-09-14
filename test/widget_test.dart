import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/auth/presentation/email_login_screen.dart';
import 'package:sobilog/features/auth/presentation/login_screen.dart';
import 'package:sobilog/features/auth/presentation/terms_screen.dart';
import 'package:sobilog/features/auth/presentation/verification_screen.dart';
import 'package:sobilog/features/analysis/presentation/analysis_overview_screen.dart';
import 'package:sobilog/features/analysis/presentation/analysis_detail_screen.dart';
import 'package:sobilog/features/analysis/presentation/analysis_goal_screen.dart';
import 'package:sobilog/features/finance/data/finance_service.dart';
import 'package:sobilog/features/dutch/presentation/dutch_people_screen.dart';
import 'package:sobilog/features/dutch/presentation/dutch_assignment_screen.dart';
import 'package:sobilog/features/dutch/presentation/dutch_result_screen.dart';
import 'package:sobilog/features/dutch/presentation/dutch_request_screen.dart';
import 'package:sobilog/features/home/presentation/home_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_detail_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_edit_screen.dart';
import 'package:sobilog/features/register/presentation/register_type_screen.dart';
import 'package:sobilog/features/register/presentation/register_method_screen.dart';
import 'package:sobilog/features/register/presentation/register_direct_screen.dart';
import 'package:sobilog/features/register/presentation/register_income_screen.dart';
import 'package:sobilog/features/register/presentation/receipt_entry_form.dart';
import 'package:sobilog/features/profile/presentation/profile_screen.dart';
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

  testWidgets('advances from splash to login', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const SplashScreen(restoreSession: false),
      ),
    );

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('이메일로 로그인'), findsOneWidget);
  });

  testWidgets('opens login from onboarding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const OnboardingScreen()),
    );

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('카카오로 시작하기'), findsOneWidget);
    expect(find.text('이메일로 로그인'), findsOneWidget);
  });

  testWidgets('opens the email login form', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const LoginScreen()),
    );

    await tester.tap(find.text('이메일로 로그인'));
    await tester.pumpAndSettle();

    expect(find.byType(EmailLoginScreen), findsOneWidget);
    expect(find.text('비밀번호를 잊으셨나요?'), findsOneWidget);
  });

  testWidgets('submits a six-digit verification code', (tester) async {
    var verified = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: VerificationScreen(onVerified: () => verified = true),
      ),
    );

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();

    expect(verified, isTrue);
  });

  testWidgets('opens home after terms agreement', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const TermsScreen()),
    );

    await tester.tap(find.text('전체 동의하기'));
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

    expect(find.text('가맹점 명'), findsOneWidget);
    expect(find.text('더치페이 하기'), findsOneWidget);
    expect(find.text('메모'), findsOneWidget);
  });

  testWidgets('renders ledger edit receipt', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const LedgerEditScreen()),
    );

    expect(find.byKey(const Key('ledger-edit-receipt-scroll')), findsOneWidget);
    expect(find.text('저장'), findsOneWidget);
    expect(find.text('아메리카노'), findsNWidgets(2));
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

  testWidgets('requests native camera and gallery sources', (tester) async {
    final sources = <ImageSource>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: RegisterMethodScreen(
          onPickImage: (source) async => sources.add(source),
        ),
      ),
    );

    await tester.tap(find.text('카메라로 촬영'));
    await tester.pump();
    await tester.tap(find.text('갤러리에서 선택'));
    await tester.pump();

    expect(sources, [ImageSource.camera, ImageSource.gallery]);
  });

  testWidgets('renders direct expense receipt', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const RegisterDirectScreen()),
    );

    expect(find.text('직접 등록'), findsOneWidget);
    expect(find.text('저장'), findsOneWidget);
    expect(find.text('아메리카노'), findsNWidgets(3));
  });

  testWidgets('serializes expense payment time as an absolute UTC instant', (
    tester,
  ) async {
    final key = GlobalKey<ReceiptEntryFormState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ReceiptEntryForm(
            key: key,
            editable: true,
            initialData: const {
              'store_name': 'E2E TEST',
              'paid_at': '2026-09-14T01:38:00+09:00',
              'category': '교육',
              'payment_method': '카드',
              'items': [
                {'item_name': 'E2E BOOK', 'quantity': 1, 'unit_price': 12345},
              ],
            },
          ),
        ),
      ),
    );

    final payload = key.currentState!.buildPayload(source: 'manual')!;
    expect(payload['paid_at'], '2026-09-13T16:38:00.000Z');
  });

  testWidgets('renders income receipt', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const RegisterIncomeScreen()),
    );

    expect(find.text('수입 등록'), findsOneWidget);
    expect(find.text('금액'), findsOneWidget);
    expect(find.text('저장'), findsOneWidget);
  });

  testWidgets('renders dutch people', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const DutchPeopleScreen()),
    );
    expect(find.text('인원 등록'), findsOneWidget);
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

  testWidgets('renders dutch settlement result', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const DutchResultScreen()),
    );
    expect(find.text('정산 결과 확인'), findsOneWidget);
    expect(find.text('영수증 총액'), findsOneWidget);
    expect(find.text('김치찌개'), findsOneWidget);
    expect(find.text('다음'), findsOneWidget);
  });

  testWidgets('renders dutch settlement request', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const DutchRequestScreen()),
    );
    expect(find.text('정산 요청'), findsOneWidget);
    expect(find.text('내 계좌'), findsOneWidget);
    expect(find.text('요청할 인원 2명'), findsOneWidget);
    expect(find.text('완료'), findsOneWidget);
  });

  testWidgets('renders analysis overview', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const AnalysisOverviewScreen()),
    );
    expect(find.text('소비분석'), findsOneWidget);
    expect(find.text('총 지출'), findsOneWidget);
    expect(find.text('카테고리별 비중'), findsOneWidget);
    expect(find.text('식비'), findsOneWidget);
  });

  testWidgets('keeps spending goal visible when analysis omits goal', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: AnalysisOverviewScreen(
          financeService: _AnalysisWithoutGoalService(),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('지출 목표'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('opens analysis overview from home summary', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const HomeScreen()),
    );

    await tester.tap(find.text('소비요약'));
    await tester.pumpAndSettle();

    expect(find.byType(AnalysisOverviewScreen), findsOneWidget);
    expect(find.text('카테고리별 비중'), findsOneWidget);
  });

  testWidgets('renders analysis detail', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const AnalysisDetailScreen()),
    );

    expect(find.text('가장 많이 지출한 카테고리'), findsOneWidget);
    expect(find.text('가장 많이 산 품목 TOP 5'), findsOneWidget);
    expect(find.text('소비 패턴 분석'), findsOneWidget);
    expect(find.text('재구매 충동구매 분석'), findsOneWidget);
  });

  testWidgets('opens spending goal dialog from analysis detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const AnalysisDetailScreen()),
    );

    await tester.ensureVisible(find.text('4월 지출 목표'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4월 지출 목표'));
    await tester.pumpAndSettle();

    expect(find.byType(AnalysisGoalScreen), findsOneWidget);
    expect(find.text('지출 목표 설정'), findsOneWidget);
    expect(find.text('수입의 50%'), findsOneWidget);
    expect(find.text('직접 입력'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('analysis-goal-close')));
    await tester.pumpAndSettle();

    expect(find.byType(AnalysisGoalScreen), findsNothing);
    expect(find.byType(AnalysisDetailScreen), findsOneWidget);
  });

  testWidgets('renders profile menu', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const ProfileScreen()),
    );

    expect(find.text('마이페이지'), findsOneWidget);
    expect(find.text('소비로그 님'), findsOneWidget);
    expect(find.text('출석 현황'), findsOneWidget);
    expect(find.text('계정 설정'), findsOneWidget);
  });
}

class _AnalysisWithoutGoalService implements FinanceService {
  @override
  Future<Map<String, dynamic>> analysis({
    required int year,
    required int month,
  }) async => {
    'total_expense_amount': 150000,
    'daily_average_expense': 40000,
    'total_income_amount': 150000,
    'balance': 150000,
    'change_amount': 2500,
    'change_rate': 12,
    'category_breakdown': <Map<String, dynamic>>[],
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
