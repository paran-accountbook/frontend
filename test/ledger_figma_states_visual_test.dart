import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/finance/data/finance_service.dart';
import 'package:sobilog/features/ledger/presentation/ledger_screen.dart';

void main() {
  const captureKey = Key('ledger-figma-capture');
  setUpAll(() async {
    final pretendard = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Medium.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'));
    final amarante = FontLoader('Amarante')
      ..addFont(rootBundle.load('assets/fonts/Amarante-Regular.ttf'));
    await Future.wait([pretendard.load(), amarante.load()]);
  });

  Future<void> pumpLedger(
    WidgetTester tester, {
    required int period,
    required FinanceService service,
    required DateTime anchor,
  }) async {
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
        home: RepaintBoundary(
          key: captureKey,
          child: LedgerScreen(
            financeService: service,
            initialPeriod: period,
            initialAnchor: anchor,
            currentDate: DateTime(2026, 9, 3),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) => expectLater(
    find.byKey(captureKey),
    matchesGoldenFile('goldens/latest/$name.png'),
  );

  Future<void> applyFoodCardFilters(WidgetTester tester) async {
    await tester.tap(find.text('필터'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ledger-filter-식비')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ledger-filter-카드')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('apply-ledger-filter')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('Figma 1225:9677 day filtered results', (tester) async {
    await pumpLedger(
      tester,
      period: 2,
      anchor: DateTime(2026, 8, 25),
      service: _LedgerStateService(),
    );
    await applyFoodCardFilters(tester);
    expect(
      tester.widget<Text>(find.text('-182,400')).style?.color,
      const Color(0xFFE2E2F9),
    );
    await capture(tester, 'ledger_day_filtered_results');
  });

  testWidgets('Figma 1225:18467 week expense results', (tester) async {
    await pumpLedger(
      tester,
      period: 1,
      anchor: DateTime(2026, 8, 24),
      service: _LedgerStateService(),
    );
    await tester.tap(find.text('지출'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.widget<Text>(find.text('-118,600')).style?.color,
      const Color(0xFFE2E2F9),
    );
    await capture(tester, 'ledger_week_expense');
  });

  testWidgets('Figma 1225:18637 month income results', (tester) async {
    await pumpLedger(
      tester,
      period: 0,
      anchor: DateTime(2026, 8),
      service: _LedgerStateService(),
    );
    await tester.tap(find.text('수입'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.widget<Text>(find.text('+620,000')).style?.color,
      const Color(0xFFA8A3FF),
    );
    final summaryBottom = tester
        .getBottomLeft(find.text('2026년 8월 · 수입 2건'))
        .dy;
    final tabsTop = tester.getTopLeft(find.text('수입')).dy;
    expect(tabsTop - summaryBottom, lessThan(70));
    await capture(tester, 'ledger_month_income');
  });

  testWidgets('Figma 1225:18677 day filtered empty', (tester) async {
    await pumpLedger(
      tester,
      period: 2,
      anchor: DateTime(2026, 8, 25),
      service: _LedgerStateService(emptyFiltered: true),
    );
    await applyFoodCardFilters(tester);
    expect(find.text('-0'), findsNothing);
    expect(
      tester.widget<Text>(find.text('0')).style?.color,
      const Color(0xFFE2E2F9),
    );
    await capture(tester, 'ledger_day_filtered_empty');
  });
}

class _LedgerStateService implements FinanceService {
  _LedgerStateService({this.emptyFiltered = false});

  final bool emptyFiltered;

  @override
  Future<Map<String, dynamic>> ledger({
    required String period,
    required DateTime anchor,
    String type = 'all',
    List<String> categories = const [],
    List<String> paymentMethods = const [],
  }) async {
    final filtered = categories.isNotEmpty || paymentMethods.isNotEmpty;
    if (filtered) {
      return {
        'total_expense_amount': emptyFiltered ? 0 : 182400,
        'total_income_amount': 0,
        'expense_count': emptyFiltered ? 0 : 2,
        'income_count': 0,
        'balance': emptyFiltered ? 0 : -182400,
        'days': emptyFiltered
            ? <Map<String, dynamic>>[]
            : <Map<String, dynamic>>[
                {
                  'date': '2026-08-25',
                  'expenses': <Map<String, dynamic>>[
                    {
                      'id': 'expense-1',
                      'store_name': '이마트24 아주대점',
                      'category': '식비',
                      'payment_method': '카드',
                      'amount': 12800,
                      'representative_item_name': '식비',
                      'item_count': 1,
                      'paid_at': '2026-08-25T10:30:00',
                    },
                    {
                      'id': 'expense-2',
                      'store_name': '아주대 학생식당',
                      'category': '식비',
                      'payment_method': '카드',
                      'amount': 18900,
                      'representative_item_name': '식비',
                      'item_count': 1,
                      'paid_at': '2026-08-25T10:30:00',
                    },
                  ],
                  'incomes': <Map<String, dynamic>>[],
                },
              ],
      };
    }

    if (type == 'income') {
      return {
        'total_expense_amount': 0,
        'total_income_amount': 620000,
        'expense_count': 0,
        'income_count': 2,
        'balance': 620000,
        'days': <Map<String, dynamic>>[
          {
            'date': '2026-08-23',
            'expenses': <Map<String, dynamic>>[],
            'incomes': <Map<String, dynamic>>[
              {
                'id': 'income-1',
                'category': '근로장학금',
                'memo': '급여 · 오전 2:00',
                'amount': 320000,
              },
              {
                'id': 'income-2',
                'category': '8월 생활비',
                'memo': '용돈 · 오전 9:00',
                'amount': 300000,
              },
            ],
          },
        ],
      };
    }

    final weekly = period == 'week';
    return {
      'total_expense_amount': weekly ? 118600 : 486300,
      'total_income_amount': 620000,
      'expense_count': weekly ? 9 : 12,
      'income_count': 2,
      'balance': weekly ? 501400 : 133700,
      'days': <Map<String, dynamic>>[
        {
          'date': '2026-08-23',
          'expenses': <Map<String, dynamic>>[
            {
              'id': 'expense-3',
              'store_name': '아주대학교 카페',
              'category': '카페',
              'payment_method': '카드',
              'amount': 4500,
              'representative_item_name': '카페',
              'item_count': 1,
              'paid_at': '2026-08-23T10:30:00',
            },
            {
              'id': 'expense-4',
              'store_name': '아주대학교 카페',
              'category': '카페',
              'payment_method': '카드',
              'amount': 4500,
              'representative_item_name': '카페',
              'item_count': 1,
              'paid_at': '2026-08-23T10:30:00',
            },
          ],
          'incomes': <Map<String, dynamic>>[],
        },
      ],
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
