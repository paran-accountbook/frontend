import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sobilog/core/network/api_client.dart';
import 'package:sobilog/core/network/session_store.dart';
import 'package:sobilog/core/theme/app_theme.dart';
import 'package:sobilog/features/finance/data/finance_service.dart';
import 'package:sobilog/features/ledger/presentation/ledger_detail_screen.dart';
import 'package:sobilog/features/ledger/presentation/ledger_screen.dart';

void main() {
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

    await tester.tap(find.text('▽ 필터'));
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
    expect(find.text('내역 수정'), findsOneWidget);
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final patch = requests.singleWhere((request) => request.method == 'PATCH');
    expect(patch.url.path, '/expenses/11111111-1111-1111-1111-111111111111');
    final payload = jsonDecode(patch.body) as Map<String, dynamic>;
    expect(payload['store_name'], '테스트 카페');
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
