import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/network/api_exception.dart';
import 'package:sobilog/core/storage/app_preferences.dart';
import 'package:sobilog/features/auth/presentation/login_screen.dart';
import 'package:sobilog/features/auth/presentation/terms_screen.dart';
import 'package:sobilog/features/category/data/category_models.dart';
import 'package:sobilog/features/category/data/category_service.dart';
import 'package:sobilog/features/ledger/presentation/ledger_detail_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_screen.dart';
import 'package:sobilog/features/onboarding/presentation/onboarding_screen.dart';
import 'package:sobilog/features/register/presentation/direct_input_guide_screen.dart';
import 'package:sobilog/features/register/presentation/receipt_scan_loading_screen.dart';
import 'package:sobilog/features/register/presentation/register_direct_screen.dart';
import 'package:sobilog/shared/widgets/bank_account_picker.dart';

import 'p2_fake_service.dart';
import 'p2_harness.dart';

Widget _ledger(FakeP2Service service) => LedgerScreen(
  financeService: service,
  initialPeriod: 0,
  initialAnchor: DateTime(2026, 8, 19),
  currentDate: DateTime(2026, 8, 31),
);

class _E508Service extends FakeP2Service {
  @override
  Future<Map<String, dynamic>> recognizeReceipt(String imagePath) async =>
      throw const ApiException(
        statusCode: 400,
        code: 'E508',
        message: '병원·약국 영수증',
      );
}

Future<void> _openFilter(WidgetTester tester, FakeP2Service service) async {
  await showScreen(tester, _ledger(service));
  await tapAndSettle(tester, find.byKey(const Key('ledger-filter-button')));
}

Future<void> _longPress(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.longPress(finder);
  await tester.pumpAndSettle();
}

Future<void> _clearToast(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 3));

void main() {
  setUpAll(loadAppFonts);
  setUp(() {
    CategoryStore.instance.reset();
    resetLedgerFilterMemory();
  });

  // ------------------------------------------------------------ 온보딩·약관
  testWidgets('진입_002-01 온보딩 1/7~7/7 → 시작하기 → 완료 저장', (tester) async {
    final prefs = MemoryAppPreferences();
    await showScreen(tester, OnboardingScreen(preferences: prefs));
    for (var page = 1; page <= 7; page++) {
      await capture(tester, '진입_002-01_온보딩 튜토리얼 [$page of 7]');
      expect(find.text(page == 7 ? '시작하기' : '다음'), findsOneWidget);
      await tapAndSettle(tester, find.byKey(const Key('onboarding-next')));
    }
    expect(prefs.onboarding, isTrue);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('인증_003-01 약관동의: 개인정보 체크 항목 없음 + 안내 행', (tester) async {
    final opened = <Uri>[];
    var agreed = false;
    await showScreen(
      tester,
      TermsScreen(
        onAgreed: () => agreed = true,
        documentLauncher: (uri) async {
          opened.add(uri);
          return true;
        },
      ),
    );
    expect(find.text('[필수] 개인정보 수집 · 이용 동의'), findsNothing);
    expect(find.byKey(const Key('terms-privacy-notice')), findsOneWidget);
    await capture(tester, '인증_003-01_약관동의');
    await tapAndSettle(tester, find.byKey(const Key('terms-privacy-notice')));
    expect(opened, hasLength(1));
    await tapAndSettle(tester, find.text('전체 동의하기'));
    await tapAndSettle(tester, find.text('동의합니다'));
    expect(agreed, isTrue);
  });

  // ------------------------------------------------------------ 등록
  testWidgets('등록_005-03 병원·약국 영수증(E508) → 직접 입력 안내 → 직접 등록', (tester) async {
    final service = _E508Service();
    await showScreen(
      tester,
      ReceiptScanLoadingScreen(imagePath: 'x.jpg', financeService: service),
      settle: false,
    );
    await tester.pumpAndSettle();
    expect(find.byType(DirectInputGuideScreen), findsOneWidget);
    await capture(tester, '등록_005-03_직접 입력 안내');
    await tapAndSettle(tester, find.byKey(const Key('direct-guide-input')));
    expect(find.byType(RegisterDirectScreen), findsOneWidget);
  });

  testWidgets('가계_003-01 내역 상세 [정산완료] → 정산결과', (tester) async {
    final service = FakeP2Service()
      ..expenseDetailData = {
        ...sampleExpenseDetail,
        'dutch_pay_session_id': 'session-1',
        'dutch_pay_status': 'completed',
      };
    await showScreen(
      tester,
      LedgerDetailScreen(expenseId: 'expense-1', financeService: service),
      size: const Size(402, 1640),
    );
    expect(find.text('정산결과'), findsOneWidget);
    await capture(tester, '가계_003-01_내역 상세 [정산완료]');
  });

  testWidgets('더치_005-02 계좌 입력: 은행 선택 → 기타 직접 입력 → 입력 완료', (tester) async {
    ({String bank, String number})? result;
    await showScreen(
      tester,
      Builder(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFF121215),
          body: Center(
            child: TextButton(
              key: const Key('open-bank'),
              onPressed: () async =>
                  result = await showBankAccountPicker(context),
              child: const Text('계좌'),
            ),
          ),
        ),
      ),
    );
    await tapAndSettle(tester, find.byKey(const Key('open-bank')));
    await capture(tester, '더치_005-02_계좌 입력 [은행 선택]');
    await tapAndSettle(tester, find.byType(OutlinedButton).last);
    await tester.enterText(
      find.byKey(const Key('settlement-custom-bank-name')),
      '토스뱅크',
    );
    await tester.enterText(
      find.byKey(const Key('settlement-account-number')),
      '1000-1234-5678',
    );
    await tester.pumpAndSettle();
    await capture(tester, '더치_005-02_계좌 입력 [기타 은행 직접 입력]');
    await tapAndSettle(
      tester,
      find.byKey(const Key('register-settlement-account-number')),
    );
    expect(result?.bank, '토스뱅크');
    expect(result?.number, '100012345678');
  });

  // ------------------------------------------------------------ 가계부·필터
  testWidgets('가계_002-01 [지출 탭]·[수입 탭] + 가계_001-01 필터 적용(수입)', (tester) async {
    final service = FakeP2Service();
    await showScreen(tester, _ledger(service));
    await tapAndSettle(tester, find.byKey(const Key('ledger-entry-type-1')));
    await tapAndSettle(tester, find.byKey(const Key('ledger-filter-button')));
    expect(find.byKey(const Key('ledger-filter-side-income')), findsNothing);
    await tapAndSettle(
      tester,
      find.byKey(const Key('category-chip-expense-취미')),
    );
    await capture(tester, '가계_002-01_필터 시트 [지출 탭]');
    await tapAndSettle(tester, find.byKey(const Key('close-ledger-filter')));

    await tapAndSettle(tester, find.byKey(const Key('ledger-entry-type-2')));
    await tapAndSettle(tester, find.byKey(const Key('ledger-filter-button')));
    await tapAndSettle(
      tester,
      find.byKey(const Key('category-chip-income-급여')),
    );
    await capture(tester, '가계_002-01_필터 시트 [수입 탭]');
    await tapAndSettle(tester, find.byKey(const Key('apply-ledger-filter')));
    expect(service.ledgerQueries.last['type'], 'income');
    expect(service.ledgerQueries.last['income_category'], ['급여']);
    expect(find.byKey(const Key('ledger-applied-filter-급여')), findsOneWidget);
    await capture(tester, '가계_001-01_가계부 목록 [필터 적용(수입)]');
  });

  testWidgets('가계_001-01 [필터 결과 없음] → 필터 초기화', (tester) async {
    final service = FakeP2Service();
    await _openFilter(tester, service);
    await tapAndSettle(
      tester,
      find.byKey(const Key('category-chip-expense-의료')),
    );
    expect(find.text('0건 보기'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('apply-ledger-filter')));
    await capture(tester, '가계_001-01_가계부 목록 [필터 결과 없음]');
    await tapAndSettle(
      tester,
      find.byKey(const Key('ledger-empty-clear-filters')),
    );
    expect(find.byKey(const Key('ledger-applied-filter-의료')), findsNothing);
  });

  testWidgets('가계_002-01 지출+수입 함께 고르면 앱에서 합쳐 보여준다', (tester) async {
    final service = FakeP2Service();
    await _openFilter(tester, service);
    await tapAndSettle(
      tester,
      find.byKey(const Key('category-chip-expense-식비')),
    );
    await tapAndSettle(
      tester,
      find.byKey(const Key('ledger-filter-side-income')),
    );
    await tapAndSettle(
      tester,
      find.byKey(const Key('category-chip-income-급여')),
    );
    await tapAndSettle(tester, find.byKey(const Key('apply-ledger-filter')));
    // 서버에 섞어서 보내지 않는다 (E605 방지).
    for (final query in service.ledgerQueries) {
      final income = query['income_category'] as List;
      final expense = query['category'] as List;
      expect(income.isNotEmpty && expense.isNotEmpty, isFalse);
    }
    expect(find.byKey(const Key('ledger-applied-filter-식비')), findsOneWidget);
    expect(find.byKey(const Key('ledger-applied-filter-급여')), findsOneWidget);
  });

  testWidgets('가계_002-01 기본 카테고리 꾹 토스트', (tester) async {
    await _openFilter(tester, FakeP2Service());
    await _longPress(tester, find.byKey(const Key('category-chip-expense-식비')));
    expect(find.text('기본 카테고리는 수정·삭제할 수 없어요'), findsOneWidget);
    await capture(tester, '가계_002-01_필터 시트 [기본 카테고리 꾹 토스트]');
    await _clearToast(tester);
  });

  testWidgets('가계_002-01 지출 15개 · 수입 10개 초과 토스트', (tester) async {
    final service = FakeP2Service(
      expenseCategories: [
        ...defaultCategories(CategoryKind.expense),
        for (var i = 0; i < 7; i++)
          CategoryItem(
            id: 'x$i',
            name: '지출$i',
            icon: 'fire',
            kind: CategoryKind.expense,
          ),
      ],
      incomeCategories: [
        ...defaultCategories(CategoryKind.income),
        for (var i = 0; i < 5; i++)
          CategoryItem(
            id: 'y$i',
            name: '수입$i',
            icon: 'gift',
            kind: CategoryKind.income,
          ),
      ],
    );
    await _openFilter(tester, service);
    await tapAndSettle(tester, find.byKey(const Key('category-add-chip')));
    expect(find.text('지출 카테고리는 최대 15개까지 만들 수 있어요'), findsOneWidget);
    await capture(tester, '가계_002-01_필터 시트 [지출 15개 초과 토스트]');
    await _clearToast(tester);
    await tapAndSettle(
      tester,
      find.byKey(const Key('ledger-filter-side-income')),
    );
    await tapAndSettle(tester, find.byKey(const Key('category-add-chip')));
    expect(find.text('수입 카테고리는 최대 10개까지 만들 수 있어요'), findsOneWidget);
    await _clearToast(tester);
  });

  testWidgets('가계_002-01 [수입 탭] 수입 10개 초과 토스트 (Figma 2086-34417 데이터)', (
    tester,
  ) async {
    CategoryItem income(String name, String icon, {bool base = false}) =>
        CategoryItem(
          id: 'i-$name',
          name: name,
          icon: base ? null : icon,
          isDefault: base,
          kind: CategoryKind.income,
        );
    final service = FakeP2Service(
      incomeCategories: [
        income('급여', '', base: true),
        income('용돈', '', base: true),
        income('환급·환불', '', base: true),
        income('기타', '', base: true),
        income('알바', 'store'),
        income('부업', 'briefcase'),
        income('이자', 'dollar'),
        income('배당', 'trend'),
        income('선물', 'gift'),
        income('중고판매', 'wallet'),
      ],
    );
    await showScreen(tester, _ledger(service));
    await tapAndSettle(tester, find.byKey(const Key('ledger-entry-type-2')));
    await tapAndSettle(tester, find.byKey(const Key('ledger-filter-button')));
    await tapAndSettle(
      tester,
      find.byKey(const Key('category-chip-income-급여')),
    );
    await tapAndSettle(tester, find.byKey(const Key('category-add-chip')));
    expect(find.text('수입 카테고리는 최대 10개까지 만들 수 있어요'), findsOneWidget);
    // 긴 이름도 칩 안에서 가운데 정렬되고 넘치지 않는다.
    for (final name in ['환급·환불', '중고판매']) {
      final chip = tester.getRect(
        find.byKey(Key('category-chip-income-$name')),
      );
      final label = tester.getRect(find.text(name).last);
      expect(chip.width, 112);
      expect(label.right, lessThanOrEqualTo(chip.right - 8));
    }
    await capture(tester, '가계_002-01_필터 시트 [수입 10개 초과 토스트]');
    await _clearToast(tester);
  });

  // ------------------------------------------------------------ 카테고리
  testWidgets('등록_013-01 카테고리 추가(지출·수입) → 저장 토스트 → 등록 화면에 표시', (tester) async {
    final service = FakeP2Service();
    await _openFilter(tester, service);
    await tapAndSettle(tester, find.byKey(const Key('category-add-chip')));
    await capture(tester, '등록_013-01_카테고리 추가 [지출]');
    await tester.enterText(find.byKey(const Key('category-name-field')), '운동');
    await tapAndSettle(tester, find.byKey(const Key('category-icon-piggy')));
    await tapAndSettle(tester, find.byKey(const Key('category-editor-save')));
    // 서버에는 이름·아이콘(16번째 아이콘 포함)을 그대로 보낸다.
    expect(service.calls, contains('POST /categories 운동 piggy expense'));
    expect(find.text('카테고리를 저장했어요'), findsOneWidget);
    expect(find.byKey(const Key('category-chip-expense-운동')), findsOneWidget);
    await capture(tester, '가계_002-01_필터 시트 [저장 토스트]');
    await _clearToast(tester);

    // 중복 이름은 서버 E512 안내.
    await tapAndSettle(tester, find.byKey(const Key('category-add-chip')));
    await tester.enterText(find.byKey(const Key('category-name-field')), '식비');
    await tapAndSettle(tester, find.byKey(const Key('category-icon-fire')));
    await tapAndSettle(tester, find.byKey(const Key('category-editor-save')));
    expect(find.text('이미 있는 카테고리 이름이에요'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('category-editor-cancel')));
    await _clearToast(tester);

    await tapAndSettle(
      tester,
      find.byKey(const Key('ledger-filter-side-income')),
    );
    await tapAndSettle(tester, find.byKey(const Key('category-add-chip')));
    await capture(tester, '등록_013-01_카테고리 추가 [수입]');
    await tester.enterText(find.byKey(const Key('category-name-field')), '장학금');
    await tapAndSettle(
      tester,
      find.byKey(const Key('category-icon-graduation')),
    );
    await tapAndSettle(tester, find.byKey(const Key('category-editor-save')));
    expect(service.calls, contains('POST /categories 장학금 graduation income'));
    await _clearToast(tester);

    // 직접 만든 카테고리가 지출 등록 카테고리 목록에도 나온다.
    expect(categoryNames(CategoryKind.expense), contains('운동'));
    expect(categoryNames(CategoryKind.income), contains('장학금'));
  });

  testWidgets('등록_013-03 수정·삭제 선택 → 013-02 수정(지출·수입)', (tester) async {
    final service = FakeP2Service();
    await _openFilter(tester, service);
    await _longPress(tester, find.byKey(const Key('category-chip-expense-취미')));
    expect(find.byKey(const Key('category-menu-edit')), findsOneWidget);
    await capture(tester, '등록_013-03_수정·삭제 선택 팝업');
    await tapAndSettle(tester, find.byKey(const Key('category-menu-edit')));
    expect(find.text('지출 카테고리 수정'), findsOneWidget);
    await capture(tester, '등록_013-02_카테고리 수정 [지출]');
    await tester.enterText(find.byKey(const Key('category-name-field')), '사진');
    await tapAndSettle(tester, find.byKey(const Key('category-icon-camera')));
    await tapAndSettle(tester, find.byKey(const Key('category-editor-save')));
    expect(service.calls, contains('PATCH /categories/cat-hobby 사진 camera'));
    expect(find.byKey(const Key('category-chip-expense-사진')), findsOneWidget);
    await _clearToast(tester);

    await tapAndSettle(
      tester,
      find.byKey(const Key('ledger-filter-side-income')),
    );
    await _longPress(tester, find.byKey(const Key('category-chip-income-알바')));
    await tapAndSettle(tester, find.byKey(const Key('category-menu-edit')));
    await capture(tester, '등록_013-02_카테고리 수정 [수입]');
    await tapAndSettle(tester, find.byKey(const Key('category-editor-cancel')));
  });

  testWidgets('등록_013-04 → 013-06 → 013-08 이동 → 013-09 이동 완료', (tester) async {
    final service = FakeP2Service();
    await _openFilter(tester, service);
    await _longPress(tester, find.byKey(const Key('category-chip-expense-취미')));
    await tapAndSettle(tester, find.byKey(const Key('category-menu-delete')));
    // 기록이 있으면 013-04 없이 바로 013-06.
    expect(find.byKey(const Key('category-records-move')), findsOneWidget);
    await capture(tester, '등록_013-06_함께 삭제 안내 팝업');
    await tapAndSettle(tester, find.byKey(const Key('category-records-move')));
    await capture(tester, '등록_013-08_이동할 카테고리 선택');
    await tapAndSettle(
      tester,
      find.byKey(const Key('category-chip-expense-문화')).last,
    );
    await tapAndSettle(tester, find.byKey(const Key('category-move-confirm')));
    expect(service.calls, contains('DELETE /categories/cat-hobby?move_to=문화'));
    await capture(tester, '등록_013-09_이동 완료 팝업');
    await tapAndSettle(tester, find.byKey(const Key('category-move-done')));
    expect(find.byKey(const Key('category-chip-expense-취미')), findsNothing);
    expect(service.expenses.where((e) => e['category'] == '문화').length, 3);
  });

  testWidgets('등록_013-06 → 013-07 전체삭제 → 013-05 삭제 완료', (tester) async {
    final service = FakeP2Service();
    await _openFilter(tester, service);
    await _longPress(tester, find.byKey(const Key('category-chip-expense-취미')));
    await tapAndSettle(tester, find.byKey(const Key('category-menu-delete')));
    await tapAndSettle(
      tester,
      find.byKey(const Key('category-records-delete-all')),
    );
    expect(find.text('더치페이 정산 기록도 함께 삭제돼요'), findsOneWidget);
    await capture(tester, '등록_013-07_전체삭제 2차 확인 팝업');
    await tapAndSettle(
      tester,
      find.byKey(const Key('category-delete-all-confirm')),
    );
    expect(service.calls, contains('DELETE /categories/cat-hobby'));
    expect(find.text('‘취미’가 삭제 되었습니다'), findsOneWidget);
    await capture(tester, '등록_013-05_삭제 완료 팝업');
    await tapAndSettle(tester, find.byKey(const Key('category-delete-done')));
    expect(service.expenses.where((e) => e['category'] == '취미'), isEmpty);
  });

  testWidgets('기록 없는 카테고리 삭제는 바로 삭제 완료', (tester) async {
    final service = FakeP2Service();
    await _openFilter(tester, service);
    await tapAndSettle(
      tester,
      find.byKey(const Key('ledger-filter-side-income')),
    );
    await _longPress(tester, find.byKey(const Key('category-chip-income-알바')));
    await tapAndSettle(tester, find.byKey(const Key('category-menu-delete')));
    expect(find.byKey(const Key('category-records-move')), findsNothing);
    await capture(tester, '등록_013-04_삭제 확인 팝업');
    await tapAndSettle(
      tester,
      find.byKey(const Key('category-delete-confirm')),
    );
    expect(find.text('‘알바’가 삭제 되었습니다'), findsOneWidget);
  });
}
