import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sobilog/core/network/api_client.dart';
import 'package:sobilog/core/network/session_store.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/finance/data/finance_service.dart';
import 'package:sobilog/features/home/presentation/home_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_detail_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_edit_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_screen.dart';

void main() {
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
    final requests = <http.Request>[];
    final service = _service(requests, (_) => _ledgerData);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LedgerScreen(financeService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('필터'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ledger-filter-식비')));
    await tester.tap(find.byKey(const Key('ledger-filter-카페')));
    await tester.tap(find.byKey(const Key('ledger-filter-카드')));
    await tester.tap(find.byKey(const Key('apply-ledger-filter')));
    await tester.pumpAndSettle();

    final filtered = requests.lastWhere(
      (request) => request.method == 'GET' && request.url.path == '/expenses',
    );
    expect(filtered.url.queryParametersAll['category'], ['식비', '카페']);
    expect(filtered.url.queryParametersAll['payment_method'], ['카드']);
  });

  testWidgets('상세의 수정에서 PATCH 저장 후 상세를 다시 조회한다', (tester) async {
    final requests = <http.Request>[];
    final service = _service(requests, (request) {
      if (request.method == 'PATCH') return _expenseData;
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

    final edit = find.byKey(const Key('edit-ledger-entry'));
    expect(tester.widget<GestureDetector>(edit).onTap, isNotNull);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    expect(find.byType(LedgerEditScreen), findsOneWidget);

    await tester.tap(find.text('테스트 카페'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '수정된 카페');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final patch = requests.singleWhere((request) => request.method == 'PATCH');
    expect(patch.url.path, '/expenses/11111111-1111-1111-1111-111111111111');
    final payload = jsonDecode(patch.body) as Map<String, dynamic>;
    expect(payload['store_name'], '수정된 카페');
    expect(payload['category'], '카페');
    expect(payload['payment_method'], '카드');
    expect(payload['items'], hasLength(1));
    expect(
      requests.where(
        (request) =>
            request.method == 'GET' &&
            request.url.path.startsWith('/expenses/'),
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
    expect(find.text('삭제한 내역은 되돌릴 수 없습니다. 삭제할까요?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-delete-ledger-entry')));
    await tester.pumpAndSettle();

    final delete = requests.singleWhere(
      (request) => request.method == 'DELETE',
    );
    expect(delete.url.path, '/expenses/11111111-1111-1111-1111-111111111111');
    expect(tester.takeException(), isNull);
  });

  testWidgets('영수증 이미지가 없는 상세에서는 사진 영역을 숨긴다', (tester) async {
    final requests = <http.Request>[];
    final service = _service(requests, (_) => _expenseData);
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

    expect(find.text('소비사진  1'), findsNothing);
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
  'balance': -4500,
  'items': <Map<String, dynamic>>[],
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
