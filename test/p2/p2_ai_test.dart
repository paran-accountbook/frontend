import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobilog/core/network/api_exception.dart';
import 'package:sobilog/features/analysis/presentation/analysis_overview_screen.dart';
import 'package:sobilog/features/analysis/presentation/ai_opinion_screen.dart';
import 'package:sobilog/features/analysis/presentation/pattern_report_screen.dart';
import 'package:sobilog/features/analysis/presentation/repeat_expense_screen.dart';
import 'package:sobilog/features/analysis/presentation/saving_hint_screen.dart';
import 'package:sobilog/features/category/data/category_service.dart';
import 'package:sobilog/features/ledger/presentation/ledger_detail_screen.dart';

import 'p2_fake_service.dart';
import 'p2_harness.dart';

Future<void> _openAiTab(WidgetTester tester, FakeP2Service service) async {
  await showScreen(
    tester,
    AnalysisOverviewScreen(
      financeService: service,
      initialMonth: DateTime(2026, 11),
      initialTab: AnalysisTab.ai,
    ),
    size: const Size(402, 1304),
  );
}

void main() {
  setUpAll(loadAppFonts);
  setUp(CategoryStore.instance.reset);

  testWidgets('분석_008-01 AI분석 첫 화면 (잠김) + 탭 전환', (tester) async {
    final service = FakeP2Service();
    await _openAiTab(tester, service);
    expect(find.text('AI 코치'), findsOneWidget);
    expect(find.text('0/7일'), findsOneWidget);
    expect(find.text('0/20일'), findsOneWidget);
    expect(find.text('이번 달 1회'), findsNWidgets(2));
    await capture(tester, '분석_008-01_AI 분석 첫 화면');

    // 잠긴 카드는 눌러도 이동하지 않는다.
    await tapAndSettle(tester, find.byKey(const Key('ai-unlock-pattern')));
    expect(find.byType(PatternReportScreen), findsNothing);

    // [리포트]로 돌아갔다 다시 [AI분석].
    await tapAndSettle(tester, find.byKey(const Key('analysis-tab-report')));
    expect(find.text('AI 코치'), findsNothing);
    await tapAndSettle(tester, find.byKey(const Key('analysis-tab-ai')));
    expect(find.text('AI 코치'), findsOneWidget);
  });

  testWidgets('분석_008-01 기록 쌓인 상태 (열림 · 충전 대기)', (tester) async {
    final service = FakeP2Service()
      ..rewardsData = rewardsFor(streak: 7, month: 20)
      ..aiOpinionData = aiStatus(remaining: 0, latest: true)
      ..savingHintData = savingStatus(remaining: 0, agreed: true, latest: true);
    await _openAiTab(tester, service);
    expect(find.text('12월 1일 충전'), findsNWidgets(2));
    expect(find.text('10월 결과 다시 보기'), findsNWidgets(2));
    await capture(tester, '분석_008-01_AI 분석 [열림·다시 보기]');

    await tapAndSettle(tester, find.byKey(const Key('ai-coach-opinion')));
    expect(find.byType(AiOpinionScreen), findsOneWidget);
    expect(find.byKey(const Key('ai-next-reset')), findsOneWidget);
  });

  testWidgets('분석_005-01 소비 습관 진단 생성', (tester) async {
    final service = FakeP2Service();
    await _openAiTab(tester, service);
    await tapAndSettle(tester, find.byKey(const Key('ai-coach-opinion')));
    expect(service.calls, contains('POST /analysis/ai-opinion'));
    expect(find.byType(AiOpinionScreen), findsOneWidget);
    expect(find.text('한눈에 보기'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
    tester.view.physicalSize = const Size(402, 1100);
    await tester.pumpAndSettle();
    await capture(tester, '분석_005-01_소비 습관 진단');
  });

  testWidgets('분석_005 생성 실패 안내 (기록 부족)', (tester) async {
    final service = FakeP2Service()
      ..generateError = const ApiException(
        statusCode: 400,
        code: 'E705',
        message: '기록 부족',
      );
    await _openAiTab(tester, service);
    await tapAndSettle(tester, find.byKey(const Key('ai-coach-opinion')));
    expect(find.text('지난달 기록이 5건 이상이어야 받을 수 있어요'), findsOneWidget);
    expect(find.byType(AiOpinionScreen), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('분석_007-02 동의 팝업 → 007-03 내용 보기 → 동의 → 007-01 결과', (
    tester,
  ) async {
    final service = FakeP2Service();
    await _openAiTab(tester, service);
    await tester.tap(find.byKey(const Key('ai-coach-saving')));
    await tester.pumpAndSettle();
    expect(find.text('동의하지 않아도 다른 기능은 그대로 쓸 수 있어요'), findsOneWidget);
    tester.view.physicalSize = const Size(402, 874);
    await tester.pumpAndSettle();
    await capture(tester, '분석_007-02_제3자 제공 동의 팝업');

    await tester.tap(find.byKey(const Key('consent-detail-open')));
    await tester.pumpAndSettle();
    expect(find.byType(SavingHintConsentDetailScreen), findsOneWidget);
    await capture(tester, '분석_007-03_제3자 제공 동의 내용');
    await tester.tap(find.byKey(const Key('consent-detail-confirm')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('consent-agree')));
    await tester.pumpAndSettle();
    expect(service.calls, contains('POST /analysis/saving-hint/consent'));
    expect(service.calls, contains('POST /analysis/saving-hint'));
    expect(find.byType(SavingHintScreen), findsOneWidget);
    expect(find.text('많이 쓴 1위'), findsOneWidget);
    tester.view.physicalSize = const Size(402, 1240);
    await tester.pumpAndSettle();
    await capture(tester, '분석_007-01_할인 찾기 결과');

    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    await tapAndSettle(tester, find.byKey(const Key('saving-address-1')));
    expect(copied, '경기 수원시 영통구 매영로 150');
    expect(find.text('주소를 복사했어요'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('분석_007-02 동의 안 함 → 생성하지 않음', (tester) async {
    final service = FakeP2Service();
    await _openAiTab(tester, service);
    await tester.tap(find.byKey(const Key('ai-coach-saving')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('consent-decline')));
    await tester.pumpAndSettle();
    expect(service.calls, isNot(contains('POST /analysis/saving-hint')));
    expect(find.byType(SavingHintScreen), findsNothing);
  });

  testWidgets('분석_003-01 소비 패턴 리포트', (tester) async {
    final service = FakeP2Service()
      ..rewardsData = rewardsFor(streak: 7, month: 0);
    await _openAiTab(tester, service);
    await tapAndSettle(tester, find.byKey(const Key('ai-unlock-pattern')));
    expect(find.byType(PatternReportScreen), findsOneWidget);
    expect(find.text('최근 3개월 · 분석 기간 9~11월'), findsOneWidget);
    expect(find.text('토요일 28%'), findsOneWidget);
    expect(find.text('저녁·밤 (18~24시)'), findsOneWidget);
    expect(find.text('12회 · 48,200원'), findsOneWidget);
    tester.view.physicalSize = const Size(402, 1352);
    await tester.pumpAndSettle();
    await capture(tester, '분석_003-01_소비 패턴 리포트');
  });

  testWidgets('분석_003-01 기록 없음', (tester) async {
    final service = FakeP2Service()
      ..patternData = {
        'start_month': '2026-09',
        'end_month': '2026-11',
        'has_data': false,
      };
    await showScreen(tester, PatternReportScreen(service: service));
    expect(find.text('최근 3개월 소비 기록이 없어요'), findsOneWidget);
    await capture(tester, '분석_003-01_소비 패턴 리포트 [기록 없음]');
  });

  testWidgets('분석_004-01 반복 지출 분석 + 펼침 + 전체 보기 + 상세 이동', (tester) async {
    final service = FakeP2Service();
    await showScreen(
      tester,
      RepeatExpenseScreen(service: service, financeService: service),
      size: const Size(402, 1504),
    );
    expect(find.text('전체 8개 보기'), findsOneWidget);
    expect(find.text('같은 날 구매 · 마지막 11/1'), findsOneWidget);
    expect(find.text('월 고정 지출 · 이번 달 지출의 18%'), findsOneWidget);
    expect(find.text('월 약 13,500원'), findsOneWidget);
    await tester.tap(find.byKey(const Key('repeat-item-1')));
    await tester.pumpAndSettle();
    expect(find.text('10월 28일'), findsOneWidget);
    await capture(tester, '분석_004-01_반복 지출 분석');

    await tapAndSettle(tester, find.byKey(const Key('repeat-show-all')));
    expect(find.text('물티슈'), findsOneWidget);
    expect(find.byKey(const Key('repeat-show-all')), findsNothing);

    await tapAndSettle(
      tester,
      find.byKey(const Key('repeat-purchase-expense-4')),
    );
    expect(find.byType(LedgerDetailScreen), findsOneWidget);
  });

  testWidgets('분석_006-01 정기 지출 제외 팝업 → 제외하기', (tester) async {
    final service = FakeP2Service();
    await showScreen(
      tester,
      RepeatExpenseScreen(service: service, financeService: service),
      size: const Size(402, 1504),
    );
    await tester.tap(find.byKey(const Key('recurring-exclude-넷플릭스')));
    await tester.pumpAndSettle();
    expect(find.text("'넷플릭스'를 정기 지출에서 제외할까요?"), findsOneWidget);
    expect(find.text('제외한 내역은 되돌릴 수 없어요'), findsOneWidget);
    tester.view.physicalSize = const Size(402, 874);
    await tester.pumpAndSettle();
    await capture(tester, '분석_006-01_정기 지출 제외 팝업');
    await tester.tap(find.text('제외하기'));
    await tester.pumpAndSettle();
    expect(service.dismissedStores, ['넷플릭스']);
    expect(find.text('넷플릭스'), findsNothing);
    expect(find.text('학교 앞 세탁소'), findsOneWidget);
  });

  testWidgets('분석_004-01 예외 문구', (tester) async {
    final service = FakeP2Service()
      ..repurchaseData = {'has_data': true, 'items': <Object>[]}
      ..recurringData = {'has_data': true, 'items': <Object>[]};
    await showScreen(tester, RepeatExpenseScreen(service: service));
    expect(find.text('반복 구매한 품목이 아직 없어요'), findsOneWidget);
    expect(find.text('정기 지출이 아직 없어요'), findsOneWidget);

    service
      ..repurchaseData = {'has_data': false, 'items': <Object>[]}
      ..recurringData = {'has_data': false, 'items': <Object>[]};
    await showScreen(
      tester,
      RepeatExpenseScreen(key: UniqueKey(), service: service),
    );
    expect(find.text('기록이 쌓이면 알려드릴게요'), findsOneWidget);
  });
}
