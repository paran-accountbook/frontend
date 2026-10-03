import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/finance/data/finance_service.dart';
import 'package:sobilog/features/home/presentation/home_screen.dart';
import 'package:sobilog/shared/widgets/app_skeleton.dart';

void main() {
  const captureKey = Key('home-figma-capture');

  setUpAll(() async {
    final pretendard = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Medium.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'));
    final amarante = FontLoader('Amarante')
      ..addFont(rootBundle.load('assets/fonts/Amarante-Regular.ttf'));
    final decorative = FontLoader('BujangnimNunchi')
      ..addFont(rootBundle.load('assets/fonts/BujangnimNunchi-Regular.ttf'));
    await Future.wait([pretendard.load(), amarante.load(), decorative.load()]);
  });

  Future<void> pumpHome(WidgetTester tester, FinanceService service) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: RepaintBoundary(
          key: captureKey,
          child: HomeScreen(financeService: service),
        ),
      ),
    );
  }

  Future<void> capture(WidgetTester tester, String name) => expectLater(
    find.byKey(captureKey),
    matchesGoldenFile('goldens/latest/$name.png'),
  );

  testWidgets('Figma 1225:10470 목표 미설정 및 수입 없음', (tester) async {
    await pumpHome(tester, const _HomeStateService(goalAndIncome: false));
    await tester.pumpAndSettle();

    expect(find.text('8월 목표'), findsNothing);
    expect(find.text('수입 30,000원'), findsNothing);
    expect(tester.getTopLeft(find.text('최근 등록 내역')).dy, closeTo(360, .1));
    await capture(tester, 'home_without_goal_or_income');
  });

  testWidgets('Figma 1225:10250 목표 설정 및 수입 있음', (tester) async {
    await pumpHome(tester, const _HomeStateService(goalAndIncome: true));
    await tester.pumpAndSettle();

    expect(find.text('8월 목표'), findsOneWidget);
    expect(find.text('수입 30,000원'), findsOneWidget);
    expect(find.text('잔액 10,000원'), findsOneWidget);
    expect(tester.getTopLeft(find.text('최근 등록 내역')).dy, closeTo(448, .1));
    await capture(tester, 'home_with_goal_and_income');
  });

  testWidgets('Figma 1225:10360 목표 및 수입 있음 로딩', (tester) async {
    await pumpHome(tester, _PendingHomeService());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('8월 목표'), findsOneWidget);
    expect(find.text('수입 30,000원'), findsOneWidget);
    expect(find.byType(AppSkeletonList), findsOneWidget);
    expect(tester.getTopLeft(find.text('최근 등록 내역')).dy, closeTo(448, .1));
    await capture(tester, 'home_with_goal_and_income_skeleton');
  });
}

class _HomeStateService implements FinanceService {
  const _HomeStateService({required this.goalAndIncome});

  final bool goalAndIncome;

  @override
  Future<Map<String, dynamic>> home() async => {
    'summary': {
      'year': 2026,
      'month': 8,
      'total_expense_amount': 150000,
      'change_amount': 2500,
      'change_rate': 12,
      'goal': goalAndIncome
          ? {'amount': 40000, 'usage_rate': 100, 'daily_budget_remaining': 0}
          : null,
      'total_income_amount': goalAndIncome ? 30000 : null,
      'balance': goalAndIncome ? 10000 : null,
      'income_count': goalAndIncome ? 1 : 0,
      'has_records': true,
    },
    'recent': {'entries': _recentEntries},
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PendingHomeService
    implements FinanceService, ProgressiveHomeFinanceService {
  final _recentResult = Completer<Map<String, dynamic>>();

  @override
  Future<Map<String, dynamic>> homeSummary() async =>
      (await const _HomeStateService(goalAndIncome: true).home())['summary']
          as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> homeRecent() => _recentResult.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _recentEntries = <Map<String, dynamic>>[
  {
    'id': 'expense-1',
    'type': 'expense',
    'label': '아주대학교 카페',
    'amount': 150000,
    'registered_at': '2026-08-19T10:30:00+09:00',
  },
  {
    'id': 'expense-2',
    'type': 'expense',
    'label': '아주대학교 카페',
    'amount': 150000,
    'registered_at': '2026-08-19T10:30:00+09:00',
  },
  {
    'id': 'expense-3',
    'type': 'expense',
    'label': '아주대학교 카페',
    'amount': 150000,
    'registered_at': '2026-08-19T10:30:00+09:00',
  },
];
