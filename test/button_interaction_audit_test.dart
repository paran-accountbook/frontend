import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/auth/data/auth_service.dart';
import 'package:sobilog/features/auth/presentation/verification_screen.dart';
import 'package:sobilog/features/analysis/presentation/analysis_overview_screen.dart';
import 'package:sobilog/features/home/presentation/home_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_screen.dart';
import 'package:sobilog/features/profile/presentation/account_settings_screen.dart';
import 'package:sobilog/features/profile/presentation/attendance_screen.dart';
import 'package:sobilog/features/profile/presentation/notification_settings_screen.dart';
import 'package:sobilog/features/profile/presentation/profile_edit_screen.dart';
import 'package:sobilog/features/profile/presentation/profile_screen.dart';
import 'package:sobilog/features/profile/presentation/reward_screen.dart';
import 'package:sobilog/features/register/presentation/register_type_screen.dart';
import 'package:sobilog/shared/widgets/app_bottom_navigation.dart';
import 'package:sobilog/shared/widgets/app_chevron.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark, home: screen));
    await tester.pump();
  }

  final auditedScreens = <String, Widget>{
    '알림 설정': const NotificationSettingsScreen(),
    '출석 현황': AttendanceScreen(
      today: DateTime(2026, 10, 2),
      initialData: const <String, dynamic>{},
    ),
    '보상함': const RewardScreen(),
    '프로필 수정': const ProfileEditScreen(),
  };
  final destinations = <int, Type>{
    0: HomeScreen,
    1: LedgerScreen,
    2: RegisterTypeScreen,
    3: AnalysisOverviewScreen,
    4: ProfileScreen,
  };

  for (final screen in auditedScreens.entries) {
    for (final destination in destinations.entries) {
      testWidgets('${screen.key} 하단 ${destination.key}번 버튼이 화면을 전환한다', (
        tester,
      ) async {
        await pumpScreen(tester, screen.value);

        final navigation = tester.widget<AppBottomNavigation>(
          find.byType(AppBottomNavigation),
        );
        expect(navigation.selectedIndex, 4);

        await tester.tap(
          find.byKey(ValueKey('bottom-navigation-item-${destination.key}')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(destination.value), findsOneWidget);
      });
    }
  }

  testWidgets('계정 설정 앱 버전은 동작하지 않는 화살표를 노출하지 않는다', (tester) async {
    await pumpScreen(tester, const AccountSettingsScreen());

    expect(find.byType(AppChevron), findsNWidgets(3));
    expect(find.text('앱버전'), findsOneWidget);
  });

  testWidgets('계정 설정 로그아웃 버튼은 전달받은 인증 서비스를 호출한다', (tester) async {
    final authService = _LogoutRecordingAuthService();
    await pumpScreen(tester, AccountSettingsScreen(authService: authService));

    await tester.tap(find.text('로그아웃').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그아웃').last);
    await tester.pumpAndSettle();

    expect(authService.logoutCalls, 1);
  });

  testWidgets('인증번호 재발송 대기 중 탭하면 남은 시간을 안내한다', (tester) async {
    await pumpScreen(tester, const VerificationScreen());

    await tester.tap(find.text('인증번호 재발송'));
    await tester.pump();

    expect(find.textContaining('초 후 다시 요청할 수 있어요.'), findsOneWidget);
  });
}

class _LogoutRecordingAuthService implements AuthService {
  int logoutCalls = 0;

  @override
  Future<void> logout() async {
    logoutCalls += 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
