import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sobilog/core/network/api_client.dart';
import 'package:sobilog/core/network/api_exception.dart';
import 'package:sobilog/core/network/session_store.dart';
import 'package:sobilog/features/auth/data/auth_service.dart';
import 'package:sobilog/features/finance/data/finance_service.dart';

void main() {
  test('email signup sends the confirmed age checkbox value', () async {
    http.Request? signupRequest;
    final client = ApiClient(
      baseUrl: 'https://api.sobilog.kr',
      sessionStore: _MemorySessionStore(),
      httpClient: MockClient((request) async {
        signupRequest = request;
        return http.Response(jsonEncode({'data': <String, dynamic>{}}), 200);
      }),
    );

    await AuthApiService(client).signup(
      email: 'user@example.com',
      password: 'Password1!',
      nickname: '소비로그',
      ageConfirmed: true,
      marketingAgreed: false,
    );

    expect(signupRequest?.url.path, '/auth/signup');
    expect(jsonDecode(signupRequest!.body), {
      'email': 'user@example.com',
      'password': 'Password1!',
      'password_confirm': 'Password1!',
      'nickname': '소비로그',
      'terms_agreed': true,
      'privacy_agreed': true,
      'age_confirmed': true,
      'marketing_agreed': false,
    });
  });

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
    await service.deleteExpensePhoto('expense-1', 'photo-1');
    await service.incomeDetail('income-1');
    await service.updateIncome('income-1', {'amount': 250000});
    await service.deleteIncome('income-1');
    await service.analysis(year: 2026, month: 9);
    await service.attendance(month: DateTime(2026, 8));

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
    expect(requests[5].method, 'DELETE');
    expect(requests[5].url.path, '/expenses/expense-1/photos/photo-1');
    expect(requests[6].method, 'GET');
    expect(requests[6].url.path, '/incomes/income-1');
    expect(requests[7].method, 'PATCH');
    expect(requests[7].url.path, '/incomes/income-1');
    expect(jsonDecode(requests[7].body), {'amount': 250000});
    expect(requests[8].method, 'DELETE');
    expect(requests[8].url.path, '/incomes/income-1');
    expect(requests[9].url.queryParameters, {'month': '2026-09'});
    expect(requests[10].url.path, '/mypage/attendance');
    expect(requests[10].url.queryParameters, {'month': '2026-08'});
    expect(
      requests.every(
        (request) => request.headers['authorization'] == 'Bearer access',
      ),
      isTrue,
    );
  });

  test(
    'social login and all terms endpoints follow backend contracts',
    () async {
      final requests = <http.Request>[];
      final store = _MemorySessionStore();
      final client = ApiClient(
        baseUrl: 'https://api.sobilog.kr',
        sessionStore: store,
        httpClient: MockClient((request) async {
          requests.add(request);
          final data =
              request.url.path == '/auth/kakao' ||
                  request.url.path == '/auth/apple'
              ? {
                  'access_token': 'access',
                  'refresh_token': 'refresh',
                  'is_new_user': true,
                }
              : <String, dynamic>{};
          return http.Response(jsonEncode({'data': data}), 200);
        }),
      );
      final service = AuthApiService(client);

      await service.loginWithKakao('kakao-token');
      await service.loginWithApple(
        identityToken: 'apple-identity-token',
        authorizationCode: 'apple-authorization-code',
        email: 'user@privaterelay.appleid.com',
        givenName: '길동',
        familyName: '홍',
      );
      await service.termsDocument();
      await service.termsStatus();
      await service.myAgreement();
      await service.agreeToLatestTerms();
      await service.initialAgree(
        nickname: '소비로그',
        ageConfirmed: true,
        marketingAgreed: true,
      );
      await service.initialAgree(ageConfirmed: true, marketingAgreed: false);

      expect(
        requests.map((request) => '${request.method} ${request.url.path}'),
        [
          'POST /auth/kakao',
          'POST /auth/apple',
          'GET /auth/terms/document',
          'GET /auth/terms/status',
          'GET /auth/terms/my-agreement',
          'POST /auth/terms/agree',
          'POST /auth/terms/initial-agree',
          'POST /auth/terms/initial-agree',
        ],
      );
      expect(jsonDecode(requests.first.body), {
        'kakao_access_token': 'kakao-token',
      });
      expect(jsonDecode(requests[1].body), {
        'identity_token': 'apple-identity-token',
        'authorization_code': 'apple-authorization-code',
        'email': 'user@privaterelay.appleid.com',
        'given_name': '길동',
        'family_name': '홍',
      });
      expect(jsonDecode(requests[6].body), {
        'nickname': '소비로그',
        'terms_agreed': true,
        'privacy_agreed': true,
        'age_confirmed': true,
        'marketing_agreed': true,
      });
      expect(jsonDecode(requests.last.body), {
        'terms_agreed': true,
        'privacy_agreed': true,
        'age_confirmed': true,
        'marketing_agreed': false,
      });
      expect(store.accessToken, 'access');
      expect(store.refreshToken, 'refresh');
    },
  );

  test('initial agreement preserves the E310 nickname error', () async {
    final client = ApiClient(
      baseUrl: 'https://api.sobilog.kr',
      sessionStore: _MemorySessionStore(accessToken: 'access'),
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({'result': 'E310', 'message': '닉네임이 필요합니다'}),
          400,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );

    await expectLater(
      AuthApiService(
        client,
      ).initialAgree(ageConfirmed: true, marketingAgreed: false),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'E310')
            .having((error) => error.message, 'message', '닉네임이 필요합니다'),
      ),
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
