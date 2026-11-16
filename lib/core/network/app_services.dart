import '../../features/auth/data/auth_service.dart';
import '../../features/auth/data/apple_login_client.dart';
import '../../features/auth/data/kakao_login_client.dart';
import '../../features/dutch/data/dutch_pay_service.dart';
import '../../features/finance/data/finance_service.dart';
import '../notifications/local_notifications.dart';
import '../notifications/notification_router.dart' show NotificationSync;
import '../notifications/notification_sync.dart';
import '../storage/app_preferences.dart';
import 'api_client.dart';

abstract final class AppServices {
  static final ApiClient client = ApiClient();
  static final AuthService auth = AuthApiService(
    client,
    onSignedOut: () async {
      NotificationSync.reset();
      await cancelNotificationsOnSignOut(notifications);
    },
  );
  static const KakaoLoginClient kakaoLogin = KakaoSdkLoginClient();
  static const AppleLoginClient appleLogin = AppleSdkLoginClient();
  static final FinanceService finance = FinanceApiService(client);
  static final DutchPayService dutchPay = DutchPayApiService(client);
  static AppPreferences preferences = const SharedAppPreferences();
  static LocalNotificationService notifications =
      PluginLocalNotificationService();
}
