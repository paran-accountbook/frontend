import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/network/api_exception.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/auth/data/auth_service.dart';
import 'package:sobilog/features/auth/data/apple_login_client.dart';
import 'package:sobilog/features/auth/data/kakao_login_client.dart';
import 'package:sobilog/features/auth/presentation/kakao_signup_name_screen.dart';
import 'package:sobilog/features/auth/presentation/login_screen.dart';
import 'package:sobilog/features/auth/presentation/terms_screen.dart';
import 'package:sobilog/features/finance/data/finance_service.dart';
import 'package:sobilog/features/dutch/data/dutch_pay_service.dart';
import 'package:sobilog/features/dutch/data/kakao_share_service.dart';
import 'package:sobilog/features/dutch/presentation/dutch_assignment_screen.dart';
import 'package:sobilog/features/dutch/presentation/dutch_request_screen.dart';
import 'package:sobilog/features/dutch/presentation/dutch_result_screen.dart';
import 'package:sobilog/features/ledger/presentation/income_detail_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_screen.dart';
import 'package:sobilog/features/profile/presentation/attendance_screen.dart';

void main() {
  testWidgets('카카오 로그인 취소는 실패 메시지로 표시하지 않는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LoginScreen(
          authService: _KakaoAuthService(),
          kakaoLoginClient: _CanceledKakaoLoginClient(),
        ),
      ),
    );

    await tester.tap(find.text('카카오로 시작하기'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.textContaining('완료하지 못했습니다'), findsNothing);
  });

  testWidgets('P1 카카오 신규 사용자는 약관 동의 후 이름을 입력한다', (tester) async {
    final auth = _KakaoAuthService();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LoginScreen(
          authService: auth,
          kakaoLoginClient: _FakeKakaoLoginClient(),
        ),
      ),
    );

    await tester.tap(find.text('카카오로 시작하기'));
    await tester.pumpAndSettle();

    expect(find.byType(TermsScreen), findsOneWidget);
    expect(find.byType(KakaoSignupNameScreen), findsNothing);

    await tester.tap(find.text('전체 동의하기'));
    await tester.tap(find.text('동의합니다'));
    await tester.pumpAndSettle();

    expect(find.byType(KakaoSignupNameScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), '소비로그');
    await tester.tap(find.text('가입 완료'));
    await tester.pump();

    expect(auth.agreedNickname, '소비로그');
    expect(auth.marketingAgreed, isFalse);
  });

  testWidgets('Apple 신규 사용자는 Apple 정보로 로그인하고 약관 뒤 이름 입력을 생략한다', (tester) async {
    final auth = _AppleAuthService();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LoginScreen(
          authService: auth,
          appleLoginClient: const _FakeAppleLoginClient(),
        ),
      ),
    );

    await tester.tap(find.text('Apple로 시작하기'));
    await tester.pumpAndSettle();

    expect(auth.identityToken, 'identity-token');
    expect(auth.authorizationCode, 'authorization-code');
    expect(auth.email, 'user@example.com');
    expect(auth.givenName, '길동');
    expect(auth.familyName, '홍');
    expect(find.byType(TermsScreen), findsOneWidget);

    await tester.tap(find.text('전체 동의하기'));
    await tester.tap(find.text('동의합니다'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(KakaoSignupNameScreen), findsNothing);
    expect(auth.initialAgreeCalled, isTrue);
    expect(auth.agreedNickname, isNull);
  });

  testWidgets('Apple 이메일이 기존 이메일 계정과 겹치면 안내 모달을 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LoginScreen(
          authService: _AppleConflictAuthService(),
          appleLoginClient: const _FakeAppleLoginClient(),
        ),
      ),
    );

    await tester.tap(find.text('Apple로 시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('이미 가입된 이메일이에요'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.text('이메일로 로그인'), findsWidgets);
  });

  testWidgets('P1 수입 목록에서 상세를 열고 PATCH 수정한다', (tester) async {
    final service = _IncomeFinanceService();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LedgerScreen(financeService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('급여'));
    await tester.pumpAndSettle();
    expect(find.byType(IncomeDetailScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit-income')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('income-amount-row')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('income-amount-input')),
      '3200000',
    );
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('수정 완료'));
    await tester.pumpAndSettle();

    expect(service.updatedId, 'income-1');
    expect(service.updatedBody?['amount'], 3200000);
    expect(find.byType(IncomeDetailScreen), findsOneWidget);
  });

  testWidgets('P1 수입 수정 화면에서 DELETE 삭제한다', (tester) async {
    final service = _IncomeFinanceService();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LedgerScreen(financeService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('급여'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-income')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-income')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-income')));
    await tester.pumpAndSettle();

    expect(service.deletedId, 'income-1');
    expect(find.byType(IncomeDetailScreen), findsNothing);
  });

  testWidgets('P1 출석 달력은 이동한 월을 API로 다시 조회한다', (tester) async {
    final service = _AttendanceFinanceService();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: AttendanceScreen(
          financeService: service,
          today: DateTime(2026, 9, 25),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(service.requestedMonths, [DateTime(2026, 9)]);
    await tester.tap(find.byKey(const Key('attendance-prev-month')));
    await tester.pumpAndSettle();

    expect(service.requestedMonths, [DateTime(2026, 9), DateTime(2026, 8)]);
    expect(find.byKey(const Key('attendance-day-2-recorded')), findsOneWidget);
    expect(find.byKey(const Key('attendance-day-4-no-spend')), findsOneWidget);

    await tester.tap(find.byKey(const Key('attendance-next-month')));
    await tester.pumpAndSettle();
    expect(service.requestedMonths.last, DateTime(2026, 9));
  });

  testWidgets('P1 품목 배정은 개별 선택과 원 단위 나머지를 정확히 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const DutchAssignmentScreen(
          items: [
            {'id': 'demo-1', 'item_name': '커피', 'amount': 10000, 'quantity': 1},
          ],
          participants: [
            {'id': 'self', 'name': '나', 'is_self': true},
            {'id': 'p2', 'name': '철수', 'is_self': false},
            {'id': 'p3', 'name': '영희', 'is_self': false},
          ],
        ),
      ),
    );

    expect(find.text('전원 선택'), findsNothing);
    await tester.tap(find.text('나'));
    await tester.tap(find.text('철수'));
    await tester.tap(find.text('영희'));
    await tester.pump();

    expect(find.text('전원 해제'), findsNothing);
    expect(find.text('3,334'), findsOneWidget);
    expect(find.text('3,333'), findsNWidgets(2));
  });

  testWidgets('P1 품목별 전원선택은 모든 참여자를 선택하고 다시 해제한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const DutchAssignmentScreen(
          items: [
            {'id': 'item-1', 'item_name': '커피', 'amount': 9000, 'quantity': 3},
          ],
          participants: [
            {'id': 'self', 'name': '나', 'is_self': true},
            {'id': 'p2', 'name': '철수', 'is_self': false},
            {'id': 'p3', 'name': '영희', 'is_self': false},
          ],
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('dutch-select-all-item-1')));
    await tester.pump();
    expect(find.text('3명 선택 · 1인당'), findsOneWidget);
    expect(find.text('3,000원'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dutch-select-all-item-1')));
    await tester.pump();
    expect(find.text('0명 선택 · 1인당'), findsOneWidget);
  });

  testWidgets('P1 정산 결과는 서버의 잔돈 포함 상태와 이전 버튼을 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: DutchResultScreen(
          sessionId: 'session-1',
          dutchPayService: _DutchResultService(),
          selfName: '나',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('잔돈 포함'), findsOneWidget);
    expect(find.text('이전'), findsOneWidget);
    expect(find.text('다음'), findsOneWidget);
  });

  testWidgets('P1 정산 요청은 선택한 인원의 미리보기와 공유 텍스트를 갱신한다', (tester) async {
    String? sharedMessage;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: DutchRequestScreen(
          onShareText: (message) async => sharedMessage = message,
        ),
      ),
    );

    final shareButton = find.byKey(const ValueKey('dutch-share-p3'));
    await tester.ensureVisible(shareButton);
    await tester.pumpAndSettle();
    await tester.tap(shareButton);
    await tester.pumpAndSettle();
    expect(find.text('공유'), findsWidgets);
    await tester.tap(find.byKey(const Key('share-via-kakao')));
    await tester.pumpAndSettle();

    expect(sharedMessage, contains('영희'));
    expect(find.text('개별 · 영희'), findsOneWidget);
    expect(find.text('이전'), findsNothing);
    expect(find.text('완료'), findsOneWidget);
  });

  testWidgets('P1 정산 요청 상단 전체 복사는 전체 메시지를 복사한다', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const DutchRequestScreen()),
    );

    expect(find.text('전체 복사'), findsNWidgets(2));
    tester
        .widget<GestureDetector>(find.byKey(const Key('dutch-copy-all-header')))
        .onTap!();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('메시지를 복사했어요'), findsOneWidget);
  });

  testWidgets('P1 카카오톡 공유는 선택한 멤버 메시지를 Share SDK로 전달한다', (tester) async {
    final kakaoShare = _FakeKakaoShareService();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: DutchRequestScreen(kakaoShareService: kakaoShare),
      ),
    );

    final shareButton = find.byKey(const ValueKey('dutch-share-p3'));
    await tester.ensureVisible(shareButton);
    await tester.pumpAndSettle();
    await tester.tap(shareButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('share-via-kakao')));
    await tester.pumpAndSettle();

    expect(kakaoShare.messages, hasLength(1));
    expect(kakaoShare.messages.single, contains('홍길동님이 영희님께'));
    expect(kakaoShare.messages.single, contains('14,500원'));
    expect(kakaoShare.messages.single, contains('아주은행 000-0000-0000'));
  });
}

class _FakeKakaoShareService implements KakaoShareService {
  final messages = <String>[];

  @override
  Future<void> shareText(String message) async => messages.add(message);
}

class _DutchResultService implements DutchPayService {
  @override
  Future<Map<String, dynamic>> result(String sessionId) async => {
    'total_amount': 10000,
    'participants': [
      {
        'participant_id': 'self',
        'name': '나',
        'amount': 3334,
        'has_remainder': true,
        'items': [
          {
            'expense_item_id': 'item-1',
            'item_name': '커피',
            'share_amount': 3334,
            'has_remainder': true,
          },
        ],
      },
      {
        'participant_id': 'p2',
        'name': '철수',
        'amount': 3333,
        'has_remainder': false,
        'items': <Map<String, dynamic>>[],
      },
      {
        'participant_id': 'p3',
        'name': '영희',
        'amount': 3333,
        'has_remainder': false,
        'items': <Map<String, dynamic>>[],
      },
    ],
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeKakaoLoginClient implements KakaoLoginClient {
  @override
  Future<String> login() async => 'kakao-access-token';
}

class _CanceledKakaoLoginClient implements KakaoLoginClient {
  @override
  Future<String> login() => throw const ApiException(
    code: 'KAKAO_LOGIN_CANCELED',
    message: '카카오 로그인이 취소되었습니다',
  );
}

class _FakeAppleLoginClient implements AppleLoginClient {
  const _FakeAppleLoginClient();

  @override
  Future<AppleLoginCredential> login() async => const AppleLoginCredential(
    identityToken: 'identity-token',
    authorizationCode: 'authorization-code',
    email: 'user@example.com',
    givenName: '길동',
    familyName: '홍',
  );
}

class _AppleAuthService implements AuthService {
  String? identityToken;
  String? authorizationCode;
  String? email;
  String? givenName;
  String? familyName;
  bool initialAgreeCalled = false;
  String? agreedNickname;

  @override
  Future<Map<String, dynamic>> loginWithApple({
    required String identityToken,
    required String authorizationCode,
    String? email,
    String? givenName,
    String? familyName,
  }) async {
    this.identityToken = identityToken;
    this.authorizationCode = authorizationCode;
    this.email = email;
    this.givenName = givenName;
    this.familyName = familyName;
    return {
      'is_new_user': true,
      'pending_deletion_at': null,
      'terms_agreed': false,
      'profile_complete': true,
    };
  }

  @override
  Future<Map<String, dynamic>> initialAgree({
    String? nickname,
    required bool marketingAgreed,
  }) async {
    initialAgreeCalled = true;
    agreedNickname = nickname;
    return {'nickname': '홍길동'};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AppleConflictAuthService implements AuthService {
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

class _KakaoAuthService implements AuthService {
  String? agreedNickname;
  bool? marketingAgreed;

  @override
  Future<Map<String, dynamic>> loginWithKakao(String kakaoAccessToken) async =>
      {'is_new_user': true, 'pending_deletion_at': null};

  @override
  Future<Map<String, dynamic>> termsStatus() async => {
    'initial_agreement_required': true,
    'reconsent_required': false,
  };

  @override
  Future<Map<String, dynamic>> initialAgree({
    String? nickname,
    required bool marketingAgreed,
  }) async {
    agreedNickname = nickname;
    this.marketingAgreed = marketingAgreed;
    return {'nickname': nickname};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _IncomeFinanceService implements FinanceService {
  String? detailId;
  String? updatedId;
  Map<String, Object?>? updatedBody;
  String? deletedId;

  @override
  Future<Map<String, dynamic>> ledger({
    required String period,
    required DateTime anchor,
    String type = 'all',
    List<String> categories = const [],
    List<String> paymentMethods = const [],
  }) async => {
    'total_expense_amount': 0,
    'total_income_amount': 3000000,
    'expense_count': 0,
    'income_count': 1,
    'balance': 3000000,
    'days': [
      {
        'date': '2026-09-23',
        'expenses': <Map<String, dynamic>>[],
        'incomes': [
          {
            'id': 'income-1',
            'amount': 3000000,
            'category': '급여',
            'memo': '9월 급여',
          },
        ],
      },
    ],
  };

  @override
  Future<Map<String, dynamic>> incomeDetail(String id) async {
    detailId = id;
    return {
      'id': id,
      'amount': 3000000,
      'income_date': '2026-09-23',
      'category': '급여',
      'memo': '9월 급여',
      'created_at': '2026-09-23T10:00:00+09:00',
    };
  }

  @override
  Future<Map<String, dynamic>> updateIncome(
    String id,
    Map<String, Object?> body,
  ) async {
    updatedId = id;
    updatedBody = body;
    return {'id': id, ...body};
  }

  @override
  Future<Map<String, dynamic>> deleteIncome(String id) async {
    deletedId = id;
    return {'message': '삭제되었습니다'};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AttendanceFinanceService implements FinanceService {
  final requestedMonths = <DateTime>[];

  @override
  Future<Map<String, dynamic>> attendance({DateTime? month}) async {
    requestedMonths.add(DateTime(month!.year, month.month));
    final isAugust = month.year == 2026 && month.month == 8;
    return {
      'current_streak': 2,
      'max_streak': 5,
      'this_month_recorded_days': isAugust ? 2 : 0,
      'this_month_recording_rate': isAugust ? 6.0 : 0.0,
      'this_month_no_spend_days': isAugust ? 1 : 0,
      'calendar': isAugust
          ? [
              {'date': '2026-08-02', 'status': 'recorded'},
              {'date': '2026-08-04', 'status': 'no_spend'},
            ]
          : <Map<String, dynamic>>[],
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
