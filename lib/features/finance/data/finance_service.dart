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
}

class FinanceApiService implements FinanceService {
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
  Future<Map<String, dynamic>> createIncome(Map<String, Object?> body) async =>
      await _client.post('/incomes', body: body) as Map<String, dynamic>;
}
