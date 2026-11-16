import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/network/api_exception.dart';
import 'package:sobilog/core/notifications/local_notifications.dart';
import 'package:sobilog/core/storage/app_preferences.dart';
import 'package:sobilog/features/analysis/presentation/pattern_report_screen.dart';
import 'package:sobilog/features/category/data/category_service.dart';
import 'package:sobilog/features/profile/presentation/account_settings_screen.dart';
import 'package:sobilog/features/profile/presentation/attendance_screen.dart';
import 'package:sobilog/features/profile/presentation/notification_settings_screen.dart';
import 'package:sobilog/features/profile/presentation/profile_screen.dart';

import 'p2_fake_service.dart';
import 'p2_harness.dart';

final _today = DateTime(2026, 8, 16);

List<Map<String, dynamic>> _calendar({
  List<int> recorded = const [],
  List<int> noSpend = const [],
}) => [
  for (final d in recorded)
    {'date': '2026-08-${d.toString().padLeft(2, '0')}', 'status': 'recorded'},
  for (final d in noSpend)
    {'date': '2026-08-${d.toString().padLeft(2, '0')}', 'status': 'no_spend'},
];

const _progressRecorded = [1, 2, 3, 6, 7, 9, 11, 13, 14, 15];
const _progressNoSpend = [4, 5, 8, 10, 12];

Future<void> _showAttendance(
  WidgetTester tester,
  FakeP2Service service, {
  double height = 1308,
  DateTime? today,
}) => showScreen(
  tester,
  AttendanceScreen(
    financeService: service,
    today: today ?? _today,
    initialMonth: DateTime(2026, 8),
  ),
  size: Size(402, height),
);

void main() {
  setUpAll(loadAppFonts);
  setUp(CategoryStore.instance.reset);

  group('마이_001·005 메뉴 / 계정 설정', () {
    testWidgets('마이페이지 메뉴: 출석 현황 · 알림 설정 · 계정 설정 · 고객 센터', (tester) async {
      final service = FakeP2Service();
      await showScreen(tester, ProfileScreen(financeService: service));
      for (final label in ['출석 현황', '알림 설정', '계정 설정', '고객 센터']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('리워드 관리'), findsNothing);
      await capture(tester, '마이_001-01_마이페이지 메인');
    });

    testWidgets('마이_005-01 동의한 사용자: 철회 메뉴 → 분석_007-04 → 철회', (tester) async {
      final service = FakeP2Service()
        ..savingHintData = savingStatus(remaining: 1, agreed: true);
      await showScreen(
        tester,
        AccountSettingsScreen(provider: 'apple', financeService: service),
      );
      expect(find.text('할인 찾기 정보 제공 동의 철회'), findsOneWidget);
      await capture(tester, '마이_005-01_계정 설정 [Apple]');

      await tester.tap(find.byKey(const Key('account-consent-withdraw')));
      await tester.pumpAndSettle();
      expect(find.text('할인 찾기 정보 제공 동의를 철회할까요?'), findsOneWidget);
      expect(find.text('이미 보낸 정보는 Google에서 최대 55일 보관 후 삭제돼요'), findsOneWidget);
      await capture(tester, '분석_007-04_동의 철회 팝업');

      await tester.tap(find.text('철회하기'));
      await tester.pumpAndSettle();
      expect(service.calls, contains('DELETE /analysis/saving-hint/consent'));
      expect(find.text('할인 찾기 정보 제공 동의 철회'), findsNothing);
    });

    testWidgets('마이_005-01 동의 안 한 사용자 / 조회 실패: 철회 메뉴 숨김', (tester) async {
      final service = FakeP2Service();
      await showScreen(
        tester,
        AccountSettingsScreen(provider: 'email', financeService: service),
      );
      expect(find.text('할인 찾기 정보 제공 동의 철회'), findsNothing);
      expect(find.text('비밀번호 변경'), findsOneWidget);
    });
  });

  group('마이_002·003 출석 현황 / 리워드', () {
    testWidgets('마이_002-01 처음', (tester) async {
      final service = FakeP2Service()..today = _today;
      await _showAttendance(tester, service, height: 1253);
      expect(find.text('첫 기록을 남겨볼까요?'), findsOneWidget);
      expect(find.text('오늘 기록하면 1일째 연속 기록이에요'), findsOneWidget);
      expect(
        find.text('7일 연속 기록하면 소비 패턴 리포트 잠금이 풀려요\n20일 기록하면 반복 지출 분석 잠금이 풀려요'),
        findsOneWidget,
      );
      expect(find.text('0일 / 31일'), findsOneWidget);
      await capture(tester, '마이_002-01_출석 현황 [처음]');
    });

    testWidgets('마이_002-01 진행 중 + 월 이동 (▶ 비활성)', (tester) async {
      final service = FakeP2Service()
        ..today = _today
        ..rewardsData = rewardsFor(streak: 15, month: 15)
        ..attendanceData = attendanceFor(
          current: 15,
          max: 15,
          recorded: 15,
          noSpend: 5,
          calendar: _calendar(
            recorded: _progressRecorded,
            noSpend: _progressNoSpend,
          ),
        );
      await _showAttendance(tester, service);
      expect(find.text('소비 패턴 리포트 열림'), findsOneWidget);
      expect(find.text('5일만 더 기록하면 반복 지출 분석 잠금이 풀려요'), findsOneWidget);
      expect(find.text('오늘 아직 기록이 없어요'), findsOneWidget);
      expect(find.text('오늘 기록하면 16일째 연속 기록이에요'), findsOneWidget);
      expect(
        find.byKey(const Key('attendance-day-4-no-spend')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('attendance-day-1-recorded')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('attendance-today-dot')), findsOneWidget);
      await capture(tester, '마이_002-01_출석 현황 [진행 중]');

      final before = service.calls.length;
      await tapAndSettle(
        tester,
        find.byKey(const Key('attendance-next-month')),
      );
      expect(service.calls.length, before);
      await tapAndSettle(
        tester,
        find.byKey(const Key('attendance-prev-month')),
      );
      expect(service.calls, contains('GET /mypage/attendance?month=2026-7'));
      expect(find.text('7월 기록일'), findsOneWidget);

      await tapAndSettle(
        tester,
        find.byKey(const Key('attendance-open-streak_7')),
      );
      expect(find.byType(PatternReportScreen), findsOneWidget);
    });

    testWidgets('마이_002-01 반복 지출 분석 열림 (오늘 기록함 → 배너 숨김)', (tester) async {
      final today = DateTime(2026, 8, 20);
      final service = FakeP2Service()
        ..today = today
        ..rewardsData = rewardsFor(streak: 20, month: 20)
        ..attendanceData = attendanceFor(
          current: 20,
          max: 20,
          recorded: 20,
          noSpend: 5,
          calendar: _calendar(
            recorded: [..._progressRecorded, 16, 17, 18, 19, 20],
            noSpend: _progressNoSpend,
          ),
        );
      await _showAttendance(tester, service, today: today);
      expect(find.text('반복 지출 분석 열림'), findsOneWidget);
      expect(find.text('오늘 아직 기록이 없어요'), findsNothing);
      expect(find.byKey(const Key('attendance-reward-hint')), findsNothing);
      await capture(tester, '마이_002-01_출석 현황 [반복 지출 분석 열림]');
    });

    testWidgets('마이_002-02 무지출 기록 → [무지출 기록 완료] + 토스트', (tester) async {
      final service = FakeP2Service()
        ..today = _today
        ..rewardsData = rewardsFor(streak: 15, month: 15)
        ..attendanceData = attendanceFor(
          current: 15,
          max: 15,
          recorded: 15,
          noSpend: 5,
          calendar: _calendar(
            recorded: _progressRecorded,
            noSpend: _progressNoSpend,
          ),
        );
      await _showAttendance(tester, service, height: 874);
      await tapAndSettle(tester, find.byKey(const Key('attendance-no-spend')));
      expect(find.text('오늘 지출이 없었나요?'), findsOneWidget);
      await capture(tester, '마이_002-02_무지출 기록 팝업');

      await tester.tap(find.byKey(const Key('center-confirm-ok')));
      await tester.pumpAndSettle();
      expect(service.calls, contains('POST /mypage/attendance/no-spend-day'));
      expect(find.text('오늘을 무지출로 기록했어요'), findsOneWidget);
      expect(find.text('오늘 아직 기록이 없어요'), findsNothing);
      expect(
        find.byKey(const Key('attendance-day-16-no-spend')),
        findsOneWidget,
      );
      await capture(tester, '마이_002-01_출석 현황 [무지출 기록 완료]');
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('마이_002-02 E408 → 다시 조회 (배너 사라짐)', (tester) async {
      final service = FakeP2Service()
        ..today = _today
        ..noSpendError = const ApiException(
          statusCode: 400,
          code: 'E408',
          message: '이미 기록',
        );
      await _showAttendance(tester, service);
      service.attendanceData = attendanceFor(
        current: 1,
        max: 1,
        recorded: 1,
        calendar: _calendar(recorded: [16]),
      );
      await tapAndSettle(tester, find.byKey(const Key('attendance-no-spend')));
      await tester.tap(find.byKey(const Key('center-confirm-ok')));
      await tester.pumpAndSettle();
      expect(find.text('첫 기록을 남겨볼까요?'), findsNothing);
      expect(find.text('오늘 아직 기록이 없어요'), findsNothing);
    });

    testWidgets('마이_003-01 → 003-02 순서, 확인 처리는 한 번', (tester) async {
      final service = FakeP2Service()
        ..today = _today
        ..rewardsData = rewardsFor(
          streak: 7,
          month: 20,
          streakNew: true,
          monthNew: true,
        );
      await _showAttendance(tester, service, height: 854);
      expect(find.text('7일 연속 기록 달성!'), findsOneWidget);
      await capture(tester, '마이_003-01_연속 7일 달성 팝업');
      await tester.tap(find.byKey(const Key('reward-popup-close')));
      await tester.pumpAndSettle();
      expect(find.text('이번 달 20일 기록 달성!'), findsOneWidget);
      expect(service.rewardsSeenCount, 0);
      await capture(tester, '마이_003-02_이번 달 20일 달성 팝업');
      await tester.tap(find.byKey(const Key('reward-popup-close')));
      await tester.pumpAndSettle();
      expect(service.rewardsSeenCount, 1);
    });

    testWidgets('마이_003-01 [보러 가기] → 소비 패턴 리포트', (tester) async {
      final service = FakeP2Service()
        ..today = _today
        ..rewardsData = rewardsFor(streak: 7, month: 0, streakNew: true);
      await _showAttendance(tester, service);
      await tester.tap(find.byKey(const Key('reward-popup-open')));
      await tester.pumpAndSettle();
      expect(find.byType(PatternReportScreen), findsOneWidget);
      expect(service.rewardsSeenCount, 1);
    });
  });

  group('마이_004 알림 설정', () {
    Future<(FakeP2Service, FakeLocalNotificationService, MemoryAppPreferences)>
    open(
      WidgetTester tester, {
      bool reminder = false,
      bool ai = false,
      NotificationPermission permission = NotificationPermission.granted,
      bool allow = true,
    }) async {
      final service = FakeP2Service()
        ..notificationData = {
          'push_enabled': true,
          'reminder_enabled': reminder,
          'reminder_time': '21:00',
        };
      final local = FakeLocalNotificationService(
        current: permission,
        allowOnRequest: allow,
      );
      final prefs = MemoryAppPreferences(
        aiAlert: ai,
        permissionAsked: permission != NotificationPermission.notDetermined,
      );
      await showScreen(
        tester,
        NotificationSettingsScreen(
          financeService: service,
          notifications: local,
          preferences: prefs,
        ),
      );
      return (service, local, prefs);
    }

    testWidgets('[전체 꺼짐] → 리마인더 켜기 → [전체 켜짐] + 토스트', (tester) async {
      final (service, local, prefs) = await open(tester);
      await capture(tester, '마이_004-01_알림 설정 [전체 꺼짐]');
      await tester.tap(find.byKey(const Key('noti-reminder')));
      await tester.pumpAndSettle();
      expect(service.notificationUpdates.last, {
        'push_enabled': true,
        'reminder_enabled': true,
      });
      expect(local.reminder, const TimeOfDay(hour: 21, minute: 0));
      expect(find.text('알림을 켰어요'), findsOneWidget);
      await tester.tap(find.byKey(const Key('noti-ai')));
      await tester.pumpAndSettle();
      expect(prefs.aiAlert, isTrue);
      expect(local.aiScheduled, isTrue);
      await capture(tester, '마이_004-01_알림 설정 [전체 켜짐]');
      await tester.pump(const Duration(seconds: 3));

      await tester.tap(find.byKey(const Key('noti-reminder')));
      await tester.pumpAndSettle();
      expect(local.reminder, isNull);
      expect(service.notificationUpdates.last['reminder_enabled'], false);
    });

    testWidgets('권한 아직 안 물어봄 → 허용 안 함 → [휴대폰 알림 꺼짐]', (tester) async {
      final (service, local, _) = await open(
        tester,
        reminder: true,
        ai: true,
        permission: NotificationPermission.notDetermined,
        allow: false,
      );
      await tester.tap(find.byKey(const Key('noti-ai')));
      await tester.pumpAndSettle();
      // 켜진 스위치를 끄는 것은 권한 요청 없이 저장
      expect(local.permissionRequests, 0);
      await tester.tap(find.byKey(const Key('noti-ai')));
      await tester.pumpAndSettle();
      expect(local.permissionRequests, 1);
      expect(find.text('휴대폰 알림이 꺼져 있어요'), findsOneWidget);
      await capture(tester, '마이_004-01_알림 설정 [휴대폰 알림 꺼짐]');
      final updates = service.notificationUpdates.length;
      await tester.tap(
        find.byKey(const Key('noti-reminder')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(service.notificationUpdates.length, updates);
      await tester.tap(find.byKey(const Key('noti-open-settings')));
      expect(local.settingsOpened, 1);
    });

    testWidgets('마이_004-02 시간 시트 → 저장 → 토스트', (tester) async {
      final (service, local, _) = await open(tester, reminder: true, ai: true);
      await tester.tap(find.byKey(const Key('noti-reminder-time')));
      await tester.pumpAndSettle();
      expect(find.text('기록 리마인더 시간'), findsOneWidget);
      await capture(tester, '마이_004-02_기록 리마인더 시간 시트');
      await tester.drag(
        find.byKey(const Key('reminder-minute-wheel')),
        const Offset(0, -39 * 2),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reminder-save')));
      await tester.pumpAndSettle();
      expect(service.notificationUpdates.last['reminder_time'], '21:10');
      expect(local.reminder, const TimeOfDay(hour: 21, minute: 10));
      expect(find.text('매일 21:10에 알려드릴게요'), findsOneWidget);
      await capture(tester, '마이_004-01_알림 설정 [리마인더 저장 토스트]');
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('AI 분석 알림은 서버(ai_report_alert_enabled)에 저장하고 서버 값을 우선한다', (
      tester,
    ) async {
      final service = FakeP2Service()
        ..notificationData = {
          'push_enabled': true,
          'reminder_enabled': false,
          'reminder_time': '21:00',
          'ai_report_alert_enabled': false,
        };
      final local = FakeLocalNotificationService();
      final prefs = MemoryAppPreferences(aiAlert: true, permissionAsked: true);
      await showScreen(
        tester,
        NotificationSettingsScreen(
          financeService: service,
          notifications: local,
          preferences: prefs,
        ),
      );
      // 기기 값(켜짐)보다 서버 값(꺼짐)을 따른다.
      expect(
        tester
            .widget<P2Switch>(
              find.descendant(
                of: find.byKey(const Key('noti-ai')),
                matching: find.byType(P2Switch),
              ),
            )
            .value,
        isFalse,
      );
      expect(local.aiScheduled, isFalse);
      await tester.tap(find.byKey(const Key('noti-ai')));
      await tester.pumpAndSettle();
      expect(service.notificationUpdates.last, {
        'push_enabled': true,
        'ai_report_alert_enabled': true,
      });
      expect(local.aiScheduled, isTrue);
      expect(prefs.aiAlert, isTrue);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets(
      '전체 알림(push_enabled) 꺼짐 → 예약 전부 취소, 하나를 켜면 나머지는 화면 값(꺼짐)으로 함께 저장',
      (tester) async {
        final service = FakeP2Service()
          ..notificationData = {
            'push_enabled': false,
            'reminder_enabled': true,
            'reminder_time': '21:00',
            'ai_report_alert_enabled': true,
          };
        final local = FakeLocalNotificationService()
          ..reminder = const TimeOfDay(hour: 21, minute: 0)
          ..aiScheduled = true;
        await showScreen(
          tester,
          NotificationSettingsScreen(
            financeService: service,
            notifications: local,
            preferences: MemoryAppPreferences(permissionAsked: true),
          ),
        );
        expect(local.cancelAllCount, 1);
        expect(local.reminder, isNull);
        expect(local.aiScheduled, isFalse);
        bool switchOf(String key) => tester
            .widget<P2Switch>(
              find.descendant(
                of: find.byKey(Key(key)),
                matching: find.byType(P2Switch),
              ),
            )
            .value;
        expect(switchOf('noti-reminder'), isFalse);
        expect(switchOf('noti-ai'), isFalse);

        await tester.tap(find.byKey(const Key('noti-reminder')));
        await tester.pumpAndSettle();
        expect(service.notificationUpdates.last, {
          'push_enabled': true,
          'reminder_enabled': true,
          'ai_report_alert_enabled': false,
        });
        // 사용자가 켜지 않은 AI 알림은 켜지지 않는다.
        expect(local.reminder, const TimeOfDay(hour: 21, minute: 0));
        expect(local.aiScheduled, isFalse);
        expect(switchOf('noti-ai'), isFalse);
        await tester.pump(const Duration(seconds: 3));

        // 전체 알림이 켜진 뒤에는 해당 항목만 보낸다.
        await tester.tap(find.byKey(const Key('noti-ai')));
        await tester.pumpAndSettle();
        expect(service.notificationUpdates.last, {
          'push_enabled': true,
          'ai_report_alert_enabled': true,
        });
        expect(local.aiScheduled, isTrue);
        await tester.pump(const Duration(seconds: 3));
      },
    );

    testWidgets('저장 실패 → 원래대로 + 안내', (tester) async {
      final service = FakeP2Service()..failNotificationUpdate = true;
      final local = FakeLocalNotificationService();
      await showScreen(
        tester,
        NotificationSettingsScreen(
          financeService: service,
          notifications: local,
          preferences: MemoryAppPreferences(permissionAsked: true),
        ),
      );
      await tester.tap(find.byKey(const Key('noti-reminder')));
      await tester.pumpAndSettle();
      expect(find.text('저장하지 못했어요. 다시 시도해 주세요'), findsOneWidget);
      expect(local.reminder, isNull);
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
