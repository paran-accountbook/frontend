import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/analysis/presentation/analysis_overview_screen.dart';
import 'package:sobilog/features/finance/data/finance_service.dart';

void main() {
  const captureKey = Key('analysis-goal-state-capture');

  setUpAll(() async {
    final pretendard = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Medium.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'));
    final amarante = FontLoader('Amarante')
      ..addFont(rootBundle.load('assets/fonts/Amarante-Regular.ttf'));
    await Future.wait([pretendard.load(), amarante.load()]);
  });

  Future<void> pumpAnalysis(
    WidgetTester tester, {
    required bool hasGoal,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: RepaintBoundary(
          key: captureKey,
          child: AnalysisOverviewScreen(
            initialMonth: DateTime(2026, 8),
            financeService: _AnalysisStateService(hasGoal: hasGoal),
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

  Future<void> scrollToBottom(WidgetTester tester) async {
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -1200),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Figma 1225:9248 목표 있음 상단과 하단', (tester) async {
    await pumpAnalysis(tester, hasGoal: true);
    expect(find.text('목표 등록하기'), findsNothing);
    expect(find.text('20%'), findsOneWidget);
    await capture(tester, 'analysis_with_goal_top');

    await scrollToBottom(tester);
    expect(find.text('413,700'), findsOneWidget);
    expect(find.text('17,200'), findsOneWidget);
    await capture(tester, 'analysis_with_goal_bottom');
  });

  testWidgets('Figma 1385:15192 목표 없음 상단과 하단', (tester) async {
    await pumpAnalysis(tester, hasGoal: false);
    expect(find.text('목표 등록하기'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    await capture(tester, 'analysis_without_goal_top');

    await scrollToBottom(tester);
    expect(find.text('남은 예산 -원 ÷ -일'), findsOneWidget);
    await capture(tester, 'analysis_without_goal_bottom');
  });
}

class _AnalysisStateService implements FinanceService {
  const _AnalysisStateService({required this.hasGoal});

  final bool hasGoal;

  @override
  Future<Map<String, dynamic>> analysis({
    required int year,
    required int month,
  }) async => {
    'year': year,
    'month': month,
    'total_expense_amount': 150000,
    'daily_average_expense': 40000,
    'total_income_amount': 150000,
    'income_count': 1,
    'balance': 150000,
    'change_amount': 2500,
    'change_rate': 12,
    'category_breakdown': _categories,
    'goal': hasGoal
        ? {
            'amount': 563700,
            'usage_rate': 20,
            'remaining_budget': 413700,
            'remaining_days': 24,
            'daily_budget_remaining': 17200,
          }
        : null,
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _categories = <Map<String, dynamic>>[
  {'category': '식비', 'percentage': 53, 'amount': 4500},
  {'category': '쇼핑', 'percentage': 30, 'amount': 4500},
  {'category': '카페', 'percentage': 8, 'amount': 4500},
  {'category': '의료', 'percentage': 4, 'amount': 4500},
  {'category': '교통', 'percentage': 3, 'amount': 4500},
  {'category': '문화', 'percentage': 2, 'amount': 4500},
  {'category': '교육', 'percentage': 2, 'amount': 4500},
  {'category': '기타', 'percentage': 2, 'amount': 4500},
];
