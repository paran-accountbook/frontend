import 'package:shared_preferences/shared_preferences.dart';

/// 기기에만 저장하는 값 (서버 저장 안 함).
/// - 진입_002: 온보딩 완료 여부
/// - 마이_004: 이달의 AI 분석 알림 켜짐 여부(기본 켜짐), iOS 알림 권한을 물어본 적 있는지
abstract interface class AppPreferences {
  Future<bool> onboardingCompleted();
  Future<void> setOnboardingCompleted();
  Future<bool> aiAlertEnabled();
  Future<void> setAiAlertEnabled(bool value);
  Future<bool> notificationPermissionAsked();
  Future<void> setNotificationPermissionAsked();
}

class SharedAppPreferences implements AppPreferences {
  const SharedAppPreferences();

  static const _onboardingKey = 'sobilog_onboarding_completed';
  static const _aiAlertKey = 'sobilog_ai_alert_enabled';
  static const _permissionAskedKey = 'sobilog_notification_permission_asked';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<bool> onboardingCompleted() async =>
      (await _prefs).getBool(_onboardingKey) ?? false;

  @override
  Future<void> setOnboardingCompleted() async =>
      (await _prefs).setBool(_onboardingKey, true);

  @override
  Future<bool> aiAlertEnabled() async =>
      (await _prefs).getBool(_aiAlertKey) ?? true;

  @override
  Future<void> setAiAlertEnabled(bool value) async =>
      (await _prefs).setBool(_aiAlertKey, value);

  @override
  Future<bool> notificationPermissionAsked() async =>
      (await _prefs).getBool(_permissionAskedKey) ?? false;

  @override
  Future<void> setNotificationPermissionAsked() async =>
      (await _prefs).setBool(_permissionAskedKey, true);
}

/// 테스트·미리보기용 메모리 저장소.
class MemoryAppPreferences implements AppPreferences {
  MemoryAppPreferences({
    this.onboarding = false,
    this.aiAlert = true,
    this.permissionAsked = false,
  });

  bool onboarding;
  bool aiAlert;
  bool permissionAsked;

  @override
  Future<bool> onboardingCompleted() async => onboarding;
  @override
  Future<void> setOnboardingCompleted() async => onboarding = true;
  @override
  Future<bool> aiAlertEnabled() async => aiAlert;
  @override
  Future<void> setAiAlertEnabled(bool value) async => aiAlert = value;
  @override
  Future<bool> notificationPermissionAsked() async => permissionAsked;
  @override
  Future<void> setNotificationPermissionAsked() async => permissionAsked = true;
}
