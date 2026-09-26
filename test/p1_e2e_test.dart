import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/network/api_exception.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/auth/data/auth_service.dart';
import 'package:sobilog/features/auth/data/kakao_login_client.dart';
import 'package:sobilog/features/auth/presentation/kakao_signup_name_screen.dart';
import 'package:sobilog/features/auth/presentation/login_screen.dart';
import 'package:sobilog/features/auth/presentation/terms_screen.dart';
import 'package:sobilog/features/finance/data/finance_service.dart';
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
    expect(auth.marketingAgreed, isTrue);
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
    required String nickname,
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
