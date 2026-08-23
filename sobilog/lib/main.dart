import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/config/app_config.dart';
import 'core/logging/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  AppLogger.info(
    'Sobilog started | env=${AppConfig.environment} | api=${AppConfig.apiBaseUrl}',
  );

  runApp(const SobilogApp());
}

class SobilogApp extends StatelessWidget {
  const SobilogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sobilog',
      debugShowCheckedModeBanner: AppConfig.isDevelopment,
      home: const Scaffold(
        body: Center(child: Text('Sobilog')),
      ),
    );
  }
}
