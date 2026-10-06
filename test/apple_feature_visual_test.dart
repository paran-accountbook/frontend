import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/network/api_exception.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/auth/data/apple_login_client.dart';
import 'package:sobilog/features/auth/data/auth_service.dart';
import 'package:sobilog/features/auth/data/kakao_login_client.dart';
import 'package:sobilog/features/auth/presentation/login_screen.dart';
import 'package:sobilog/features/dutch/presentation/dutch_assignment_screen.dart';
import 'package:sobilog/features/profile/presentation/account_settings_screen.dart';
import 'package:sobilog/features/profile/presentation/profile_edit_screen.dart';

void main() {
  setUpAll(() async {
    final pretendard = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-Medium.otf'))
      ..addFont(rootBundle.load('assets/fonts/Pretendard-SemiBold.otf'));
    final amarante = FontLoader('Amarante')
      ..addFont(rootBundle.load('assets/fonts/Amarante-Regular.ttf'));
    await Future.wait([pretendard.load(), amarante.load()]);
  });

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark, home: screen));
    await tester.pump();
  }

  testWidgets('Apple login screen', (tester) async {
    await pumpScreen(tester, const LoginScreen());
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/apple/login.png'),
    );
  });

  testWidgets('Apple login failure toast', (tester) async {
    await pumpScreen(
      tester,
      const LoginScreen(appleLoginClient: _FailingAppleLoginClient()),
    );
    await tester.tap(find.text('Apple로 시작하기'));
    await tester.pump();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/apple/apple_failure_toast.png'),
    );
  });

  testWidgets('Kakao login failure toast', (tester) async {
    await pumpScreen(
      tester,
      const LoginScreen(kakaoLoginClient: _FailingKakaoLoginClient()),
    );
    await tester.tap(find.text('카카오로 시작하기'));
    await tester.pump();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/apple/kakao_failure_toast.png'),
    );
  });

  testWidgets('Existing email dialog', (tester) async {
    await pumpScreen(
      tester,
      const LoginScreen(
        authService: _AppleConflictAuthService(),
        appleLoginClient: _SuccessfulAppleLoginClient(),
      ),
    );
    await tester.tap(find.text('Apple로 시작하기'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Overlay).first,
      matchesGoldenFile('goldens/apple/existing_email_dialog.png'),
    );
  });

  for (final provider in ['email', 'kakao', 'apple']) {
    testWidgets('$provider account settings', (tester) async {
      await pumpScreen(tester, AccountSettingsScreen(provider: provider));
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/apple/account_$provider.png'),
      );
    });
  }

  testWidgets('Email profile', (tester) async {
    await pumpScreen(
      tester,
      ProfileEditScreen(initialData: _profile(provider: 'email')),
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/apple/profile_email.png'),
    );
  });

  testWidgets('Apple profile hides internal email', (tester) async {
    await pumpScreen(
      tester,
      ProfileEditScreen(initialData: _profile(provider: 'apple')),
    );
    expect(find.text('apple_123@apple.sobilog.internal'), findsNothing);
    expect(find.text('Apple 로그인 · 이메일 가림'), findsOneWidget);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/apple/profile_apple.png'),
    );
  });

  testWidgets('Dutch assignment select all', (tester) async {
    await pumpScreen(tester, const DutchAssignmentScreen());
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/apple/dutch_select_all.png'),
    );
  });
}

Map<String, dynamic> _profile({required String provider}) => {
  'nickname': '소비로그',
  'email': provider == 'apple'
      ? 'apple_123@apple.sobilog.internal'
      : 'welcome@sobilog.com',
  'provider': provider,
  'created_at': '2026-09-01T15:20:00+09:00',
  'bank_name': '소비은행',
  'bank_account_number': '000-0000-0000',
};

class _FailingAppleLoginClient implements AppleLoginClient {
  const _FailingAppleLoginClient();

  @override
  Future<AppleLoginCredential> login() =>
      throw const AppleLoginFailedException();
}

class _SuccessfulAppleLoginClient implements AppleLoginClient {
  const _SuccessfulAppleLoginClient();

  @override
  Future<AppleLoginCredential> login() async => const AppleLoginCredential(
    identityToken: 'identity-token',
    authorizationCode: 'authorization-code',
    email: 'user@example.com',
    givenName: '길동',
    familyName: '홍',
  );
}

class _FailingKakaoLoginClient implements KakaoLoginClient {
  const _FailingKakaoLoginClient();

  @override
  Future<String> login() =>
      throw const ApiException(code: 'E214', message: '카카오 로그인 실패');
}

class _AppleConflictAuthService implements AuthService {
  const _AppleConflictAuthService();

  @override
  Future<Map<String, dynamic>> loginWithApple({
    required String identityToken,
    required String authorizationCode,
    String? email,
    String? givenName,
    String? familyName,
  }) => throw const ApiException(code: 'E221', message: '이미 가입된 이메일입니다');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
