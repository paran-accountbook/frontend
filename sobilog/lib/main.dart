import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/config/app_config.dart';
import 'core/logging/app_logger.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/terms_screen.dart';
import 'features/auth/presentation/verification_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/ledger/presentation/ledger_screen.dart';
import 'features/splash/presentation/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await dotenv.load(fileName: '.env.example');

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
      title: 'Sobilog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: switch (_preview) {
        'login' => const LoginScreen(),
        'verification' => const VerificationScreen(),
        'terms' => const TermsScreen(),
        'home' => const HomeScreen(),
        'ledger' => const LedgerScreen(),
        _ => const SplashScreen(),
      },
    );
  }
}
