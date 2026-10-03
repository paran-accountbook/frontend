import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/shared/widgets/app_toast.dart';
import 'package:sobilog/features/dutch/presentation/dutch_request_screen.dart';
import 'package:sobilog/features/finance/data/finance_service.dart';
import 'package:sobilog/features/ledger/presentation/ledger_detail_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_edit_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_screen.dart';
import 'package:sobilog/features/register/presentation/expense_registration_complete_screen.dart';
import 'package:sobilog/features/register/presentation/register_income_screen.dart';

void main() {
  setUpAll(() async {
    final pretendard = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Medium.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'));
    final amarante = FontLoader('Amarante')
      ..addFont(rootBundle.load('assets/fonts/Amarante-Regular.ttf'));
    await Future.wait([pretendard.load(), amarante.load()]);
  });

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: screen,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/latest/$name.png'),
  );

  testWidgets('latest Dutch no-account state', (tester) async {
    await pumpScreen(
      tester,
      const DutchRequestScreen(settlementData: {'total_amount': 29000}),
    );
    expect(find.text('등록된 계좌가 없어요'), findsOneWidget);
    await capture(tester, 'dutch_no_account');
  });

  testWidgets('latest Dutch bank picker', (tester) async {
    await pumpScreen(tester, const DutchRequestScreen());
    tester
        .widget<GestureDetector>(
          find.byKey(const Key('edit-settlement-account')),
        )
        .onTap!();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('은행을 선택해 주세요'), findsOneWidget);
    await capture(tester, 'dutch_bank_picker');
  });

  testWidgets('latest Dutch account number input', (tester) async {
    await pumpScreen(tester, const DutchRequestScreen());
    tester
        .widget<GestureDetector>(
          find.byKey(const Key('edit-settlement-account')),
        )
        .onTap!();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    tester
        .widget<GestureDetector>(find.byKey(const ValueKey('bank-토스')))
        .onTap!();
    await tester.pumpAndSettle();
    expect(find.text('계좌번호 입력'), findsOneWidget);
    await capture(tester, 'dutch_account_input');
  });

  testWidgets('latest Dutch individual share sheet', (tester) async {
    await pumpScreen(
      tester,
      const DutchRequestScreen(
        settlementData: _sharePreviewData,
        selfName: '홍길동',
      ),
    );
    tester
        .widget<GestureDetector>(find.byKey(const ValueKey('dutch-share-p2')))
        .onTap!();
    await tester.pumpAndSettle();
    expect(find.text('철수에게 보낼 메시지'), findsOneWidget);
    expect(find.text('홍길동님이 철수님께 더치페이를 요청했어요'), findsOneWidget);
    await capture(tester, 'dutch_share_individual');
  });

  testWidgets('latest Dutch whole share sheet', (tester) async {
    await pumpScreen(
      tester,
      const DutchRequestScreen(
        settlementData: _sharePreviewData,
        selfName: '홍길동',
      ),
    );
    final button = find.text('전체 공유');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    tester
        .widget<GestureDetector>(
          find
              .ancestor(of: button, matching: find.byType(GestureDetector))
              .first,
        )
        .onTap!();
    await tester.pumpAndSettle();
    expect(find.text('전체 메시지 · 4명 총 50,800원'), findsOneWidget);
    expect(find.text('홍길동님이 더치페이를 요청했어요'), findsOneWidget);
    expect(find.text('영희'), findsWidgets);
    expect(find.text('민수'), findsWidgets);
    await capture(tester, 'dutch_share_all');
  });

  testWidgets('latest income date picker', (tester) async {
    await pumpScreen(
      tester,
      RegisterIncomeScreen(
        initialData: {
          'amount': 30000,
          'income_date': DateTime(2026, 9, 1, 15, 20).toIso8601String(),
          'category': '급여',
        },
      ),
    );
    await tester.tap(find.byKey(const Key('income-date-picker')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('income-date-wheel')), findsOneWidget);
    await capture(tester, 'income_date_picker');
  });

  testWidgets('latest expense detail', (tester) async {
    await pumpScreen(tester, const LedgerDetailScreen());
    await capture(tester, 'expense_detail');
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();
    await capture(tester, 'expense_detail_bottom');
  });

  testWidgets('expense detail item controls and double tap editing work', (
    tester,
  ) async {
    await pumpScreen(tester, const LedgerDetailScreen());

    await tester.tap(find.byKey(const Key('ledger-detail-item-add-0')));
    await tester.pump();
    expect(find.text('18,000원'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ledger-detail-item-remove-0')));
    await tester.pump();
    expect(find.text('18,000원'), findsNothing);

    final firstItem = find.byKey(const Key('ledger-detail-item-edit-0'));
    await tester.tap(firstItem);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(firstItem);
    await tester.pump();
    expect(find.byKey(const Key('ledger-detail-item-name-0')), findsOneWidget);
    expect(
      find.byKey(const Key('ledger-detail-item-unit-price-0')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('ledger-detail-item-name-0')),
      '바닐라라떼',
    );
    await tester.enterText(
      find.byKey(const Key('ledger-detail-item-unit-price-0')),
      '5000',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('바닐라라떼'), findsOneWidget);
    expect(find.text('5,000원'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ledger-detail-item-delete-1')));
    await tester.pump();
    expect(find.text('품목   2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('latest expense delete confirmation', (tester) async {
    await pumpScreen(
      tester,
      LedgerEditScreen(
        expenseId: 'expense',
        financeService: _NoopFinanceService(),
        initialData: const {
          'store_name': '00카페 DT점',
          'total_amount': 31500,
          'items': [
            {'item_name': '아메리카노', 'quantity': 2, 'unit_price': 4500},
          ],
        },
      ),
    );
    await tester.tap(find.byKey(const Key('delete-ledger-entry')));
    await tester.pumpAndSettle();
    expect(find.text('이 내역을 삭제할까요?'), findsOneWidget);
    await capture(tester, 'expense_delete_confirm');
  });

  testWidgets('latest expense deleted snackbar', (tester) async {
    await pumpScreen(
      tester,
      const LedgerScreen(
        initialData: {
          'total_expense_amount': 9000,
          'total_income_amount': 0,
          'expense_count': 1,
          'income_count': 0,
          'balance': -9000,
          'days': [
            {
              'date': '2026-08-19',
              'expenses': [
                {
                  'store_name': '아주대학교 카페',
                  'category': '카페',
                  'payment_method': '카드',
                  'amount': 4500,
                },
              ],
              'incomes': <Map<String, dynamic>>[],
            },
          ],
        },
      ),
    );
    ScaffoldMessenger.of(
      tester.element(find.byType(LedgerScreen)),
    ).showSnackBar(appSuccessToast('내역을 삭제했어요'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('내역을 삭제했어요'), findsOneWidget);
    await capture(tester, 'expense_deleted_snackbar');
  });

  testWidgets('latest expense completion with Dutch action', (tester) async {
    await pumpScreen(
      tester,
      ExpenseRegistrationCompleteScreen(
        expenseId: 'expense',
        financeService: _NoopFinanceService(),
        storeName: '00카페 DT점',
        totalAmount: 31500,
      ),
    );
    await capture(tester, 'expense_complete_with_dutch');
  });

  testWidgets('latest expense completion without Dutch action', (tester) async {
    await pumpScreen(
      tester,
      ExpenseRegistrationCompleteScreen(
        expenseId: 'expense',
        financeService: _NoopFinanceService(),
        storeName: '00카페 DT점',
        totalAmount: 31500,
        showDutchPay: false,
      ),
    );
    await capture(tester, 'expense_complete');
  });

  testWidgets('latest ledger income-zero prompt', (tester) async {
    await pumpScreen(
      tester,
      LedgerScreen(
        currentDate: DateTime(2026, 8, 19),
        initialData: {
          'total_expense_amount': 150000,
          'total_income_amount': 0,
          'expense_count': 2,
          'income_count': 0,
          'balance': -150000,
          'days': [
            {
              'date': '2024-08-19',
              'expenses': [
                {
                  'store_name': '아주대학교 카페',
                  'representative_item_name': '카페',
                  'item_count': 1,
                  'category': '카페',
                  'payment_method': '카드',
                  'paid_at': '2024-08-19T10:30:00+09:00',
                  'amount': 4500,
                },
                {
                  'store_name': '아주대학교 카페',
                  'representative_item_name': '카페',
                  'item_count': 1,
                  'category': '카페',
                  'payment_method': '카드',
                  'paid_at': '2024-08-19T10:30:00+09:00',
                  'amount': 4500,
                },
              ],
              'incomes': <Map<String, dynamic>>[],
            },
          ],
        },
      ),
    );
    expect(
      find.byKey(const Key('ledger-income-zero-register')),
      findsOneWidget,
    );
    expect(find.textContaining('오전 10:30'), findsNWidgets(2));
    await capture(tester, 'ledger_income_zero');
    await tester.tap(find.byKey(const Key('ledger-income-zero-register')));
    await tester.pumpAndSettle();
    expect(find.text('수입 등록'), findsOneWidget);
  });
}

const _sharePreviewData = <String, dynamic>{
  'bank_name': '아주은행',
  'bank_account_number': '000-0000-0000',
  'total_amount': 50800,
  'requests': [
    {'participant_id': 'p2', 'name': '철수', 'amount': 14500},
    {'participant_id': 'p3', 'name': '영희', 'amount': 12000},
    {'participant_id': 'p4', 'name': '민수', 'amount': 9800},
  ],
  'participants': [
    {'participant_id': 'self', 'name': '홍길동', 'amount': 14500, 'is_self': true},
    {'participant_id': 'p2', 'name': '철수', 'amount': 14500, 'is_self': false},
    {'participant_id': 'p3', 'name': '영희', 'amount': 12000, 'is_self': false},
    {'participant_id': 'p4', 'name': '민수', 'amount': 9800, 'is_self': false},
  ],
};

class _NoopFinanceService implements FinanceService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<Map<String, dynamic>>.value(const {});
}
