import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/shared/widgets/p2_widgets.dart';

const captureRoot = Key('p2-capture-root');
const screenshotDir = String.fromEnvironment('P2_SCREENSHOTS');

Future<void> loadAppFonts() async {
  final pretendard = FontLoader('Pretendard')
    ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
    ..addFont(rootBundle.load('assets/fonts/Pretendard-Medium.otf'))
    ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'));
  final amarante = FontLoader('Amarante')
    ..addFont(rootBundle.load('assets/fonts/Amarante-Regular.ttf'));
  final brand = FontLoader('BujangnimNunchi')
    ..addFont(rootBundle.load('assets/fonts/BujangnimNunchi-Regular.ttf'));
  final material = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([
    pretendard.load(),
    amarante.load(),
    brand.load(),
    material.load(),
  ]);
}

Future<void> showScreen(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(402, 874),
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  addTearDown(dismissTopToast);
  await tester.pumpWidget(
    RepaintBoundary(
      key: captureRoot,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: screen,
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// 화면을 PNG로 저장한다. P2_SCREENSHOTS 가 비어 있으면 건너뛴다.
Future<void> capture(WidgetTester tester, String name) async {
  if (screenshotDir.isEmpty) return;
  await tester.pump(const Duration(milliseconds: 50));
  final images = find.byType(Image);
  final elements = images.evaluate().toList();
  if (elements.isNotEmpty) {
    await tester.runAsync(
      () => Future.wait([
        for (final element in elements)
          precacheImage((element.widget as Image).image, element),
      ]),
    );
    await tester.pump();
  }
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(captureRoot),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    final file = File('$screenshotDir/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png.buffer.asUint8List());
    image.dispose();
  });
}
