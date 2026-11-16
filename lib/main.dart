import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'core/config/app_config.dart';
import 'core/logging/app_logger.dart';
import 'core/network/app_services.dart';
import 'core/notifications/local_notifications.dart';
import 'core/notifications/notification_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/terms_screen.dart';
import 'features/auth/presentation/verification_screen.dart';
import 'features/analysis/presentation/analysis_overview_screen.dart';
import 'features/analysis/presentation/analysis_detail_screen.dart';
import 'features/analysis/presentation/analysis_goal_screen.dart';
import 'features/dutch/presentation/dutch_people_screen.dart';
import 'features/dutch/presentation/dutch_assignment_screen.dart';
import 'features/dutch/presentation/dutch_result_screen.dart';
import 'features/dutch/presentation/dutch_request_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/ledger/presentation/ledger_screen.dart';
import 'features/ledger/presentation/ledger_detail_screen.dart';
import 'features/ledger/presentation/ledger_edit_screen.dart';
import 'features/register/presentation/register_type_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/register/presentation/register_method_screen.dart';
import 'features/register/presentation/register_direct_screen.dart';
import 'features/register/presentation/register_income_screen.dart';
import 'features/splash/presentation/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await dotenv.load(fileName: '.env');
  if (AppConfig.kakaoNativeAppKey.isNotEmpty) {
    KakaoSdk.init(nativeAppKey: AppConfig.kakaoNativeAppKey);
  }

  try {
    await AppServices.notifications.initialize();
  } catch (error) {
    AppLogger.info('Local notifications unavailable: $error');
  }
  PluginLocalNotificationService.tapped.addListener(() {
    final target = PluginLocalNotificationService.tapped.value;
    if (target == null) return;
    PluginLocalNotificationService.tapped.value = null;
    openNotificationTarget(target);
  });

  AppLogger.info(
    'Sobilog started | env=${AppConfig.environment} | api=${AppConfig.apiBaseUrl}',
  );

  runApp(const SobilogApp());
}

class SobilogApp extends StatelessWidget {
  const SobilogApp({super.key});

  static const String _preview = String.fromEnvironment('SOBILOG_PREVIEW');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Sobilog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: switch (_preview) {
        'login' => const LoginScreen(),
        'verification' => const VerificationScreen(),
        'terms' => const TermsScreen(),
        'analysis-overview' => const AnalysisOverviewScreen(),
        'analysis-detail' => const AnalysisDetailScreen(),
        'analysis-goal' => const AnalysisGoalScreen(),
        'profile' => const ProfileScreen(),
        'home' => const HomeScreen(),
        'ledger' => const LedgerScreen(),
        'ledger-detail' => const LedgerDetailScreen(),
        'ledger-edit' => const LedgerEditScreen(),
        'register-type' => const RegisterTypeScreen(),
        'register-method' => const RegisterMethodScreen(),
        'register-direct' => const RegisterDirectScreen(),
        'register-income' => const RegisterIncomeScreen(),
        'dutch-people' => const DutchPeopleScreen(),
        'dutch-assignment' => const DutchAssignmentScreen(),
        'dutch-result' => const DutchResultScreen(),
        'dutch-request' => const DutchRequestScreen(),
        _ => const SplashScreen(),
      },
    );
  }
}
