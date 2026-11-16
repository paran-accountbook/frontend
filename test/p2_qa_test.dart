import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sobilog/core/constants/app_assets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/analysis/presentation/analysis_overview_screen.dart';
import 'package:sobilog/features/dutch/data/dutch_pay_service.dart';
import 'package:sobilog/features/dutch/presentation/dutch_people_screen.dart';
import 'package:sobilog/features/dutch/presentation/dutch_request_screen.dart';
import 'package:sobilog/features/finance/data/finance_service.dart';
import 'package:sobilog/features/finance/data/payment_methods.dart';
import 'package:sobilog/features/home/presentation/home_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_detail_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_screen.dart';
import 'package:sobilog/features/profile/presentation/profile_edit_screen.dart';
import 'package:sobilog/features/register/presentation/receipt_result_screen.dart';
import 'package:sobilog/features/register/presentation/register_direct_screen.dart';
import 'package:sobilog/features/register/presentation/register_income_screen.dart';

const _captureRoot = Key('qa-capture-root');
const _output = String.fromEnvironment('QA_SCREENSHOTS');

void main() {
  setUpAll(() async {
    if (_output.isEmpty) return;
    final pretendard = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Medium.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'));
    final amarante = FontLoader('Amarante')
      ..addFont(rootBundle.load('assets/fonts/Amarante-Regular.ttf'));
    final brand = FontLoader('BujangnimNunchi')
      ..addFont(rootBundle.load('assets/fonts/BujangnimNunchi-Regular.ttf'));
    final material = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([
      pretendard.load(),
      amarante.load(),
      brand.load(),
      material.load(),
    ]);
  });

  for (final editing in [false, true]) {
    testWidgets('QA 07 수입일 휠에서 취소 및 확정 후 날짜만 저장 ($editing)', (tester) async {
      final service = _Service();
      await _show(
        tester,
        RegisterIncomeScreen(
          incomeId: editing ? 'income-1' : null,
          initialData: const {'amount': 30000, 'income_date': '2026-09-10'},
          financeService: service,
        ),
        size: const Size(375, 667),
      );
      final date = find.byKey(const Key('income-date-picker'));
      final dateValue = find.byKey(const Key('income-date-value'));
      final before = tester.widget<Text>(dateValue).data;
      for (final confirm in [false, true]) {
        await _tap(tester, date);
        final wheels = find.byType(CupertinoPicker);
        expect(wheels, findsNWidgets(3));
        await tester.drag(wheels.last, const Offset(0, -46));
        await tester.pumpAndSettle();
        await _capture(tester, '01-income-date');
        await _tap(
          tester,
          find.byKey(
            Key(
              confirm
                  ? 'complete-income-date-picker'
                  : 'close-income-date-picker',
            ),
          ),
        );
        expect(tester.widget<Text>(dateValue).data == before, !confirm);
      }
      await _tap(tester, find.text(editing ? '수정 완료' : '저장'));
      final body = service.savedIncome!;
      expect(body['income_date'], matches(r'^2026-09-1[1-3]$'));
      expect(service.updatedIncomeId, editing ? 'income-1' : null);
    });
  }

  testWidgets('QA 08 작은 화면에서 모든 카테고리를 선택하고 완료해야 저장된다', (tester) async {
    final service = _Service();
    await _show(
      tester,
      RegisterIncomeScreen(
        financeService: service,
        initialData: const {'amount': 30000},
      ),
      size: const Size(375, 667),
    );
    await _tap(tester, find.byKey(const Key('income-category-picker')));
    for (var index = 0; index < 5; index++) {
      expect(
        find.byKey(ValueKey('income-category-option-$index')).hitTestable(),
        findsOneWidget,
      );
    }
    final done = find.byKey(const Key('complete-income-category-picker'));
    await _tap(tester, find.byKey(const ValueKey('income-category-option-4')));
    expect(done.hitTestable(), findsOneWidget);
    await _capture(tester, '02-income-category');
    await _tap(tester, done);
    expect(find.text('기타'), findsOneWidget);
    await _tap(tester, find.text('저장'));
    expect(service.savedIncome?['category'], '기타');
  });

  testWidgets('QA 01 직접 등록의 품목 행에서 이름과 단가를 편집한다', (tester) async {
    final service = _Service();
    await _show(tester, RegisterDirectScreen(financeService: service));
    expect(find.text('단가 입력'), findsOneWidget);
    await _tap(tester, find.text('입력해 주세요'));
    await tester.enterText(find.byType(TextFormField), '아주대학교');
    await _tap(tester, find.text('확인'));
    _expectPaymentChips(tester);
    final strip = find.byKey(const Key('receipt-payment-method-scroll'));
    final transfer = find.text('계좌이체');
    expect(transfer.hitTestable(), findsNothing);
    await tester.drag(strip, const Offset(-310, 0));
    await tester.pumpAndSettle();
    expect(transfer.hitTestable(), findsOneWidget);
    await _tap(tester, transfer);
    await _editReceiptItem(tester, '수정한 품목', '4200');
    await _tap(tester, find.text('현금'));
    for (final scroll in tester.stateList<ScrollableState>(
      find.byType(Scrollable),
    )) {
      scroll.position.jumpTo(0);
    }
    await tester.pumpAndSettle();
    await _capture(tester, '01-direct-payment-badges');
    await _tap(tester, transfer);
    await _tap(tester, find.text('저장'));
    expect(service.savedExpense?['payment_method'], '계좌이체');
    expect(service.savedExpense?['items'], [
      {'item_name': '수정한 품목', 'quantity': 1, 'unit_price': 4200},
    ]);
  });

  testWidgets('QA 04 OCR 단가 수정 중 저장을 숨기고 키패드를 닫으면 폼 끝에서 저장할 수 있다', (
    tester,
  ) async {
    final service = _Service();
    await _show(
      tester,
      ReceiptResultScreen(
        imagePath: '',
        initialData: {
          ..._expense,
          'payment_method': '현금',
          'items': List.filled(
            3,
            _expense['items'] as List,
          ).expand((items) => items).toList(),
        },
        financeService: service,
      ),
    );
    _expectPaymentChips(tester);
    await _capture(tester, '02-ocr-payment-badges');
    await _tap(tester, find.text('간편결제'));
    await _tap(tester, find.byKey(const Key('receipt-item-0')));
    final price = find.byKey(const Key('receipt-item-price-input-0'));
    await tester.enterText(price, '6500');
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.ensureVisible(price);
    await tester.pumpAndSettle();
    expect(price.hitTestable(), findsOneWidget);
    expect(find.text('저장'), findsNothing);
    expect(tester.testTextInput.isVisible, isTrue);
    await _capture(tester, '04-ocr-price-keyboard-layout');
    await tester.tapAt(const Offset(14, 112));
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
    expect(price, findsNothing);
    final save = find.text('저장');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    expect(save.hitTestable(), findsOneWidget);
    final list = tester.state<ScrollableState>(find.byType(Scrollable).first);
    list.position.jumpTo(0);
    await tester.pumpAndSettle();
    expect(save.hitTestable(), findsNothing);
    await _capture(tester, '05-ocr-payment-methods');
    await _tap(tester, save);
    expect(service.savedExpense?['payment_method'], '간편결제');
    expect((service.savedExpense?['items'] as List).first['unit_price'], 6500);
  });

  testWidgets('QA 02 더치페이 인원 입력은 키보드 높이가 생겨도 가로 크기를 유지한다', (tester) async {
    await _show(tester, const DutchPeopleScreen());
    final input = find.byType(TextField).first;
    final width = tester.getRect(input).width;
    await tester.enterText(input, '민정');
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();
    expect(tester.getRect(input).width, closeTo(width, 1));
    expect(input.hitTestable(), findsOneWidget);
    expect(tester.widget<TextField>(input).controller?.text, '민정');
    expect(tester.testTextInput.isVisible, isTrue);
    await _capture(tester, '06-dutch-people-keyboard-layout');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.text('민정'), findsOneWidget);
    expect(tester.widget<TextField>(input).controller?.text, isEmpty);
  });

  testWidgets('QA 09 정산 요청과 프로필에서 공용 은행 선택 시트를 연다', (tester) async {
    final dutch = _DutchAccountService();
    await _show(
      tester,
      DutchRequestScreen(sessionId: 'qa-settlement', dutchPayService: dutch),
    );
    await _tap(tester, find.text('계좌 등록하기'));
    _expectKbankLogo(tester);
    await _capture(tester, '07-dutch-bank-picker');
    final customBank = find.text('기타 (직접 입력)');
    final bankName = find.byKey(const Key('settlement-custom-bank-name'));
    final number = find.byKey(const Key('settlement-account-number'));
    final register = find.byKey(
      const Key('register-settlement-account-number'),
    );
    await _tap(tester, customBank);
    expect(find.byKey(const Key('change-settlement-bank')), findsOneWidget);
    expect(tester.widget<FilledButton>(register).onPressed, isNull);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(of: bankName, matching: find.byType(EditableText)),
          )
          .focusNode
          .hasFocus,
      isTrue,
    );
    await _capture(tester, 'dutch-custom-bank-empty');
    await tester.enterText(bankName, '키움증권');
    await tester.enterText(number, '00000000000000');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(register).onPressed, isNotNull);
    await _capture(tester, 'dutch-custom-bank-filled');
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();
    await tester.ensureVisible(register);
    await tester.pumpAndSettle();
    expect(register.hitTestable(), findsOneWidget);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const Key('change-settlement-bank')));
    await _tap(tester, customBank);
    expect(tester.widget<TextField>(bankName).controller!.text, '키움증권');
    expect(tester.widget<TextField>(number).controller!.text, '00000000000000');
    await _tap(tester, find.byKey(const Key('change-settlement-bank')));
    await _tap(tester, find.text('케이뱅크'));
    expect(bankName, findsNothing);
    await tester.enterText(number, '123-456');
    expect(tester.widget<TextField>(number).controller!.text, '123456');
    await tester.pumpAndSettle();
    await _tap(
      tester,
      find.byKey(const Key('register-settlement-account-number')),
    );
    expect(dutch.savedAccount, {
      'bank_name': '케이뱅크',
      'bank_account_number': '123456',
    });
    expect(find.textContaining('케이뱅크 123456'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    final profile = _Service();
    await _show(tester, ProfileEditScreen(financeService: profile));
    await _tap(tester, find.byKey(const Key('edit-profile-account')));
    _expectKbankLogo(tester);
    await _capture(tester, '08-profile-bank-picker');
    await _tap(tester, find.text('케이뱅크'));
    await tester.enterText(number, '1234');
    await tester.pumpAndSettle();
    await _tap(
      tester,
      find.byKey(const Key('register-settlement-account-number')),
    );
    expect(find.text('케이뱅크'), findsOneWidget);
    expect(profile.savedProfile, {
      'bank_name': '케이뱅크',
      'bank_account_number': '1234',
    });
    await _tap(tester, find.byKey(const Key('edit-profile-account')));
    await _tap(tester, customBank);
    await tester.enterText(bankName, '테스트은행');
    await tester.enterText(number, '1234');
    await tester.pumpAndSettle();
    await _tap(
      tester,
      find.byKey(const Key('register-settlement-account-number')),
    );
    expect(find.text('테스트은행'), findsOneWidget);
    expect(profile.savedProfile, {
      'bank_name': '테스트은행',
      'bank_account_number': '1234',
    });
  });

  testWidgets('QA 03 작은 화면에서 지출 목표 안내가 줄바꿈된다', (tester) async {
    await _show(
      tester,
      AnalysisOverviewScreen(financeService: _Service()),
      size: const Size(375, 667),
    );
    final goal = find.text('이번 달 지출 목표를 등록하면 하루 사용 가능 금액을 확인할 수 있어요');
    await Scrollable.ensureVisible(tester.element(goal), alignment: .38);
    await tester.pumpAndSettle();
    final paragraph = tester.renderObject<RenderParagraph>(goal);
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(tester.getRect(goal).bottom, lessThan(667));
    expect(goal.hitTestable(), findsOneWidget);
    await _capture(tester, '09-analysis-goal-copy');
  });

  testWidgets('QA 01·02 상세 품목 입력이 키보드 위에서 같은 폭을 유지한다', (tester) async {
    await _show(
      tester,
      LedgerDetailScreen(expenseId: 'expense-1', financeService: _Service()),
    );
    final paymentRow = find.byKey(const Key('receipt-payment-method-row'));
    expect(paymentRow, findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    await _capture(tester, '03-ledger-detail-unsettled');
    await tester.tap(paymentRow);
    await tester.pumpAndSettle();
    _expectPaymentChips(tester);
    await _capture(tester, '05-ledger-payment-picker');
    await tester.tapAt(const Offset(30, 90));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: paymentRow, matching: find.text('간편결제')),
      findsOneWidget,
    );
    final row = find.byKey(const Key('receipt-item-0'));
    final width = tester.getSize(row).width;
    await _editReceiptItem(tester, '수정한 커피', '4800', expectedWidth: width);
    expect(find.text('수정한 커피'), findsOneWidget);
    expect(find.text('단가'), findsWidgets);
    expect(find.text('4,800원'), findsWidgets);
    final addPhoto = find.byKey(const Key('add-expense-photo'));
    await tester.ensureVisible(addPhoto);
    await tester.pumpAndSettle();
    expect(addPhoto.hitTestable(), findsOneWidget);
    final save = find.byKey(const Key('save-ledger-entry'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    expect(save.hitTestable(), findsOneWidget);
    await _capture(tester, '11-ledger-detail-photos');
  });

  testWidgets('정산 완료 상세에서도 결제수단 행에서 값을 바꾼다', (tester) async {
    await _show(
      tester,
      LedgerDetailScreen(
        expenseId: 'expense-1',
        financeService: _Service(
          expense: {
            ..._expense,
            'dutch_pay_status': 'completed',
            'payment_method': '현금',
          },
        ),
      ),
    );
    expect(find.text('정산결과'), findsOneWidget);
    await _capture(tester, '04-ledger-detail-settled');
    final paymentRow = find.byKey(const Key('receipt-payment-method-row'));
    await _tap(tester, paymentRow);
    await _tap(tester, find.text('신용카드'));
    expect(
      find.descendant(of: paymentRow, matching: find.text('신용카드')),
      findsOneWidget,
    );
  });

  testWidgets('QA 06 긴 가맹점명과 품목명만 말줄임하고 금액과 결제수단을 유지한다', (tester) async {
    await _show(
      tester,
      LedgerScreen(financeService: _Service()),
      size: const Size(320, 667),
    );
    final store = find.text(_longStore);
    final item = find.text(_longItem);
    final extra = find.text('외 2건');
    final method = find.text('간편결제');
    final amount = find.text('-128,500').last;
    for (final clipped in [store, item]) {
      expect(tester.widget<Text>(clipped).overflow, TextOverflow.ellipsis);
      expect(
        tester.renderObject<RenderParagraph>(clipped).didExceedMaxLines,
        isTrue,
      );
    }
    for (final full in [extra, method, amount]) {
      expect(
        tester.renderObject<RenderParagraph>(full).didExceedMaxLines,
        isFalse,
      );
      expect(tester.getRect(full).right, lessThan(320));
    }
    expect(tester.getRect(store).right, lessThan(tester.getRect(amount).left));
    expect(tester.getRect(item).right, lessThan(tester.getRect(extra).left));
    expect(tester.getRect(extra).right, lessThan(tester.getRect(method).left));
    expect(tester.getCenter(extra).dy, closeTo(tester.getCenter(method).dy, 1));
    expect(tester.takeException(), isNull);
    await _capture(tester, '12-ledger-long-entry');
  });

  testWidgets('QA 12 지출 필터에서 결제수단 6종을 적용한다', (tester) async {
    await _show(tester, LedgerScreen(financeService: _Service()));
    await _tap(tester, find.byKey(const Key('ledger-filter-button')));
    for (final method in _expectedPaymentMethods) {
      expect(find.byKey(Key('ledger-payment-$method')), findsOneWidget);
    }
    expect(find.byKey(const Key('category-chip-income-급여')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('ledger-payment-간편결제')));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const Key('ledger-payment-간편결제')));
    await _capture(tester, '13-ledger-expense-filter');
    await _tap(tester, find.byKey(const Key('apply-ledger-filter')));
    expect(find.byKey(const Key('ledger-applied-filter-간편결제')), findsOneWidget);
    expect(find.text(_longStore), findsOneWidget);
    expect(find.text('필터에서 제외할 현금 지출'), findsNothing);

    await _tap(tester, find.byKey(const Key('ledger-entry-type-2')));
    // P2: 수입 탭에도 필터가 있고, 탭을 바꾸면 고른 필터는 초기화된다.
    expect(find.byKey(const Key('ledger-filter-button')), findsOneWidget);
    expect(find.byKey(const Key('ledger-applied-filter-간편결제')), findsNothing);
    expect(find.text('급여'), findsOneWidget);
  });

  for (final home in [true, false]) {
    testWidgets('QA 10 홈과 가계부가 Figma 수입 아이콘을 렌더링한다 (홈: $home)', (tester) async {
      final service = _Service();
      await _show(
        tester,
        home
            ? HomeScreen(financeService: service)
            : LedgerScreen(financeService: service),
      );
      if (!home) {
        await _tap(tester, find.byKey(const Key('ledger-entry-type-2')));
      }
      for (final asset in [
        AppAssets.incomeSalary,
        AppAssets.incomeAllowance,
        AppAssets.incomeSideIncome,
      ]) {
        final finder = find.byWidgetPredicate((widget) {
          if (widget is! SvgPicture) return false;
          final loader = widget.bytesLoader;
          return loader is SvgAssetLoader && loader.assetName == asset;
        });
        expect(finder, findsOneWidget);
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        expect(finder.hitTestable(), findsOneWidget);
      }
      await _capture(
        tester,
        home ? 'home-income-icons' : 'ledger-income-icons',
      );
    });
  }

  test('QA 12 기존 결제수단은 P2 값으로 정규화된다', () {
    expect(normalizePaymentMethod('카드'), '체크카드');
    for (final method in [null, '미지정', '직접 입력', '지역화폐']) {
      expect(normalizePaymentMethod(method), '기타');
    }
    for (final method in _expectedPaymentMethods) {
      expect(normalizePaymentMethod(method), method);
    }
  });
}

const _expectedPaymentMethods = ['현금', '체크카드', '신용카드', '간편결제', '계좌이체', '기타'];
const _longStore = '소비로그 매장 이름이 화면 너비를 넘을 정도로 길 때';
const _longItem = '아주 긴 품목 이름이 금액과 결제수단을 가리던 사례';

void _expectPaymentChips(WidgetTester tester) {
  expect(
    tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .map((chip) => (chip.label as Text).data),
    _expectedPaymentMethods,
  );
}

void _expectKbankLogo(WidgetTester tester) {
  final image = tester.widget<Image>(
    find.byKey(const ValueKey('bank-logo-케이뱅크')),
  );
  expect((image.image as AssetImage).assetName, 'assets/bank_logos/kbank.png');
}

Future<void> _editReceiptItem(
  WidgetTester tester,
  String name,
  String price, {
  double? expectedWidth,
}) async {
  final row = find.byKey(const Key('receipt-item-0'));
  await tester.ensureVisible(row);
  final bounds = tester.getRect(row);
  expect(bounds.height, greaterThanOrEqualTo(48));
  await tester.tapAt(bounds.bottomLeft + const Offset(8, -6));
  await tester.pumpAndSettle();
  final nameField = find.byKey(const Key('receipt-item-name-input-0'));
  final priceField = find.byKey(const Key('receipt-item-price-input-0'));
  await tester.enterText(nameField, name);
  await tester.enterText(priceField, price);
  if (expectedWidth != null) {
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.ensureVisible(priceField);
    await tester.pumpAndSettle();
    expect(priceField.hitTestable(), findsOneWidget);
    expect(tester.getSize(row).width, closeTo(expectedWidth, 1));
    expect(tester.testTextInput.isVisible, isTrue);
  }
  await tester.tapAt(const Offset(14, 112));
  tester.view.resetViewInsets();
  await tester.pumpAndSettle();
  expect(tester.testTextInput.isVisible, isFalse);
  expect(nameField, findsNothing);
}

Future<void> _show(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(402, 874),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _captureRoot,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_output.isEmpty) return;
  if (name.endsWith('bank-picker')) {
    final logos = tester.widgetList<Image>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName.startsWith(
              'assets/bank_logos/',
            ),
      ),
    );
    await tester.runAsync(
      () => Future.wait([
        for (final logo in logos)
          precacheImage(logo.image, tester.element(find.byType(GridView))),
      ]),
    );
  }
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureRoot),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    await File('$_output/$name.png').writeAsBytes(png.buffer.asUint8List());
    image.dispose();
  });
}

const _expense = <String, dynamic>{
  'id': 'expense-1',
  'store_name': '소비로그 테스트 카페',
  'category': '카페',
  'payment_method': '간편결제',
  'items': [
    {'item_name': '아메리카노', 'quantity': 2, 'unit_price': 4500},
    {'item_name': '바닐라 라떼', 'quantity': 1, 'unit_price': 5500},
  ],
};

class _Service implements FinanceService, ExpensePhotoService {
  _Service({this.expense = _expense});

  final Map<String, dynamic> expense;
  Map<String, Object?>? savedExpense;
  Map<String, Object?>? savedIncome;
  Map<String, Object?>? savedProfile;

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, Object?> body) async {
    savedProfile = body;
    return {...body};
  }

  String? updatedIncomeId;

  @override
  Future<Map<String, dynamic>> createExpense(Map<String, Object?> body) async {
    savedExpense = body;
    return {'id': 'expense-1', ...body};
  }

  @override
  Future<Map<String, dynamic>> createIncome(Map<String, Object?> body) async {
    savedIncome = body;
    return {'id': 'income-1', ...body};
  }

  @override
  Future<Map<String, dynamic>> updateIncome(
    String id,
    Map<String, Object?> body,
  ) async {
    updatedIncomeId = id;
    return createIncome(body);
  }

  @override
  Future<Map<String, dynamic>> expenseDetail(String id) async => expense;

  @override
  Future<Map<String, dynamic>> ledger({
    required String period,
    required DateTime anchor,
    String type = 'all',
    List<String> categories = const [],
    List<String> paymentMethods = const [],
  }) async {
    final expenses = [
      if (type != 'income' &&
          (paymentMethods.isEmpty || paymentMethods.contains('간편결제')))
        {
          'id': 'expense-1',
          'store_name': _longStore,
          'representative_item_name': _longItem,
          'item_count': 3,
          'category': '카페',
          'payment_method': '간편결제',
          'amount': 128500,
          'paid_at': '2026-11-11T10:30:00+09:00',
        },
      if (type != 'income' &&
          (paymentMethods.isEmpty || paymentMethods.contains('현금')))
        {
          'id': 'expense-2',
          'store_name': '필터에서 제외할 현금 지출',
          'item_count': 1,
          'category': '카페',
          'payment_method': '현금',
          'amount': 1000,
          'paid_at': '2026-11-11T10:35:00+09:00',
        },
    ];
    final incomes = [
      if (type != 'expense')
        {'id': 'income-1', 'category': '급여', 'amount': 2500000},
      if (type != 'expense')
        {'id': 'income-2', 'category': '부수입', 'amount': 30000},
      if (type != 'expense')
        {'id': 'income-3', 'category': '용돈', 'amount': 10000},
    ];
    return {
      'expense_count': expenses.length,
      'income_count': incomes.length,
      'total_expense_amount': expenses.fold(
        0,
        (sum, item) => sum + (item['amount'] as int),
      ),
      'total_income_amount': incomes.fold(
        0,
        (sum, item) => sum + (item['amount'] as int),
      ),
      'unfiltered_total_expense_amount': 129500,
      'unfiltered_total_income_amount': 2540000,
      'days': [
        {'date': '2026-11-11', 'expenses': expenses, 'incomes': incomes},
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> home() async => {
    'summary': {'has_records': true, 'total_expense_amount': 128500},
    'recent': {
      'entries': [
        {'id': 'income-1', 'type': 'income', 'label': '급여', 'amount': 2500000},
        {'id': 'income-2', 'type': 'income', 'label': '부수입', 'amount': 30000},
        {'id': 'income-3', 'type': 'income', 'label': '용돈', 'amount': 10000},
      ],
    },
  };

  @override
  Future<Map<String, dynamic>> analysis({
    required int year,
    required int month,
  }) async => {
    'year': year,
    'month': month,
    'total_expense_amount': 128500,
    'total_income_amount': 2530000,
    'category_breakdown': [
      {'category': '카페', 'percentage': 100, 'amount': 128500},
    ],
    'goal': null,
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DutchAccountService implements DutchPayService {
  Map<String, dynamic>? savedAccount;

  @override
  Future<Map<String, dynamic>> summary(String sessionId) async => {
    'requests': [
      {'participant_id': 'qa-member', 'name': '정산 대상', 'amount': 3000},
    ],
  };

  @override
  Future<Map<String, dynamic>> updateAccount(
    String sessionId, {
    String? bankName,
    String? bankAccountNumber,
  }) async {
    expect(sessionId, 'qa-settlement');
    return savedAccount = {
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
