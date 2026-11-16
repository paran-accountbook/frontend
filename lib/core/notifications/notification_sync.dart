import 'package:flutter/material.dart';

import '../../features/finance/data/finance_service.dart';
import '../storage/app_preferences.dart';
import 'local_notifications.dart';

/// 'HH:MM' → TimeOfDay (기본 21:00)
TimeOfDay parseReminderTime(String? value) {
  final parts = (value ?? '').split(':');
  final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
  if (hour == null || minute == null) {
    return const TimeOfDay(hour: 21, minute: 0);
  }
  return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
}

String formatReminderTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

/// 서버 알림 설정(GET/PATCH /mypage/notifications)을 읽기 쉽게 정리한 값.
/// 알림은 모두 앱 로컬 알림으로 보낸다 (서버 푸시 없음).
class NotificationSettings {
  const NotificationSettings({
    required this.pushEnabled,
    required this.reminderEnabled,
    required this.reminderTime,
    required this.aiReportEnabled,
  });

  /// [aiFallback]: 서버가 아직 ai_report_alert_enabled 를 내려주지 않을 때 쓰는 기기 저장값.
  factory NotificationSettings.fromJson(
    Map<String, dynamic> json, {
    bool aiFallback = true,
  }) => NotificationSettings(
    pushEnabled: json['push_enabled'] as bool? ?? true,
    reminderEnabled: json['reminder_enabled'] as bool? ?? false,
    reminderTime: parseReminderTime(json['reminder_time'] as String?),
    aiReportEnabled: json['ai_report_alert_enabled'] as bool? ?? aiFallback,
  );

  final bool pushEnabled;
  final bool reminderEnabled;
  final TimeOfDay reminderTime;
  final bool aiReportEnabled;

  bool get reminderActive => pushEnabled && reminderEnabled;
  bool get aiActive => pushEnabled && aiReportEnabled;
}

/// 설정에 맞춰 로컬 알림을 예약·취소한다.
/// - 전체 알림(push_enabled)이 꺼져 있거나 휴대폰 알림 권한이 없으면 전부 취소
/// - 기록 리마인더: 매일 reminder_time / 이달의 AI 분석 알림: 매월 1일 12:00
Future<void> applyNotificationSettings(
  NotificationSettings settings, {
  required LocalNotificationService notifications,
  required AppPreferences preferences,
}) async {
  final asked = await preferences.notificationPermissionAsked();
  final permission = await notifications.permission(asked: asked);
  if (!settings.pushEnabled || permission != NotificationPermission.granted) {
    await notifications.cancelAll();
    return;
  }
  if (settings.reminderEnabled) {
    await notifications.scheduleDailyReminder(settings.reminderTime);
  } else {
    await notifications.cancelDailyReminder();
  }
  if (settings.aiReportEnabled) {
    await notifications.scheduleMonthlyAiAlert();
  } else {
    await notifications.cancelMonthlyAiAlert();
  }
}

/// 앱 실행·로그인 후: 서버 값으로 알림을 다시 예약한다 (기기를 바꿔도 유지).
Future<NotificationSettings?> resyncNotifications(
  FinanceService service, {
  required LocalNotificationService notifications,
  required AppPreferences preferences,
}) async {
  try {
    final json = await service.notificationSettings();
    final settings = NotificationSettings.fromJson(
      json,
      aiFallback: await preferences.aiAlertEnabled(),
    );
    await preferences.setAiAlertEnabled(settings.aiReportEnabled);
    await applyNotificationSettings(
      settings,
      notifications: notifications,
      preferences: preferences,
    );
    return settings;
  } catch (_) {
    // 알림 예약 실패는 앱 사용을 막지 않는다.
    return null;
  }
}

/// 로그아웃·탈퇴: 예약된 알림을 전부 취소한다.
Future<void> cancelNotificationsOnSignOut(
  LocalNotificationService notifications,
) async {
  try {
    await notifications.cancelAll();
  } catch (_) {
    // 플러그인을 쓸 수 없는 환경에서도 로그아웃은 계속한다.
  }
}
