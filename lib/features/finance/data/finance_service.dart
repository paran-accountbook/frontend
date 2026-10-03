import '../../../core/network/api_client.dart';

abstract interface class FinanceService {
  Future<Map<String, dynamic>> home();
  Future<Map<String, dynamic>> ledger({
    required String period,
    required DateTime anchor,
    String type = 'all',
    List<String> categories = const [],
    List<String> paymentMethods = const [],
  });
  Future<Map<String, dynamic>> expenseDetail(String id);
  Future<Map<String, dynamic>> updateExpense(
    String id,
    Map<String, Object?> body,
  );
  Future<Map<String, dynamic>> deleteExpense(String id);
  Future<Map<String, dynamic>> analysis({
    required int year,
    required int month,
  });
  Future<Map<String, dynamic>> profile();
  Future<Map<String, dynamic>> updateProfile(Map<String, Object?> body);
  Future<Map<String, dynamic>> recognizeReceipt(String imagePath);
  Future<Map<String, dynamic>> createExpense(Map<String, Object?> body);
  Future<Map<String, dynamic>> createIncome(Map<String, Object?> body);
  Future<Map<String, dynamic>> incomeDetail(String id);
  Future<Map<String, dynamic>> updateIncome(
    String id,
    Map<String, Object?> body,
  );
  Future<Map<String, dynamic>> deleteIncome(String id);

  /// 마이_002: 출석 및 기록 현황(연속 기록일수, 이번 달 기록률 등)을 조회한다.
  Future<Map<String, dynamic>> attendance({DateTime? month});

  /// 마이_002: 오늘을 무지출 날로 기록한다.
  Future<void> markNoSpendDay();

  /// 마이_004: 알림 설정을 조회한다.
  Future<Map<String, dynamic>> notificationSettings();

  /// 마이_004: 알림 설정을 수정한다(부분 수정 가능).
  Future<Map<String, dynamic>> updateNotificationSettings(
    Map<String, Object?> body,
  );

  /// 분석_002: 월간 지출 목표를 조회한다.
  Future<Map<String, dynamic>> monthlyGoal({
    required int year,
    required int month,
  });

  /// 분석_002: 월간 지출 목표를 설정/수정한다.
  Future<Map<String, dynamic>> setMonthlyGoal({
    required int year,
    required int month,
    required int amount,
  });
}

abstract interface class ExpensePhotoService {
  Future<Map<String, dynamic>> uploadExpensePhoto(
    String expenseId,
    String imagePath,
  );

  Future<Map<String, dynamic>> deleteExpensePhoto(
    String expenseId,
    String photoId,
  );
}

class FinanceApiService implements FinanceService, ExpensePhotoService {
  const FinanceApiService(this._client);
  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> home() async {
    final responses = await Future.wait([
      _client.get('/home/summary'),
      _client.get('/home/recent'),
    ]);
    return {
      'summary': responses[0] as Map<String, dynamic>,
      'recent': responses[1] as Map<String, dynamic>,
    };
  }

  @override
  Future<Map<String, dynamic>> ledger({
    required String period,
    required DateTime anchor,
    String type = 'all',
    List<String> categories = const [],
    List<String> paymentMethods = const [],
  }) async =>
      await _client.get(
            '/expenses',
            query: {
              'period': period,
              'date': anchor.toIso8601String().substring(0, 10),
              'type': type,
              if (categories.isNotEmpty) 'category': categories,
              if (paymentMethods.isNotEmpty) 'payment_method': paymentMethods,
            },
          )
          as Map<String, dynamic>;
  @override
  Future<Map<String, dynamic>> expenseDetail(String id) async =>
      await _client.get('/expenses/$id') as Map<String, dynamic>;
  @override
  Future<Map<String, dynamic>> updateExpense(
    String id,
    Map<String, Object?> body,
  ) async =>
      await _client.patch('/expenses/$id', body: body) as Map<String, dynamic>;
  @override
  Future<Map<String, dynamic>> deleteExpense(String id) async =>
      await _client.delete('/expenses/$id') as Map<String, dynamic>;
  @override
  Future<Map<String, dynamic>> analysis({
    required int year,
    required int month,
  }) async =>
      await _client.get(
            '/analysis/monthly',
            query: {'month': '$year-${month.toString().padLeft(2, '0')}'},
          )
          as Map<String, dynamic>;
  @override
  Future<Map<String, dynamic>> profile() async =>
      await _client.get('/mypage/profile') as Map<String, dynamic>;
  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, Object?> body) async =>
      await _client.patch('/mypage/profile', body: body)
          as Map<String, dynamic>;
  @override
  Future<Map<String, dynamic>> recognizeReceipt(String imagePath) async =>
      await _client.multipartPost('/expenses/receipt', filePath: imagePath)
          as Map<String, dynamic>;
  @override
  Future<Map<String, dynamic>> createExpense(Map<String, Object?> body) async =>
      await _client.post('/expenses', body: body) as Map<String, dynamic>;
  @override
  Future<Map<String, dynamic>> uploadExpensePhoto(
    String expenseId,
    String imagePath,
  ) async =>
      await _client.multipartPost(
            '/expenses/$expenseId/photos',
            filePath: imagePath,
            field: 'files',
          )
          as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> deleteExpensePhoto(
    String expenseId,
    String photoId,
  ) async =>
      await _client.delete('/expenses/$expenseId/photos/$photoId')
          as Map<String, dynamic>;
  @override
  Future<Map<String, dynamic>> createIncome(Map<String, Object?> body) async =>
      await _client.post('/incomes', body: body) as Map<String, dynamic>;
  @override
  Future<Map<String, dynamic>> incomeDetail(String id) async =>
      await _client.get('/incomes/$id') as Map<String, dynamic>;
  @override
  Future<Map<String, dynamic>> updateIncome(
    String id,
    Map<String, Object?> body,
  ) async =>
      await _client.patch('/incomes/$id', body: body) as Map<String, dynamic>;
  @override
  Future<Map<String, dynamic>> deleteIncome(String id) async =>
      await _client.delete('/incomes/$id') as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> attendance({DateTime? month}) async =>
      await _client.get(
            '/mypage/attendance',
            query: month == null
                ? null
                : {
                    'month':
                        '${month.year}-${month.month.toString().padLeft(2, '0')}',
                  },
          )
          as Map<String, dynamic>;

  @override
  Future<void> markNoSpendDay() async {
    await _client.post('/mypage/attendance/no-spend-day');
  }

  @override
  Future<Map<String, dynamic>> notificationSettings() async =>
      await _client.get('/mypage/notifications') as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> updateNotificationSettings(
    Map<String, Object?> body,
  ) async =>
      await _client.patch('/mypage/notifications', body: body)
          as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> monthlyGoal({
    required int year,
    required int month,
  }) async =>
      await _client.get(
            '/analysis/monthly-goal',
            query: {'year': year, 'month': month},
          )
          as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> setMonthlyGoal({
    required int year,
    required int month,
    required int amount,
  }) async =>
      await _client.put(
            '/analysis/monthly-goal',
            body: {'year': year, 'month': month, 'amount': amount},
          )
          as Map<String, dynamic>;
}
