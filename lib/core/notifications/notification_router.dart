import 'dart:io';

import 'package:flutter/material.dart';

import '../../features/analysis/presentation/analysis_overview_screen.dart';
import '../../features/finance/data/finance_service.dart';
import '../../features/register/presentation/register_type_screen.dart';
import '../network/app_services.dart';
import 'local_notifications.dart';
import 'notification_sync.dart';

/// 앱 전체 네비게이터 (알림 탭으로 화면을 열 때 사용).
final appNavigatorKey = GlobalKey<NavigatorState>();

/// 마이_004: 알림 탭 → 기록 리마인더는 소비 등록 탭, AI 분석 알림은 분석_008-01.
Widget notificationTargetScreen(NotificationTarget target) => switch (target) {
  NotificationTarget.register => RegisterTypeScreen(
    financeService: AppServices.finance,
  ),
  NotificationTarget.aiAnalysis => AnalysisOverviewScreen(
    financeService: AppServices.finance,
    initialTab: AnalysisTab.ai,
  ),
};

void openNotificationTarget(NotificationTarget target) {
  appNavigatorKey.currentState?.push(
    MaterialPageRoute<void>(builder: (_) => notificationTargetScreen(target)),
  );
}

/// 앱이 알림으로 열렸다면 그 화면을 연다 (홈으로 들어간 직후 한 번).
void consumePendingNotificationTarget() {
  final target = PluginLocalNotificationService.pendingTarget;
  if (target == null) return;
  PluginLocalNotificationService.pendingTarget = null;
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => openNotificationTarget(target),
  );
}

/// 앱 실행·로그인 후 한 번: 서버 알림 설정으로 로컬 알림을 다시 예약한다.
class NotificationSync {
  static bool _done = false;

  static Future<void> run(FinanceService? service) async {
    if (_done || service == null) return;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    _done = true;
    final settings = await resyncNotifications(
      service,
      notifications: AppServices.notifications,
      preferences: AppServices.preferences,
    );
    if (settings == null) _done = false;
  }

  /// 로그아웃 후 다른 계정으로 들어오면 다시 예약하도록 초기화.
  static void reset() => _done = false;
}
