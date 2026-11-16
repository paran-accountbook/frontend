import '../../../core/network/api_client.dart';
import '../../analysis/data/insight_service.dart';
import '../../category/data/category_models.dart';
import '../../category/data/category_service.dart';

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

/// Allows the home summary and recent entries to render independently.
abstract interface class ProgressiveHomeFinanceService {
  Future<Map<String, dynamic>> homeSummary();
  Future<Map<String, dynamic>> homeRecent();
}

/// 가계_001·002: 지출·수입 필터를 모두 지원하는 내역 조회.
/// 지출 조건(category·payment_method)과 수입 조건(income_category)은 같이 보내지 않는다.
abstract interface class LedgerFilterService {
  Future<Map<String, dynamic>> ledgerFiltered({
    required String period,
    required DateTime anchor,
    String type = 'all',
    List<String> categories = const [],
    List<String> paymentMethods = const [],
    List<String> incomeCategories = const [],
  });

  Future<Map<String, dynamic>> ledgerSummary({
    required String period,
    required DateTime anchor,
    String type = 'all',
    List<String> categories = const [],
    List<String> paymentMethods = const [],
    List<String> incomeCategories = const [],
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

class FinanceApiService
    implements
        FinanceService,
        ExpensePhotoService,
        ProgressiveHomeFinanceService,
        LedgerFilterService,
        CategoryService,
        InsightService {
  const FinanceApiService(this._client);
  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> home() async {
    final responses = await Future.wait([homeSummary(), homeRecent()]);
    return {'summary': responses[0], 'recent': responses[1]};
  }

  @override
  Future<Map<String, dynamic>> homeSummary() async =>
      await _client.get('/home/summary') as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> homeRecent() async =>
      await _client.get('/home/recent') as Map<String, dynamic>;

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

  Map<String, Object?> _ledgerQuery({
    required String period,
    required DateTime anchor,
    required String type,
    required List<String> categories,
    required List<String> paymentMethods,
    required List<String> incomeCategories,
  }) => {
    'period': period,
    'date': anchor.toIso8601String().substring(0, 10),
    'type': type,
    if (categories.isNotEmpty) 'category': categories,
    if (paymentMethods.isNotEmpty) 'payment_method': paymentMethods,
    if (incomeCategories.isNotEmpty) 'income_category': incomeCategories,
  };

  @override
  Future<Map<String, dynamic>> ledgerFiltered({
    required String period,
    required DateTime anchor,
    String type = 'all',
    List<String> categories = const [],
    List<String> paymentMethods = const [],
    List<String> incomeCategories = const [],
  }) async =>
      await _client.get(
            '/expenses',
            query: _ledgerQuery(
              period: period,
              anchor: anchor,
              type: type,
              categories: categories,
              paymentMethods: paymentMethods,
              incomeCategories: incomeCategories,
            ),
          )
          as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> ledgerSummary({
    required String period,
    required DateTime anchor,
    String type = 'all',
    List<String> categories = const [],
    List<String> paymentMethods = const [],
    List<String> incomeCategories = const [],
  }) async =>
      await _client.get(
            '/expenses/summary',
            query: _ledgerQuery(
              period: period,
              anchor: anchor,
              type: type,
              categories: categories,
              paymentMethods: paymentMethods,
              incomeCategories: incomeCategories,
            ),
          )
          as Map<String, dynamic>;

  @override
  Future<List<CategoryItem>> categories(CategoryKind kind) async {
    final data =
        await _client.get('/categories', query: {'type': kind.apiValue})
            as Map<String, dynamic>;
    return (data['categories'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CategoryItem.fromJson)
        .toList();
  }

  @override
  Future<CategoryItem> createCategory({
    required String name,
    required String icon,
    required CategoryKind kind,
  }) async {
    final data =
        await _client.post(
              '/categories',
              body: {'name': name, 'icon': icon, 'type': kind.apiValue},
            )
            as Map<String, dynamic>;
    return CategoryItem.fromJson({...data, 'is_default': false});
  }

  @override
  Future<CategoryItem> updateCategory(
    CategoryItem category, {
    required String name,
    required String icon,
  }) async {
    final data =
        await _client.patch(
              '/categories/${category.id}',
              body: {'name': name, 'icon': icon},
            )
            as Map<String, dynamic>;
    return CategoryItem.fromJson({
      ...data,
      'is_default': false,
      'record_count': category.recordCount,
    });
  }

  @override
  Future<Map<String, dynamic>> deleteCategory(
    CategoryItem category, {
    String? moveTo,
  }) async {
    final query = moveTo == null
        ? ''
        : '?move_to=${Uri.encodeQueryComponent(moveTo)}';
    return await _client.delete('/categories/${category.id}$query')
            as Map<String, dynamic>? ??
        const {};
  }

  @override
  Future<Map<String, dynamic>> rewards() async =>
      await _client.get('/mypage/rewards') as Map<String, dynamic>;

  @override
  Future<void> markRewardsSeen() async {
    await _client.post('/mypage/rewards/seen');
  }

  @override
  Future<Map<String, dynamic>> aiOpinionStatus() async =>
      await _client.get('/analysis/ai-opinion') as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> generateAiOpinion() async =>
      await _client.post('/analysis/ai-opinion', body: const {})
          as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> savingHintStatus() async =>
      await _client.get('/analysis/saving-hint') as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> generateSavingHint() async =>
      await _client.post('/analysis/saving-hint', body: const {})
          as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> agreeSavingHintConsent() async =>
      await _client.post('/analysis/saving-hint/consent')
          as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> withdrawSavingHintConsent() async =>
      await _client.delete('/analysis/saving-hint/consent')
          as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> pattern() async =>
      await _client.get('/analysis/pattern') as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> repurchase() async =>
      await _client.get('/analysis/repurchase') as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> recurringExpenses() async =>
      await _client.get('/analysis/recurring-expenses') as Map<String, dynamic>;

  @override
  Future<void> dismissRecurringExpense(String storeName) async {
    await _client.post(
      '/analysis/recurring-expenses/dismiss',
      body: {'store_name': storeName},
    );
  }
}
