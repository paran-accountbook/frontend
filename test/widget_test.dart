import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sobilog/core/network/api_exception.dart';
import 'package:sobilog/core/theme/app_colors.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/auth/data/auth_service.dart';
import 'package:sobilog/features/auth/presentation/email_login_screen.dart';
import 'package:sobilog/features/auth/presentation/login_screen.dart';
import 'package:sobilog/features/auth/presentation/signup_name_screen.dart';
import 'package:sobilog/features/auth/presentation/signup_password_screen.dart';
import 'package:sobilog/features/auth/presentation/terms_detail_screen.dart';
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
import 'package:sobilog/features/register/presentation/receipt_result_screen.dart';
import 'package:sobilog/features/register/presentation/receipt_scan_loading_screen.dart';
import 'package:sobilog/features/profile/presentation/profile_screen.dart';
import 'package:sobilog/features/onboarding/presentation/onboarding_screen.dart';
import 'package:sobilog/features/splash/presentation/splash_screen.dart';
import 'package:sobilog/shared/widgets/app_bottom_navigation.dart';
import 'package:sobilog/shared/widgets/app_skeleton.dart';
import 'package:sobilog/shared/widgets/editable_receipt_form.dart';

void main() {
  testWidgets('signup completion content matches the Figma button layout', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final authService = _RecordingAuthService();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: SignupNameScreen(
          email: 'user@test.com',
          password: 'Password1!',
          authService: authService,
        ),
      ),
    );

    final iconRect = tester.getRect(
      find.byKey(const ValueKey('auth-bottom-action-leading-icon')),
    );
    final labelRect = tester.getRect(
      find.byKey(const ValueKey('auth-bottom-action-label')),
    );
    expect(iconRect.size, const Size(18, 12));
    expect(labelRect.left - iconRect.right, 10);

    await tester.enterText(find.byType(TextField), '테스트');
    await tester.tap(find.text('가입 완료'));
    await tester.pump();
    await tester.pump();

    expect(authService.signupEmail, 'user@test.com');
    expect(authService.signupNickname, '테스트');
  });

  testWidgets('signup follows verification, terms, password, and name order', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final authService = _RecordingAuthService();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: VerificationScreen(
          email: 'user@test.com',
          authService: authService,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    expect(authService.verifiedCode, '123456');
    expect(find.byType(TermsScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('terms-view-0')));
    await tester.pumpAndSettle();
    expect(find.byType(TermsDetailScreen), findsOneWidget);
    expect(find.text('서비스 이용 약관'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('전체 동의하기'));
    await tester.tap(find.text('동의합니다'));
    await tester.pumpAndSettle();
    expect(find.byType(SignupPasswordScreen), findsOneWidget);

    final passwordFields = find.byType(TextField);
    await tester.enterText(passwordFields.at(0), 'Password1!');
    await tester.enterText(passwordFields.at(1), 'Password1!');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.byType(SignupNameScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField), '소비로그');
    await tester.tap(find.text('가입 완료'));
    await tester.pump();
    await tester.pump();

    expect(authService.signupEmail, 'user@test.com');
    expect(authService.signupNickname, '소비로그');
    expect(authService.marketingAgreed, isTrue);
  });

  testWidgets('bottom navigation matches the Figma item geometry', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppBottomNavigation(selectedIndex: 0)),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('bottom-navigation-item-2'))),
      const Size(48, 36),
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('bottom-navigation-register-icon')),
      ),
      const Size(36, 36),
    );
    final home = tester.getCenter(
      find.byKey(const ValueKey('bottom-navigation-item-0')),
    );
    final ledger = tester.getCenter(
      find.byKey(const ValueKey('bottom-navigation-item-1')),
    );
    expect(ledger.dx - home.dx, 58);
  });

  testWidgets('bottom navigation swaps to the selected Figma variant', (
    tester,
  ) async {
    var selectedIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: AppBottomNavigation(
              selectedIndex: selectedIndex,
              onSelected: (index) => setState(() => selectedIndex = index),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('bottom-navigation-icon-0-on')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('bottom-navigation-icon-4-off')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('bottom-navigation-item-4')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('bottom-navigation-icon-0-off')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('bottom-navigation-icon-4-on')),
      findsOneWidget,
    );
  });

  testWidgets('analysis locked icons match the Figma geometry', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const AnalysisOverviewScreen()),
    );

    await tester.tap(find.text('패턴'));
    await tester.pump();

    expect(
      tester.getSize(find.byKey(const ValueKey('analysis-locked-icon-slot-0'))),
      const Size.square(26),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('analysis-locked-icon-0'))),
      const Size.square(18),
    );
  });

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

  testWidgets('ledger month arrows point and move in opposite directions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LedgerScreen(currentDate: DateTime(2026, 9, 23)),
      ),
    );

    final previous = find.byKey(const Key('ledger-period-previous'));
    final next = find.byKey(const Key('ledger-period-next'));
    final previousTransform = tester.widget<Transform>(
      find.descendant(of: previous, matching: find.byType(Transform)),
    );
    expect(previousTransform.transform.storage[0], -1);

    String title() => tester
        .widget<Text>(find.byKey(const Key('ledger-period-title')))
        .textSpan!
        .toPlainText()
        .replaceAll('\uFFFC', '');

    expect(title(), contains('8'));
    await tester.tap(previous);
    await tester.pump();
    expect(title(), contains('7'));
    await tester.tap(next);
    await tester.pump();
    expect(title(), contains('8'));
  });

  testWidgets('월·주·일의 과거 기간에서 다음 화살표가 활성화된다', (tester) async {
    final currentDate = DateTime(2026, 9, 23);

    for (var period = 0; period < 3; period++) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: LedgerScreen(
            initialAnchor: currentDate,
            initialPeriod: period,
            currentDate: currentDate,
          ),
        ),
      );

      Finder next() => find.byKey(const Key('ledger-period-next'));
      GestureDetector nextButton() => tester.widget<GestureDetector>(next());

      expect(nextButton().onTap, isNull, reason: '현재 기간은 다음 이동 불가');

      await tester.tap(find.byKey(const Key('ledger-period-previous')));
      await tester.pump();
      expect(nextButton().onTap, isNotNull, reason: '과거 기간은 다음 이동 가능');

      await tester.tap(next());
      await tester.pump();
      expect(nextButton().onTap, isNull, reason: '현재 기간으로 복귀하면 다시 비활성화');

      await tester.pumpWidget(const SizedBox.shrink());
    }
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

  testWidgets('all bottom navigation items work on registration screens', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: RegisterMethodScreen(onNavigationSelected: selected.add),
      ),
    );

    for (var index = 0; index < 5; index++) {
      await tester.tap(find.byKey(ValueKey('bottom-navigation-item-$index')));
      await tester.pump();
    }
    expect(selected, [0, 1, 2, 3, 4]);

    selected.clear();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: RegisterTypeScreen(onNavigationSelected: selected.add),
      ),
    );
    for (var index = 0; index < 5; index++) {
      await tester.tap(find.byKey(ValueKey('bottom-navigation-item-$index')));
      await tester.pump();
    }
    expect(selected, [0, 1, 2, 3, 4]);
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

  testWidgets(
    'receipt registration spinner rotates clockwise at constant speed',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(402, 874);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const ReceiptScanLoadingScreen(
            imagePath: 'receipt.jpg',
            autoRecognize: false,
          ),
        ),
      );

      final spinnerFinder = find.byKey(
        const ValueKey('receipt-registration-spinner'),
      );
      final progress = tester.widget<CircularProgressIndicator>(
        find.descendant(
          of: spinnerFinder,
          matching: find.byType(CircularProgressIndicator),
        ),
      );
      final before = tester
          .widget<RotationTransition>(spinnerFinder)
          .turns
          .value;

      expect(progress.value, 0.75);
      await tester.pump(const Duration(milliseconds: 300));

      final after = tester
          .widget<RotationTransition>(spinnerFinder)
          .turns
          .value;
      expect((after - before + 1) % 1, closeTo(0.25, 0.01));
    },
  );

  testWidgets('receipt recognition failure offers retry and direct entry', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final service = _FailingReceiptService();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ReceiptScanLoadingScreen(
          imagePath: 'unreadable-receipt.jpg',
          financeService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('receipt-recognition-failure-dialog')),
      findsOneWidget,
    );
    expect(find.text('영수증을 인식하지 못했어요'), findsOneWidget);
    expect(find.text('다시 시도하거나'), findsOneWidget);
    expect(find.text('직접 등록할 수 있어요.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
    expect(find.text('직접 등록'), findsOneWidget);
    expect(service.recognitionCalls, 1);
    expect(
      tester.getSize(
        find.byKey(const ValueKey('receipt-recognition-failure-dialog-panel')),
      ),
      const Size(326, 270),
    );

    final panelRect = tester.getRect(
      find.byKey(const ValueKey('receipt-recognition-failure-dialog-panel')),
    );
    final titleRect = tester.getRect(find.text('영수증을 인식하지 못했어요'));
    final retryRect = tester.getRect(find.text('다시 시도'));
    final directRect = tester.getRect(find.text('직접 등록'));
    expect(titleRect.center.dx, closeTo(panelRect.center.dx, .5));
    expect(retryRect.center.dy, closeTo(directRect.center.dy, .5));
    expect(retryRect.center.dx, lessThan(panelRect.center.dx));
    expect(directRect.center.dx, greaterThan(panelRect.center.dx));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/receipt_failure_dialog.png'),
    );

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(service.recognitionCalls, 2);
    expect(
      find.byKey(const ValueKey('receipt-recognition-failure-dialog')),
      findsOneWidget,
    );

    await tester.tap(find.text('직접 등록'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterDirectScreen), findsOneWidget);
  });

  testWidgets('data-driven screens render skeletons while loading', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final service = _PendingFinanceService();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: HomeScreen(financeService: service),
      ),
    );
    await tester.pump();
    expect(find.byType(AppSkeletonList), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LedgerScreen(financeService: service),
      ),
    );
    await tester.pump();
    expect(find.byType(AppSkeletonList), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: AnalysisOverviewScreen(financeService: service),
      ),
    );
    await tester.pump();
    expect(find.byType(AppSkeleton), findsWidgets);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ProfileScreen(financeService: service),
      ),
    );
    await tester.pump();
    expect(find.byType(AppSkeleton), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LedgerDetailScreen(expenseId: '1', financeService: service),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('ledger-detail-loading')), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LedgerEditScreen(expenseId: '1', financeService: service),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('ledger-edit-loading')), findsOneWidget);
  });

  testWidgets('skeleton shimmer preserves the Figma 10 to 20 percent alpha', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppSkeleton(child: AppSkeletonBox(width: 100, height: 20)),
        ),
      ),
    );

    final mask = tester.widget<ShaderMask>(find.byType(ShaderMask));
    expect(mask.blendMode, BlendMode.srcIn);
    expect(AppColors.text10.a, closeTo(.1, .01));
    expect(AppColors.text20.a, closeTo(.2, .01));
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

  testWidgets('edits a receipt item on double tap and deletes its memo', (
    tester,
  ) async {
    final key = GlobalKey<ReceiptEntryFormState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReceiptEntryForm(
              key: key,
              editable: true,
              showMemo: true,
              initialData: const {
                'store_name': '테스트 카페',
                'category': '카페',
                'payment_method': '카드',
                'items': [
                  {'item_name': '아메리카노', 'quantity': 1, 'unit_price': 4500},
                ],
                'memo': '삭제할 메모',
              },
            ),
          ),
        ),
      ),
    );

    final item = find.byKey(const Key('receipt-item-0'));
    await tester.tap(item);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(item);
    await tester.pumpAndSettle();

    final itemInput = find.byKey(const Key('receipt-item-name-input-0'));
    expect(itemInput, findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.enterText(itemInput, '카페라떼');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    final priceInput = find.byKey(const Key('receipt-item-price-input-0'));
    expect(priceInput, findsOneWidget);
    await tester.enterText(priceInput, '6000');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(itemInput, findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.ensureVisible(find.byKey(const Key('receipt-memo-field')));
    await tester.tap(find.byKey(const Key('receipt-memo-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-receipt-memo')));
    await tester.pumpAndSettle();

    final payload = key.currentState!.buildPayload(source: 'ocr')!;
    expect((payload['items'] as List).single, {
      'item_name': '카페라떼',
      'quantity': 1,
      'unit_price': 6000,
    });
    expect(payload['memo'], isNull);
    expect(find.text('메모를 입력해 주세요'), findsOneWidget);
  });

  testWidgets('edits a ledger receipt item and clears its memo', (
    tester,
  ) async {
    final key = GlobalKey<EditableReceiptFormState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: EditableReceiptForm(
              key: key,
              editable: true,
              initialData: const {
                'store_name': '테스트 카페',
                'category': '카페',
                'payment_method': '카드',
                'items': [
                  {'item_name': '아메리카노', 'quantity': 1, 'unit_price': 4500},
                ],
                'memo': '삭제할 메모',
              },
            ),
          ),
        ),
      ),
    );

    final item = find.byKey(const Key('editable-receipt-item-0'));
    await tester.ensureVisible(item);
    await tester.tap(item);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(item);
    await tester.pumpAndSettle();
    final itemInput = find.byKey(const Key('editable-receipt-item-name-input'));
    expect(itemInput, findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.enterText(itemInput, '카페라떼');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    final priceInput = find.byKey(
      const Key('editable-receipt-item-price-input'),
    );
    expect(priceInput, findsOneWidget);
    await tester.enterText(priceInput, '6000');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(itemInput, findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);

    final memo = find.byKey(const Key('editable-receipt-memo-field'));
    await tester.ensureVisible(memo);
    await tester.tap(memo);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-editable-receipt-memo')));
    await tester.pumpAndSettle();

    final payload = key.currentState!.buildUpdatePayload()!;
    expect((payload['items'] as List).single, {
      'item_name': '카페라떼',
      'quantity': 1,
      'unit_price': 6000,
    });
    expect(payload['memo'], isNull);
  });

  testWidgets('품목 편집 화면은 키보드가 나와도 전체를 축소하지 않는다', (tester) async {
    final service = _FailingReceiptService();
    final screens = <Widget>[
      RegisterDirectScreen(financeService: service),
      ReceiptResultScreen(
        imagePath: 'receipt.jpg',
        financeService: service,
        initialData: const {
          'store_name': '테스트 카페',
          'items': [
            {'item_name': '아메리카노', 'quantity': 1, 'unit_price': 4500},
          ],
        },
      ),
      LedgerEditScreen(
        expenseId: 'expense-1',
        financeService: service,
        initialData: const {
          'store_name': '테스트 카페',
          'items': [
            {'item_name': '아메리카노', 'quantity': 1, 'unit_price': 4500},
          ],
        },
      ),
    ];

    for (final screen in screens) {
      await tester.pumpWidget(MaterialApp(theme: AppTheme.dark, home: screen));
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).resizeToAvoidBottomInset,
        isFalse,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
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
    expect(find.text('이전'), findsNothing);
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

  testWidgets('소비분석의 과거 월에서는 다음 달 화살표가 활성화된다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const AnalysisOverviewScreen()),
    );

    expect(find.text('8'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('analysis-next-month')));
    await tester.pump();
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('keeps bottom navigation fixed on long analysis screens', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const AnalysisOverviewScreen()),
    );
    final overviewNavigation = find.byType(AppBottomNavigation);
    final overviewTop = tester.getTopLeft(overviewNavigation).dy;
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(overviewNavigation).dy, overviewTop);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const AnalysisDetailScreen()),
    );
    await tester.pumpAndSettle();
    final detailNavigation = find.byType(AppBottomNavigation);
    final detailTop = tester.getTopLeft(detailNavigation).dy;
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(detailNavigation).dy, detailTop);
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

  testWidgets('opens spending goal screen from analysis detail', (
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
    expect(find.text('수입의 60%'), findsOneWidget);
    expect(find.text('수입의 80%'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('analysis-goal-close')));
    await tester.pumpAndSettle();

    expect(find.byType(AnalysisGoalScreen), findsNothing);
    expect(find.byType(AnalysisDetailScreen), findsOneWidget);
  });

  testWidgets('renders profile menu', (tester) async {
    Uri? openedUri;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ProfileScreen(
          onOpenCustomerSupport: (uri) async => openedUri = uri,
        ),
      ),
    );

    expect(find.text('마이페이지'), findsOneWidget);
    expect(find.text('소비로그 님'), findsOneWidget);
    expect(find.text('출석 현황'), findsOneWidget);
    expect(find.text('계정 설정'), findsOneWidget);
    expect(find.text('고객 센터'), findsOneWidget);

    await tester.tap(find.text('고객 센터'));
    await tester.pump();
    expect(openedUri, Uri.parse('http://pf.kakao.com/_xbVZaX'));
  });
}

class _FailingReceiptService implements FinanceService {
  int recognitionCalls = 0;

  @override
  Future<Map<String, dynamic>> recognizeReceipt(String imagePath) async {
    recognitionCalls += 1;
    throw const ApiException(message: '영수증 인식 실패');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PendingFinanceService implements FinanceService {
  final _home = Completer<Map<String, dynamic>>();
  final _ledger = Completer<Map<String, dynamic>>();
  final _analysis = Completer<Map<String, dynamic>>();
  final _profile = Completer<Map<String, dynamic>>();
  final _detail = Completer<Map<String, dynamic>>();

  @override
  Future<Map<String, dynamic>> home() => _home.future;

  @override
  Future<Map<String, dynamic>> ledger({
    required String period,
    required DateTime anchor,
    String type = 'all',
    List<String> categories = const [],
    List<String> paymentMethods = const [],
  }) => _ledger.future;

  @override
  Future<Map<String, dynamic>> analysis({
    required int year,
    required int month,
  }) => _analysis.future;

  @override
  Future<Map<String, dynamic>> profile() => _profile.future;

  @override
  Future<Map<String, dynamic>> expenseDetail(String id) => _detail.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingAuthService implements AuthService {
  String? verifiedCode;
  String? signupEmail;
  String? signupNickname;
  bool? marketingAgreed;

  @override
  Future<void> verifyCode({required String email, required String code}) async {
    verifiedCode = code;
  }

  @override
  Future<void> signup({
    required String email,
    required String password,
    required String nickname,
    required bool marketingAgreed,
  }) async {
    signupEmail = email;
    signupNickname = nickname;
    this.marketingAgreed = marketingAgreed;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
