import '../../../core/network/api_client.dart';

/// 더치페이(정산) 기능(더치_001~005)을 위한 백엔드 연동 서비스.
abstract interface class DutchPayService {
  /// 더치_001: 특정 지출 내역에 대해 더치페이 세션에 진입한다.
  /// 이미 진행 중인 세션이 있으면 이어서 반환한다.
  Future<Map<String, dynamic>> entry(String expenseId);

  /// 더치_002: 최근 정산에 사용한 이름 추천 목록(최대 10개)을 가져온다.
  Future<List<String>> recentNames();

  /// 더치_002: 참여 인원 목록을 전체 교체로 등록한다. 본인 포함 최소 2명.
  Future<List<Map<String, dynamic>>> setParticipants(
    String sessionId,
    List<Map<String, Object?>> participants,
  );

  /// 더치_003: 품목별 인원 배정을 전체 교체로 저장한다.
  Future<Map<String, dynamic>> setAssignments(
    String sessionId,
    List<Map<String, Object?>> assignments,
  );

  /// 더치_004: 인원별 정산 결과(배정 품목/금액)를 조회한다.
  Future<Map<String, dynamic>> result(String sessionId);

  /// 더치_005: 인원별 정산 요청 메시지(계좌+요청금액)를 조회한다.
  Future<Map<String, dynamic>> summary(String sessionId);

  /// 더치_005: 이 화면에서 계좌 정보를 직접 수정한다(마이_001에도 반영).
  Future<Map<String, dynamic>> updateAccount(
    String sessionId, {
    String? bankName,
    String? bankAccountNumber,
  });

  /// 더치_005: 정산 완료 처리를 한다.
  Future<String> complete(String sessionId);
}

class DutchPayApiService implements DutchPayService {
  const DutchPayApiService(this._client);
  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> entry(String expenseId) async =>
      await _client.get('/expenses/$expenseId/dutch-pay')
          as Map<String, dynamic>;

  @override
  Future<List<String>> recentNames() async {
    final data =
        await _client.get('/dutch-pay/recent-names') as Map<String, dynamic>;
    return (data['names'] as List?)?.cast<String>() ?? const [];
  }

  @override
  Future<List<Map<String, dynamic>>> setParticipants(
    String sessionId,
    List<Map<String, Object?>> participants,
  ) async {
    final data =
        await _client.put(
              '/dutch-pay/$sessionId/participants',
              body: {'participants': participants},
            )
            as Map<String, dynamic>;
    return (data['participants'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const [];
  }

  @override
  Future<Map<String, dynamic>> setAssignments(
    String sessionId,
    List<Map<String, Object?>> assignments,
  ) async =>
      await _client.put(
            '/dutch-pay/$sessionId/assignments',
            body: {'assignments': assignments},
          )
          as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> result(String sessionId) async =>
      await _client.get('/dutch-pay/$sessionId/result') as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> summary(String sessionId) async =>
      await _client.get('/dutch-pay/$sessionId/summary')
          as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> updateAccount(
    String sessionId, {
    String? bankName,
    String? bankAccountNumber,
  }) async =>
      await _client.patch(
            '/dutch-pay/$sessionId/summary/account',
            body: {
              'bank_name': bankName,
              'bank_account_number': bankAccountNumber,
            },
          )
          as Map<String, dynamic>;

  @override
  Future<String> complete(String sessionId) async {
    final data =
        await _client.post('/dutch-pay/$sessionId/complete')
            as Map<String, dynamic>;
    return data['message'] as String? ?? '정산이 완료되었습니다';
  }
}
