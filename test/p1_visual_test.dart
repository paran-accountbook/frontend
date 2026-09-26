import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/analysis/presentation/analysis_goal_screen.dart';
import 'package:sobilog/features/auth/presentation/login_screen.dart';
import 'package:sobilog/features/dutch/presentation/dutch_assignment_screen.dart';
import 'package:sobilog/features/dutch/presentation/dutch_people_screen.dart';
import 'package:sobilog/features/dutch/presentation/dutch_request_screen.dart';
import 'package:sobilog/features/dutch/presentation/dutch_result_screen.dart';
import 'package:sobilog/features/profile/presentation/attendance_screen.dart';
import 'package:sobilog/features/profile/presentation/notification_settings_screen.dart';
import 'package:sobilog/features/profile/presentation/reward_screen.dart';
import 'package:sobilog/features/register/presentation/register_income_screen.dart';

void main() {
  setUpAll(() async {
    final pretendard = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Medium.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'));
    final amarante = FontLoader('Amarante')
      ..addFont(rootBundle.load('assets/fonts/Amarante-Regular.ttf'));
    final bujangnim = FontLoader('BujangnimNunchi')
      ..addFont(rootBundle.load('assets/fonts/BujangnimNunchi-Regular.ttf'));
    await Future.wait([pretendard.load(), amarante.load(), bujangnim.load()]);
  });

  Future<void> expectP1Golden(
    WidgetTester tester,
    Widget screen,
    String filename,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark, home: screen));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/p1/$filename.png'),
    );
  }

  testWidgets('P1 kakao login visual', (tester) async {
    await expectP1Golden(tester, const LoginScreen(), 'kakao_login');
  });

  testWidgets('P1 dutch people visual', (tester) async {
    await expectP1Golden(tester, const DutchPeopleScreen(), 'dutch_people');
  });

  testWidgets('P1 dutch assignment visual', (tester) async {
    await expectP1Golden(
      tester,
      const DutchAssignmentScreen(),
      'dutch_assignment',
    );
  });

  testWidgets('P1 dutch result visual', (tester) async {
    await expectP1Golden(tester, const DutchResultScreen(), 'dutch_result');
  });

  testWidgets('P1 dutch request visual', (tester) async {
    await expectP1Golden(tester, const DutchRequestScreen(), 'dutch_request');
  });

  testWidgets('P1 income visual', (tester) async {
    await expectP1Golden(
      tester,
      RegisterIncomeScreen(
        initialData: {
          'amount': 30000,
          'income_date': DateTime(2026, 9, 1, 15, 20).toIso8601String(),
          'category': '급여',
          'memo': '안녕하세요',
        },
      ),
      'income',
    );
  });

  testWidgets('P1 goal visual', (tester) async {
    await expectP1Golden(tester, const AnalysisGoalScreen(), 'goal');
  });

  testWidgets('P1 attendance visual', (tester) async {
    await expectP1Golden(
      tester,
      AttendanceScreen(
        today: DateTime(2026, 8, 16),
        initialMonth: DateTime(2026, 8),
        initialData: const {
          'current_streak': 7,
          'max_streak': 14,
          'this_month_recorded_days': 9,
          'this_month_recording_rate': 56.25,
          'this_month_no_spend_days': 3,
          'recorded_dates': [
            '2026-08-02',
            '2026-08-03',
            '2026-08-04',
            '2026-08-05',
            '2026-08-06',
            '2026-08-08',
            '2026-08-13',
            '2026-08-16',
            '2026-08-28',
          ],
          'no_spend_dates': ['2026-08-04', '2026-08-05', '2026-08-13'],
        },
      ),
      'attendance',
    );
  });

  testWidgets('income values share the Figma right alignment guide', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: RegisterIncomeScreen(
          initialData: {
            'amount': 30000,
            'income_date': DateTime(2026, 9, 1, 15, 20).toIso8601String(),
            'category': '급여',
          },
        ),
      ),
    );

    final valueRights = [
      'income-amount-value',
      'income-date-value',
      'income-category-value',
    ].map((key) => tester.getRect(find.byKey(Key(key))).right).toList();
    final chevronRights = [
      'income-amount-chevron',
      'income-date-chevron',
      'income-category-chevron',
    ].map((key) => tester.getRect(find.byKey(Key(key))).right).toList();

    expect(valueRights.toSet(), hasLength(1));
    expect(chevronRights.toSet(), hasLength(1));
    expect(valueRights.first, 348);
    expect(chevronRights.first, 378);
    expect(find.text('2026년 9월 1일'), findsOneWidget);
  });

  testWidgets('attendance calendar renders all three record states', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: AttendanceScreen(
          today: DateTime(2026, 8, 16),
          initialMonth: DateTime(2026, 8),
          initialData: const {
            'calendar': [
              {'date': '2026-08-02', 'status': 'recorded'},
              {'date': '2026-08-04', 'status': 'no_spend'},
            ],
          },
        ),
      ),
    );

    expect(find.byKey(const Key('attendance-day-2-recorded')), findsOneWidget);
    expect(find.byKey(const Key('attendance-day-4-no-spend')), findsOneWidget);
    expect(find.byKey(const Key('attendance-day-3-none')), findsOneWidget);
  });

  testWidgets('P1 notification visual', (tester) async {
    await expectP1Golden(
      tester,
      const NotificationSettingsScreen(),
      'notification',
    );
  });

  testWidgets('P1 reward visual', (tester) async {
    await expectP1Golden(tester, const RewardScreen(), 'reward');
  });
}
