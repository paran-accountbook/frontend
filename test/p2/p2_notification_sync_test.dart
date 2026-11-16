import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/network/api_client.dart';
import 'package:sobilog/core/network/session_store.dart';
import 'package:sobilog/core/notifications/local_notifications.dart';
import 'package:sobilog/core/notifications/notification_sync.dart';
import 'package:sobilog/core/storage/app_preferences.dart';
import 'package:sobilog/features/auth/data/auth_service.dart';

import 'p2_fake_service.dart';

void main() {
  test('알림 문구는 Figma 참고_잠금화면 로컬 알림 예시와 같다', () {
    expect(NotificationTemplates.reminderTitle, '오늘 소비, 기록하셨나요?');
    expect(NotificationTemplates.reminderBody, '잊기 전에 오늘 소비를 남겨 보세요');
    expect(NotificationTemplates.aiTitle, '이달의 AI 분석이 준비됐어요');
    expect(NotificationTemplates.aiBody, '소비 습관 진단과 할인 찾기를 1회씩 받을 수 있어요');
  });

  test('ai_report_alert_enabled 가 없으면 기기 저장값을 쓴다', () {
    final settings = NotificationSettings.fromJson({
      'push_enabled': true,
      'reminder_enabled': true,
      'reminder_time': '08:05',
    }, aiFallback: false);
    expect(settings.reminderTime, const TimeOfDay(hour: 8, minute: 5));
    expect(settings.aiReportEnabled, isFalse);
  });

  test('앱 실행·로그인: 서버 값으로 다시 예약', () async {
    final service = FakeP2Service()
      ..notificationData = {
        'push_enabled': true,
        'reminder_enabled': true,
        'reminder_time': '22:30',
        'ai_report_alert_enabled': true,
      };
    final local = FakeLocalNotificationService();
    final prefs = MemoryAppPreferences(aiAlert: false, permissionAsked: true);
    await resyncNotifications(
      service,
      notifications: local,
      preferences: prefs,
    );
    expect(local.reminder, const TimeOfDay(hour: 22, minute: 30));
    expect(local.aiScheduled, isTrue);
    expect(prefs.aiAlert, isTrue);
  });

  test('휴대폰 알림 권한이 없으면 아무것도 예약하지 않는다', () async {
    final service = FakeP2Service();
    final local = FakeLocalNotificationService(
      current: NotificationPermission.denied,
    );
    await resyncNotifications(
      service,
      notifications: local,
      preferences: MemoryAppPreferences(permissionAsked: true),
    );
    expect(local.reminder, isNull);
    expect(local.aiScheduled, isFalse);
    expect(local.cancelAllCount, 1);
  });

  test('로그아웃·탈퇴하면 예약된 알림을 전부 취소한다', () async {
    final local = FakeLocalNotificationService()
      ..reminder = const TimeOfDay(hour: 21, minute: 0)
      ..aiScheduled = true;
    final auth = AuthApiService(
      ApiClient(sessionStore: _MemorySessionStore()),
      onSignedOut: () => cancelNotificationsOnSignOut(local),
    );
    await auth.logout();
    expect(local.cancelAllCount, 1);
    expect(local.reminder, isNull);
    expect(local.aiScheduled, isFalse);
  });
}

class _MemorySessionStore implements SessionStore {
  String? _access;
  String? _refresh;

  @override
  Future<String?> readAccessToken() async => _access;
  @override
  Future<String?> readRefreshToken() async => _refresh;
  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    _access = accessToken;
    _refresh = refreshToken;
  }

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
  }
}
