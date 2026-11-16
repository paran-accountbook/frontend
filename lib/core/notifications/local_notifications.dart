import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

/// iOS 알림 권한 상태.
enum NotificationPermission { granted, denied, notDetermined }

/// 알림을 눌렀을 때 열 화면.
enum NotificationTarget { register, aiAnalysis }

/// 참고_잠금화면 로컬 알림 예시 (Figma 2086-50709) 문구. 앱 이름(소비로그)은 iOS가 붙인다.
abstract final class NotificationTemplates {
  static const reminderTitle = '오늘 소비, 기록하셨나요?';
  static const reminderBody = '잊기 전에 오늘 소비를 남겨 보세요';
  static const aiTitle = '이달의 AI 분석이 준비됐어요';
  static const aiBody = '소비 습관 진단과 할인 찾기를 1회씩 받을 수 있어요';
}

/// 마이_004: 로컬 알림 (서버 푸시 없음).
/// - 기록 리마인더: 매일 reminder_time (그날 기록했어도 발송)
/// - 이달의 AI 분석 알림: 매달 1일 12:00 고정
abstract interface class LocalNotificationService {
  Future<void> initialize();
  Future<NotificationPermission> permission({required bool asked});
  Future<bool> requestPermission();
  Future<void> scheduleDailyReminder(TimeOfDay time);
  Future<void> cancelDailyReminder();
  Future<void> scheduleMonthlyAiAlert();
  Future<void> cancelMonthlyAiAlert();

  /// 예약된 알림 전부 취소 (전체 알림 끔·로그아웃·탈퇴).
  Future<void> cancelAll();
  Future<void> openSystemSettings();
}

class PluginLocalNotificationService implements LocalNotificationService {
  PluginLocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const reminderId = 4001;
  static const aiAlertId = 4002;
  static const reminderPayload = 'reminder';
  static const aiPayload = 'ai_analysis';

  /// 알림을 눌러 앱이 열렸을 때 보여줄 화면(앱 시작 시 스플래시가 소비).
  static NotificationTarget? pendingTarget;

  /// 앱 실행 중 알림을 누른 경우 호출된다.
  static final ValueNotifier<NotificationTarget?> tapped = ValueNotifier(null);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _details = NotificationDetails(
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
    ),
    android: AndroidNotificationDetails(
      'sobilog_local',
      '소비로그 알림',
      importance: Importance.defaultImportance,
    ),
  );

  static NotificationTarget? _targetFor(String? payload) => switch (payload) {
    reminderPayload => NotificationTarget.register,
    aiPayload => NotificationTarget.aiAnalysis,
    _ => null,
  };

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    await _plugin.initialize(
      settings: const InitializationSettings(
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        tapped.value = _targetFor(response.payload);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      pendingTarget = _targetFor(launch?.notificationResponse?.payload);
    }
  }

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<NotificationPermission> permission({required bool asked}) async {
    await initialize();
    final options = await _ios?.checkPermissions();
    if (options?.isEnabled ?? false) return NotificationPermission.granted;
    return asked
        ? NotificationPermission.denied
        : NotificationPermission.notDetermined;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    return await _ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  tz.TZDateTime _nextDaily(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextMonthFirstNoon() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, 1, 12);
    if (!scheduled.isAfter(now)) {
      scheduled = tz.TZDateTime(tz.local, now.year, now.month + 1, 1, 12);
    }
    return scheduled;
  }

  @override
  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await initialize();
    await _plugin.cancel(id: reminderId);
    await _plugin.zonedSchedule(
      id: reminderId,
      title: NotificationTemplates.reminderTitle,
      body: NotificationTemplates.reminderBody,
      scheduledDate: _nextDaily(time),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: reminderPayload,
    );
  }

  @override
  Future<void> cancelDailyReminder() async {
    await initialize();
    await _plugin.cancel(id: reminderId);
  }

  @override
  Future<void> scheduleMonthlyAiAlert() async {
    await initialize();
    await _plugin.cancel(id: aiAlertId);
    await _plugin.zonedSchedule(
      id: aiAlertId,
      title: NotificationTemplates.aiTitle,
      body: NotificationTemplates.aiBody,
      scheduledDate: _nextMonthFirstNoon(),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      payload: aiPayload,
    );
  }

  @override
  Future<void> cancelMonthlyAiAlert() async {
    await initialize();
    await _plugin.cancel(id: aiAlertId);
  }

  @override
  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  @override
  Future<void> openSystemSettings() async {
    // iOS: 설정 앱의 소비로그 화면(알림 항목 포함)으로 이동.
    await launchUrl(Uri.parse('app-settings:'));
  }
}

/// 테스트·미리보기용 알림 서비스.
class FakeLocalNotificationService implements LocalNotificationService {
  FakeLocalNotificationService({
    this.current = NotificationPermission.granted,
    this.allowOnRequest = true,
  });

  NotificationPermission current;
  bool allowOnRequest;
  TimeOfDay? reminder;
  bool aiScheduled = false;
  int permissionRequests = 0;
  int settingsOpened = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<NotificationPermission> permission({required bool asked}) async =>
      current;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    current = allowOnRequest
        ? NotificationPermission.granted
        : NotificationPermission.denied;
    return allowOnRequest;
  }

  @override
  Future<void> scheduleDailyReminder(TimeOfDay time) async => reminder = time;
  @override
  Future<void> cancelDailyReminder() async => reminder = null;
  @override
  Future<void> scheduleMonthlyAiAlert() async => aiScheduled = true;
  @override
  Future<void> cancelMonthlyAiAlert() async => aiScheduled = false;
  int cancelAllCount = 0;
  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
    reminder = null;
    aiScheduled = false;
  }

  @override
  Future<void> openSystemSettings() async => settingsOpened++;
}
