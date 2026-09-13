import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sobilog/core/network/api_client.dart';
import 'package:sobilog/core/network/session_store.dart';
import 'package:sobilog/features/auth/data/auth_service.dart';
import 'package:sobilog/features/finance/data/finance_service.dart';

void main() {
  test('finance service uses backend route and query contracts', () async {
    final requests = <http.Request>[];
    final client = ApiClient(
      baseUrl: 'https://api.sobilog.kr/',
      sessionStore: _MemorySessionStore(accessToken: 'access'),
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(jsonEncode({'data': <String, dynamic>{}}), 200);
      }),
    );
    final service = FinanceApiService(client);

    await service.home();
    await service.ledger(
      period: 'month',
      anchor: DateTime(2026, 9, 13),
      type: 'expense',
      categories: const ['식비', '카페'],
      paymentMethods: const ['현금', '카드'],
    );
    await service.updateExpense('expense-1', {'store_name': '소비로그 카페'});
    await service.deleteExpense('expense-1');
    await service.analysis(year: 2026, month: 9);

    expect(requests[0].url.path, '/home/summary');
    expect(requests[1].url.path, '/home/recent');
    expect(requests[2].url.queryParametersAll, {
      'period': ['month'],
      'date': ['2026-09-13'],
      'type': ['expense'],
      'category': ['식비', '카페'],
      'payment_method': ['현금', '카드'],
    });
    expect(requests[3].method, 'PATCH');
    expect(requests[3].url.path, '/expenses/expense-1');
    expect(jsonDecode(requests[3].body), {'store_name': '소비로그 카페'});
    expect(requests[4].method, 'DELETE');
    expect(requests[4].url.path, '/expenses/expense-1');
    expect(requests[5].url.queryParameters, {'month': '2026-09'});
    expect(
      requests.every(
        (request) => request.headers['authorization'] == 'Bearer access',
      ),
      isTrue,
    );
  });

  test('login persists access and refresh tokens', () async {
    final store = _MemorySessionStore();
    final client = ApiClient(
      baseUrl: 'https://api.sobilog.kr',
      sessionStore: store,
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'data': {
              'access_token': 'new-access',
              'refresh_token': 'new-refresh',
              'pending_deletion_at': null,
            },
          }),
          200,
        ),
      ),
    );

    await AuthApiService(
      client,
    ).login(email: 'hello@sobilog.kr', password: 'password!1');

    expect(store.accessToken, 'new-access');
    expect(store.refreshToken, 'new-refresh');
  });

  test(
    'expired access token is refreshed once and request is retried',
    () async {
      final store = _MemorySessionStore(
        accessToken: 'expired',
        refreshToken: 'refresh-1',
      );
      var protectedCalls = 0;
      final client = ApiClient(
        baseUrl: 'https://api.sobilog.kr',
        sessionStore: store,
        httpClient: MockClient((request) async {
          if (request.url.path == '/auth/refresh') {
            return http.Response(
              jsonEncode({
                'data': {
                  'access_token': 'access-2',
                  'refresh_token': 'refresh-2',
                },
              }),
              200,
            );
          }
          protectedCalls++;
          if (protectedCalls == 1) {
            return http.Response(jsonEncode({'message': 'expired'}), 401);
          }
          expect(request.headers['authorization'], 'Bearer access-2');
          return http.Response(
            jsonEncode({
              'data': {'ok': true},
            }),
            200,
          );
        }),
      );

      expect(await client.get('/home/summary'), {'ok': true});
      expect(protectedCalls, 2);
      expect(store.refreshToken, 'refresh-2');
    },
  );
}

class _MemorySessionStore implements SessionStore {
  _MemorySessionStore({this.accessToken, this.refreshToken});
  String? accessToken;
  String? refreshToken;

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<String?> readAccessToken() async => accessToken;
  @override
  Future<String?> readRefreshToken() async => refreshToken;
  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }
}
