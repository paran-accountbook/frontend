import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sobilog/core/network/api_client.dart';
import 'package:sobilog/core/network/session_store.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/auth/data/auth_service.dart';
import 'package:sobilog/features/auth/presentation/signup_name_screen.dart';
import 'package:sobilog/features/auth/presentation/signup_password_screen.dart';
import 'package:sobilog/features/auth/presentation/terms_screen.dart';
import 'package:sobilog/features/auth/presentation/verification_screen.dart';

void main() {
  testWidgets('email signup carries the checked age value from UI to HTTP', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final requests = <http.Request>[];
    final auth = AuthApiService(
      ApiClient(
        baseUrl: 'https://api.sobilog.kr',
        sessionStore: _MemorySessionStore(),
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(jsonEncode({'data': <String, dynamic>{}}), 200);
        }),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: VerificationScreen(email: 'test@example.com', authService: auth),
      ),
    );

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    expect(find.byType(TermsScreen), findsOneWidget);

    await tester.tap(find.text('[필수] 서비스 이용약관 동의'));
    await tester.tap(find.text('[필수] 개인정보 수집 · 이용 동의'));
    await tester.tap(find.text('동의합니다'));
    await tester.pump();
    expect(find.byType(SignupPasswordScreen), findsNothing);
    expect(requests.map((request) => request.url.path), [
      '/auth/verify/check-code',
    ]);

    await tester.tap(find.text('[필수] 만 18세 이상입니다'));
    await tester.tap(find.text('동의합니다'));
    await tester.pumpAndSettle();
    expect(find.byType(SignupPasswordScreen), findsOneWidget);

    final passwordFields = find.byType(TextField);
    await tester.enterText(passwordFields.at(0), 'Password1!');
    await tester.enterText(passwordFields.at(1), 'Password1!');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.byType(SignupNameScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField), '소비로그');
    await tester.tap(find.text('가입 완료'));
    await tester.pump();
    await tester.pump();

    expect(requests.map((request) => request.url.path), [
      '/auth/verify/check-code',
      '/auth/signup',
    ]);
    final signupBody = jsonDecode(requests.last.body) as Map<String, dynamic>;
    expect(signupBody['age_confirmed'], isTrue);
    expect(signupBody['terms_agreed'], isTrue);
    expect(signupBody['privacy_agreed'], isTrue);
    expect(signupBody['nickname'], '소비로그');
  });
}

class _MemorySessionStore implements SessionStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {}
}
