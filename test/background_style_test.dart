import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/theme/app_colors.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/auth/presentation/login_screen.dart';
import 'package:sobilog/features/home/presentation/home_screen.dart';
import 'package:sobilog/features/splash/presentation/splash_screen.dart';

void main() {
  test('screen background uses the Figma black token', () {
    expect(AppColors.background, const Color(0xFF121215));
    expect(AppColors.surface, const Color(0xFF121215));
    expect(AppTheme.dark.scaffoldBackgroundColor, const Color(0xFF121215));
    expect(AppTheme.dark.colorScheme.surface, const Color(0xFF121215));
  });

  testWidgets('login shows the requested version label', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const LoginScreen()),
    );

    expect(find.text('Ver 1.0'), findsOneWidget);
  });

  for (final screen in <({String name, Widget widget})>[
    (name: 'splash', widget: const SplashScreen(autoAdvance: false)),
    (name: 'login', widget: const LoginScreen()),
    (name: 'home', widget: const HomeScreen()),
  ]) {
    testWidgets('${screen.name} has no decorative raster background', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(402, 874);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark, home: screen.widget),
      );

      expect(
        tester
            .widgetList<Image>(find.byType(Image))
            .map((image) => image.image)
            .whereType<AssetImage>(),
        isEmpty,
      );
    });
  }
}
