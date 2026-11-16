import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/features/category/data/category_service.dart';
import 'package:sobilog/features/ledger/presentation/ledger_detail_screen.dart';
import 'package:sobilog/features/register/presentation/receipt_result_screen.dart';
import 'package:sobilog/features/register/presentation/register_direct_screen.dart';

import 'p2_fake_service.dart';
import 'p2_harness.dart';

const _items = [
  {'item_name': '아메리카노', 'quantity': 3, 'unit_price': 4500},
  {'item_name': '아메리카노', 'quantity': 3, 'unit_price': 4500},
  {'item_name': '아메리카노', 'quantity': 3, 'unit_price': 4500},
];

void main() {
  setUpAll(loadAppFonts);
  setUp(CategoryStore.instance.reset);

  testWidgets('등록_010-01 직접 등록 품목 영역', (tester) async {
    final service = FakeP2Service();
    await showScreen(
      tester,
      RegisterDirectScreen(financeService: service),
      size: const Size(402, 1422),
    );
    await capture(tester, '등록_010-01_직접 등록');
  });

  testWidgets('등록_009-01 인식 결과 확인 품목 영역', (tester) async {
    final service = FakeP2Service();
    await showScreen(
      tester,
      ReceiptResultScreen(
        imagePath: '',
        financeService: service,
        initialData: const {
          'store_name': '아주대학교',
          'paid_at': '2026-09-01T15:20:00+09:00',
          'category': '카페',
          'payment_method': '현금',
          'items': _items,
        },
      ),
      size: const Size(402, 1274),
    );
    await capture(tester, '등록_009-01_인식 결과 확인');
  });

  testWidgets('가계_003-01 내역 상세 [미정산]', (tester) async {
    final service = FakeP2Service();
    await showScreen(
      tester,
      LedgerDetailScreen(expenseId: 'expense-1', financeService: service),
      size: const Size(402, 1640),
    );
    await capture(tester, '가계_003-01_내역 상세 [미정산]');
  });
}
