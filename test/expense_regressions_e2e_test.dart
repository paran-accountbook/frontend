import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/finance/data/finance_service.dart';
import 'package:sobilog/features/home/presentation/home_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_detail_screen.dart';
import 'package:sobilog/features/register/presentation/expense_registration_complete_screen.dart';
import 'package:sobilog/features/register/presentation/receipt_result_screen.dart';

void main() {
  testWidgets('OCR 결과의 0원 품목을 삭제하지 않고 지출로 등록한다', (tester) async {
    final service = _ExpenseFlowService();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ReceiptResultScreen(
          imagePath: '',
          financeService: service,
          initialData: const {
            'store_name': '테스트 카페',
            'category': '카페',
            'items': [
              {'item_name': '커피', 'quantity': 1, 'unit_price': 4500},
              {'item_name': '리뷰이벤트', 'quantity': 1, 'unit_price': 0},
            ],
          },
        ),
      ),
    );

    await tester.ensureVisible(find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(service.createdPayload?['items'], [
      {'item_name': '커피', 'quantity': 1, 'unit_price': 4500},
      {'item_name': '리뷰이벤트', 'quantity': 1, 'unit_price': 0},
    ]);
    expect(find.byType(ExpenseRegistrationCompleteScreen), findsOneWidget);
  });

  testWidgets('서버 메모가 비어 있으면 예시 문구 대신 안내 문구를 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LedgerDetailScreen(
          expenseId: 'expense-1',
          financeService: _ExpenseFlowService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('메모를 입력해 주세요'), findsOneWidget);
    expect(find.text('과제하다가 친구랑 마심'), findsNothing);
  });

  testWidgets('홈 최근 등록 내역은 지출에 음수, 수입에 양수 부호를 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: HomeScreen(financeService: _ExpenseFlowService()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('-81,000'), findsOneWidget);
    expect(find.text('+30,000'), findsOneWidget);
    expect(find.text('+81,000'), findsNothing);
  });
}

class _ExpenseFlowService implements FinanceService {
  Map<String, Object?>? createdPayload;

  @override
  Future<Map<String, dynamic>> createExpense(Map<String, Object?> body) async {
    createdPayload = body;
    return {
      'id': 'expense-1',
      'store_name': body['store_name'],
      'total_amount': 4500,
      'can_dutch_pay': false,
    };
  }

  @override
  Future<Map<String, dynamic>> expenseDetail(String id) async => {
    'id': id,
    'store_name': '테스트 카페',
    'total_amount': 4500,
    'memo': null,
    'items': [
      {'item_name': '커피', 'quantity': 1, 'unit_price': 4500},
    ],
  };

  @override
  Future<Map<String, dynamic>> home() async => {
    'summary': {'has_records': true, 'total_expense_amount': 81000},
    'recent': {
      'entries': [
        {
          'id': 'expense-1',
          'type': 'expense',
          'label': '테스트 카페',
          'amount': 81000,
          'date': '2026-10-11',
        },
        {
          'id': 'income-1',
          'type': 'income',
          'label': '용돈',
          'amount': 30000,
          'date': '2026-10-11',
        },
      ],
    },
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
