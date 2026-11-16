import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/features/category/data/category_service.dart';
import 'package:sobilog/features/ledger/presentation/ledger_screen.dart';

import 'p2_fake_service.dart';
import 'p2_harness.dart';

Widget _ledger(FakeP2Service service, {int period = 0, DateTime? anchor}) =>
    LedgerScreen(
      financeService: service,
      initialPeriod: period,
      initialAnchor: anchor ?? DateTime(2026, 8, 19),
      currentDate: DateTime(2026, 8, 31),
    );

void main() {
  setUpAll(loadAppFonts);
  setUp(() {
    CategoryStore.instance.reset();
    resetLedgerFilterMemory();
  });

  testWidgets('가계_002 필터 시트 - 전체 탭 지출/수입 전환과 N건 보기', (tester) async {
    final service = FakeP2Service();
    await showScreen(tester, _ledger(service));
    await capture(tester, '가계_001-01_가계부 목록 [월 탭·필터 진입]');
    await tapAndSettle(tester, find.byKey(const Key('ledger-filter-button')));
    expect(find.text('카테고리'), findsOneWidget);
    expect(find.text('결제수단'), findsOneWidget);
    expect(find.text('취미'), findsOneWidget);
    await tapAndSettle(
      tester,
      find.byKey(const Key('category-chip-expense-식비')),
    );
    await tapAndSettle(tester, find.byKey(const Key('ledger-payment-현금')));
    expect(find.text('1건 보기'), findsOneWidget);
    await capture(tester, '가계_002-01_필터 시트 [전체 탭]');
    await tapAndSettle(
      tester,
      find.byKey(const Key('ledger-filter-side-income')),
    );
    expect(find.text('결제수단'), findsNothing);
    expect(find.text('알바'), findsOneWidget);
    await tapAndSettle(
      tester,
      find.byKey(const Key('category-chip-income-급여')),
    );
    await capture(tester, '가계_002-01_필터 시트 [전체 탭·수입]');
  });
}
