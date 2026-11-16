import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sobilog/core/network/api_client.dart';
import 'package:sobilog/core/network/session_store.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/finance/data/finance_service.dart';
import 'package:sobilog/features/home/presentation/home_screen.dart';
import 'package:sobilog/features/ledger/presentation/income_detail_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_detail_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_edit_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_screen.dart';

import 'p2/p2_harness.dart';

void main() {
  setUpAll(loadAppFonts);
  testWidgets('가계 내역에 API 카테고리 아이콘을 표시한다', (tester) async {
    final requests = <http.Request>[];
    final service = _service(
      requests,
      (_) => {
        'total_expense_amount': 28000,
        'total_income_amount': 0,
        'balance': -28000,
        'days': [
          {
            'date': '2026-09-12',
            'expenses': [
              {
                'id': '11111111-1111-1111-1111-111111111111',
                'store_name': '영화관',
                'category': '문화',
                'payment_method': '현금',
                'amount': 28000,
              },
            ],
            'incomes': <Map<String, dynamic>>[],
          },
        ],
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LedgerScreen(financeService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ledger-category-문화')), findsOneWidget);
  });

  testWidgets('카테고리·결제수단 필터를 복수 쿼리로 조회한다', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    addTearDown(tester.view.reset);
    final requests = <http.Request>[];
    final service = _service(requests, (_) => _ledgerData);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LedgerScreen(financeService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('ledger-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('category-chip-expense-식비')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('category-chip-expense-카페')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('ledger-payment-체크카드')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ledger-payment-체크카드')));
    await tester.pumpAndSettle();

    expect(find.textContaining('건 보기'), findsOneWidget);
    final previewRequest = requests.lastWhere(
      (request) =>
          request.method == 'GET' && request.url.path == '/expenses/summary',
    );
    expect(previewRequest.url.queryParametersAll['category'], ['식비', '카페']);
    expect(previewRequest.url.queryParametersAll['payment_method'], ['체크카드']);

    await tester.tap(find.byKey(const Key('apply-ledger-filter')));
    await tester.pumpAndSettle();

    final filtered = requests.lastWhere(
      (request) => request.method == 'GET' && request.url.path == '/expenses',
    );
    expect(filtered.url.queryParametersAll['category'], ['식비', '카페']);
    expect(filtered.url.queryParametersAll['payment_method'], ['체크카드']);
    expect(find.byKey(const Key('ledger-applied-filter-식비')), findsOneWidget);
    expect(find.byKey(const Key('ledger-applied-filter-체크카드')), findsOneWidget);
    expect(find.byKey(const Key('ledger-clear-all-filters')), findsOneWidget);

    await tester.tap(find.byKey(const Key('ledger-clear-all-filters')));
    await tester.pumpAndSettle();
    final cleared = requests.lastWhere(
      (request) => request.method == 'GET' && request.url.path == '/expenses',
    );
    expect(cleared.url.queryParametersAll['category'], isNull);
    expect(cleared.url.queryParametersAll['payment_method'], isNull);
  });

  testWidgets('주·일 탭은 기간 제목과 API period를 함께 변경한다', (tester) async {
    final requests = <http.Request>[];
    final service = _service(requests, (_) => _ledgerData);
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LedgerScreen(financeService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('ledger-period-1')));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(
        '${weekStart.month}월 ${weekStart.day}일 ~ '
        '${weekEnd.month}월 ${weekEnd.day}일',
      ),
      findsOneWidget,
    );
    expect(requests.last.url.queryParameters['period'], 'week');

    await tester.tap(find.byKey(const Key('ledger-period-2')));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(
        '${now.year}년 ${now.month}월 ${now.day}일 (${weekdays[now.weekday - 1]})',
      ),
      findsOneWidget,
    );
    expect(requests.last.url.queryParameters['period'], 'day');
  });

  testWidgets('가계 내역 영역은 긴 목록을 아래로 스크롤한다', (tester) async {
    final requests = <http.Request>[];
    final entries = List.generate(
      12,
      (index) => {
        'id': 'expense-$index',
        'store_name': '상점 $index',
        'category': '식비',
        'payment_method': '카드',
        'amount': 1000 + index,
      },
    );
    final service = _service(
      requests,
      (_) => {
        ..._ledgerData,
        'days': [
          {
            'date': '2026-09-14',
            'expenses': entries,
            'incomes': <Map<String, dynamic>>[],
          },
        ],
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LedgerScreen(financeService: service),
      ),
    );
    await tester.pumpAndSettle();

    final scroll = find.byKey(const Key('ledger-entries-scroll'));
    final before = tester.getTopLeft(find.text('상점 0')).dy;
    await tester.drag(scroll, const Offset(0, -300));
    await tester.pumpAndSettle();
    final after = tester.getTopLeft(find.text('상점 0')).dy;
    expect(after, lessThan(before));
    expect(find.text('상점 11'), findsOneWidget);
  });

  testWidgets('상세 API 대기 중 예시 영수증을 노출하지 않고 상세 화면을 연다', (tester) async {
    final service = _DelayedDetailService();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LedgerScreen(financeService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('E2E 영화관'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(LedgerDetailScreen), findsOneWidget);
    expect(find.byKey(const Key('ledger-detail-loading')), findsOneWidget);
    expect(find.text('아주대학교 카페'), findsNothing);
    expect(find.text('아메리카노'), findsNothing);

    service.detail.complete({
      ..._expenseData,
      'store_name': 'E2E 영화관',
      'category': '문화',
      'items': [
        {'item_name': '영화 티켓', 'quantity': 1, 'unit_price': 14000},
      ],
    });
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ledger-detail-loading')), findsNothing);
    expect(find.text('E2E 영화관'), findsOneWidget);
    expect(find.text('영화 티켓'), findsOneWidget);
  });

  testWidgets('QA 05 상세에서 4개 필드와 품목을 수정해 PATCH하고 목록으로 돌아간다', (tester) async {
    final requests = <http.Request>[];
    var expense = Map<String, dynamic>.of(_expenseData);
    final service = _service(requests, (request) {
      if (request.method == 'PATCH') {
        expense = {
          ...expense,
          ...jsonDecode(request.body) as Map<String, dynamic>,
        };
      }
      if (request.url.path == '/expenses') {
        return {
          ..._ledgerData,
          'days': [
            {
              'date': '2026-09-01',
              'expenses': [
                {...expense, 'amount': 4800},
              ],
            },
          ],
        };
      }
      return expense;
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LedgerScreen(financeService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('테스트 카페'));
    await tester.pumpAndSettle();
    expect(find.byType(LedgerDetailScreen), findsOneWidget);
    await tester.tap(find.text('테스트 카페'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '수정된 카페');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('결제일시'));
    final date = find.byType(DatePickerDialog);
    expect(date, findsOneWidget);
    await _tapVisible(
      tester,
      find.descendant(of: date, matching: find.text('2')),
    );
    await _tapVisible(tester, find.text('OK'));
    expect(find.byKey(const Key('receipt-five-minute-picker')), findsOneWidget);
    await _tapVisible(tester, find.text('선택 완료'));

    await _tapVisible(tester, find.text('카테고리'));
    await _tapVisible(tester, find.text('쇼핑'));
    await _tapVisible(
      tester,
      find.byKey(const Key('receipt-payment-method-row')),
    );
    await _tapVisible(tester, find.text('간편결제'));
    await _tapVisible(tester, find.byKey(const Key('receipt-item-0')));
    await tester.enterText(
      find.byKey(const Key('receipt-item-price-input-0')),
      '4800',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(LedgerDetailScreen), findsOneWidget);
    expect(find.byType(LedgerEditScreen, skipOffstage: false), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('save-ledger-entry')));
    await tester.tap(find.byKey(const Key('save-ledger-entry')));
    await tester.pumpAndSettle();

    final patch = requests.singleWhere((request) => request.method == 'PATCH');
    expect(patch.url.path, '/expenses/11111111-1111-1111-1111-111111111111');
    final payload = jsonDecode(patch.body) as Map<String, dynamic>;
    expect(payload['store_name'], '수정된 카페');
    expect(DateTime.parse(payload['paid_at'] as String).toLocal().day, 2);
    expect(payload['category'], '쇼핑');
    expect(payload['payment_method'], '간편결제');
    expect(payload['items'], [
      {'item_name': '아메리카노', 'quantity': 1, 'unit_price': 4800},
    ]);
    expect(find.byType(LedgerScreen), findsOneWidget);
    expect(find.byType(LedgerDetailScreen), findsNothing);
    expect(find.text('수정된 카페'), findsOneWidget);
    expect(find.text('간편결제'), findsOneWidget);
    expect(
      requests.where(
        (request) => request.method == 'GET' && request.url.path == '/expenses',
      ),
      hasLength(2),
    );
  });

  testWidgets('수정 화면의 삭제 확인 후 DELETE API를 호출한다', (tester) async {
    final requests = <http.Request>[];
    final service = _service(requests, (request) {
      if (request.method == 'DELETE') return {'message': '삭제되었습니다'};
      return _expenseData;
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LedgerEditScreen(
          expenseId: '11111111-1111-1111-1111-111111111111',
          financeService: service,
          initialData: _expenseData,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('delete-ledger-entry')));
    await tester.pumpAndSettle();
    expect(find.text('더치페이 정산 기록도 함께 삭제돼요'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-delete-ledger-entry')));
    await tester.pumpAndSettle();

    final delete = requests.singleWhere(
      (request) => request.method == 'DELETE',
    );
    expect(delete.url.path, '/expenses/11111111-1111-1111-1111-111111111111');
    expect(tester.takeException(), isNull);
  });

  testWidgets('상세 하단의 내역 삭제 버튼이 DELETE API를 호출한다', (tester) async {
    final requests = <http.Request>[];
    final service = _service(requests, (request) {
      if (request.method == 'DELETE') return {'message': '삭제되었습니다'};
      return _expenseData;
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LedgerDetailScreen(
          expenseId: '11111111-1111-1111-1111-111111111111',
          financeService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final deleteButton = find.byKey(const Key('delete-ledger-entry'));
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-ledger-entry')));
    await tester.pumpAndSettle();

    final request = requests.singleWhere(
      (request) =>
          request.method == 'DELETE' &&
          request.url.path == '/expenses/11111111-1111-1111-1111-111111111111',
    );
    expect(request.method, 'DELETE');
    expect(tester.takeException(), isNull);
  });

  testWidgets('소비사진 x 버튼이 해당 사진 DELETE API를 호출한다', (tester) async {
    final requests = <http.Request>[];
    final service = _service(requests, (request) {
      if (request.method == 'DELETE') return {'message': '삭제되었습니다'};
      return {
        ..._expenseData,
        'photos': [
          {'id': 'photo-1', 'url': null},
        ],
      };
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LedgerDetailScreen(
          expenseId: '11111111-1111-1111-1111-111111111111',
          financeService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final photoDelete = find.byKey(const Key('delete-expense-photo-photo-1'));
    await tester.ensureVisible(photoDelete);
    await tester.tap(photoDelete);
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(
      requests.where(
        (request) =>
            request.method == 'DELETE' &&
            request.url.path ==
                '/expenses/11111111-1111-1111-1111-111111111111/photos/photo-1',
      ),
      hasLength(1),
    );
    expect(find.byKey(const Key('delete-expense-photo-photo-1')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('QA 05 사진 없는 상세에서 갤러리 취소 후 재선택하고 업로드한다', (tester) async {
    final directory = Directory.systemTemp.createTempSync('sobilog-qa-photo-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/qa.png');
    file.writeAsBytesSync(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jP1sAAAAASUVORK5CYII=',
      ),
    );

    const picker = MethodChannel('plugins.flutter.io/image_picker');
    final messenger = tester.binding.defaultBinaryMessenger;
    var pickerCalls = 0;
    messenger.setMockMethodCallHandler(picker, (call) async {
      expect(call.method, 'pickImage');
      expect(call.arguments['source'], 1);
      return ++pickerCalls == 1 ? null : file.path;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(picker, null));

    final requests = <http.Request>[];
    final uploaded = Completer<void>();
    final service = _service(requests, (request) {
      if (request.method == 'POST') {
        uploaded.complete();
        expect(request.url.path, '/expenses/${_expenseData['id']}/photos');
        expect(request.headers['authorization'], 'Bearer access');
        expect(
          request.headers['content-type'],
          startsWith('multipart/form-data;'),
        );
        expect(
          latin1.decode(request.bodyBytes),
          contains('name="files"; filename="qa.png"'),
        );
        return {
          'photos': [
            {'id': 'qa-photo'},
          ],
        };
      }
      return _expenseData;
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LedgerDetailScreen(
          expenseId: _expenseData['id'] as String,
          financeService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final add = find.byKey(const Key('add-expense-photo'));
    await _tapVisible(tester, add);
    expect(pickerCalls, 1);
    expect(requests.where((request) => request.method == 'POST'), isEmpty);
    await tester.tap(add);
    for (var attempt = 0; attempt < 80 && !uploaded.isCompleted; attempt++) {
      await tester.pump();
      await tester.runAsync(
        () => Future.any([
          uploaded.future,
          Future<void>.delayed(const Duration(milliseconds: 25)),
        ]),
      );
    }
    await tester.pumpAndSettle();
    expect(pickerCalls, 2);
    expect(requests.where((request) => request.method == 'POST'), hasLength(1));
    expect(
      find.byKey(const Key('delete-expense-photo-qa-photo')),
      findsOneWidget,
    );
  });

  testWidgets('홈 최근 내역은 등록 시각의 날짜와 시간을 표시한다', (tester) async {
    final requests = <http.Request>[];
    final service = _service(requests, (request) {
      if (request.url.path == '/home/recent') {
        return {
          'entries': [
            {
              'id': '11111111-1111-1111-1111-111111111111',
              'type': 'expense',
              'label': '저녁 카페',
              'amount': 4500,
              'registered_at': '2026-09-14T19:42:00+09:00',
            },
          ],
        };
      }
      return <String, dynamic>{};
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: HomeScreen(financeService: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('9/14'), findsOneWidget);
    expect(find.text('오후 7:42'), findsOneWidget);
    expect(find.text('오전 10:30'), findsNothing);
  });

  testWidgets('홈의 최근 수입은 GET 상세 조회 후 상세 화면을 연다', (tester) async {
    final requests = <http.Request>[];
    final service = _service(requests, (request) {
      if (request.url.path == '/home/recent') {
        return {
          'entries': [
            {
              'id': '22222222-2222-2222-2222-222222222222',
              'type': 'income',
              'label': '급여',
              'amount': 3000000,
              'registered_at': '2026-09-23T10:00:00+09:00',
            },
          ],
        };
      }
      if (request.url.path == '/incomes/22222222-2222-2222-2222-222222222222') {
        return {
          'id': '22222222-2222-2222-2222-222222222222',
          'amount': 3000000,
          'income_date': '2026-09-23',
          'category': '급여',
          'memo': '9월 급여',
          'created_at': '2026-09-23T10:00:00+09:00',
        };
      }
      return <String, dynamic>{};
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: HomeScreen(financeService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('급여'));
    await tester.pumpAndSettle();

    expect(find.byType(IncomeDetailScreen), findsOneWidget);
    expect(find.text('9월 급여'), findsOneWidget);
    expect(
      requests.where(
        (request) =>
            request.method == 'GET' &&
            request.url.path == '/incomes/22222222-2222-2222-2222-222222222222',
      ),
      hasLength(1),
    );
  });
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

FinanceApiService _service(
  List<http.Request> requests,
  Map<String, dynamic> Function(http.Request request) responseData,
) => FinanceApiService(
  ApiClient(
    baseUrl: 'https://api.sobilog.kr',
    sessionStore: _MemorySessionStore(),
    httpClient: MockClient((request) async {
      requests.add(request);
      return http.Response.bytes(
        utf8.encode(jsonEncode({'data': responseData(request)})),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  ),
);

final _ledgerData = <String, dynamic>{
  'total_expense_amount': 4500,
  'total_income_amount': 0,
  'expense_count': 1,
  'income_count': 0,
  'balance': -4500,
  'days': <Map<String, dynamic>>[],
};

final _expenseData = <String, dynamic>{
  'id': '11111111-1111-1111-1111-111111111111',
  'store_name': '테스트 카페',
  'paid_at': '2026-09-01T15:20:00+09:00',
  'category': '카페',
  'payment_method': '카드',
  'total_amount': 4500,
  'memo': '테스트',
  'items': [
    {'item_name': '아메리카노', 'quantity': 1, 'unit_price': 4500},
  ],
};

class _MemorySessionStore implements SessionStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccessToken() async => 'access';

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {}
}

class _DelayedDetailService implements FinanceService {
  final detail = Completer<Map<String, dynamic>>();

  @override
  Future<Map<String, dynamic>> ledger({
    required String period,
    required DateTime anchor,
    String type = 'all',
    List<String> categories = const [],
    List<String> paymentMethods = const [],
  }) async => {
    ..._ledgerData,
    'days': [
      {
        'date': '2026-09-14',
        'expenses': [
          {
            'id': '11111111-1111-1111-1111-111111111111',
            'store_name': 'E2E 영화관',
            'category': '문화',
            'payment_method': '카드',
            'amount': 14000,
          },
        ],
        'incomes': <Map<String, dynamic>>[],
      },
    ],
  };

  @override
  Future<Map<String, dynamic>> expenseDetail(String id) => detail.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
