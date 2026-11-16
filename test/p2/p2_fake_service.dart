import 'package:sobilog/core/network/api_exception.dart';
import 'package:sobilog/features/analysis/data/insight_service.dart';
import 'package:sobilog/features/category/data/category_models.dart';
import 'package:sobilog/features/category/data/category_service.dart';
import 'package:sobilog/features/finance/data/finance_service.dart';
import 'package:sobilog/features/finance/data/payment_methods.dart';

/// 백엔드 명세(https://api.sobilog.kr/docs)의 응답 모양을 따르는 테스트용 서버.
class FakeP2Service
    implements
        FinanceService,
        LedgerFilterService,
        CategoryService,
        InsightService,
        ExpensePhotoService {
  FakeP2Service({
    List<CategoryItem>? expenseCategories,
    List<CategoryItem>? incomeCategories,
    List<Map<String, dynamic>>? expenses,
    List<Map<String, dynamic>>? incomes,
  }) : expenseCategories = expenseCategories ?? _defaultExpenseCategories(),
       incomeCategories = incomeCategories ?? _defaultIncomeCategories(),
       expenses = expenses ?? _defaultExpenses(),
       incomes = incomes ?? _defaultIncomes();

  final List<CategoryItem> expenseCategories;
  final List<CategoryItem> incomeCategories;
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> incomes;
  final List<String> calls = [];
  final List<Map<String, Object?>> ledgerQueries = [];
  Map<String, Object?>? createdExpense;
  Map<String, Object?>? updatedExpense;
  Map<String, Object?>? createdIncome;
  Map<String, Object?>? savedProfile;
  Map<String, dynamic> expenseDetailData = sampleExpenseDetail;

  // 분석·리워드 상태
  Map<String, dynamic> rewardsData = rewardsFor(streak: 0, month: 0);
  Map<String, dynamic> aiOpinionData = aiStatus(remaining: 1);
  Map<String, dynamic> savingHintData = savingStatus(
    remaining: 1,
    agreed: false,
  );
  Map<String, dynamic> patternData = samplePattern;
  Map<String, dynamic> repurchaseData = sampleRepurchase;
  Map<String, dynamic> recurringData = sampleRecurring;
  Map<String, dynamic> attendanceData = attendanceFor();
  Map<String, dynamic> notificationData = {
    'push_enabled': true,
    'reminder_enabled': false,
    'reminder_time': '21:00',
    'budget_alert_enabled': true,
    'reward_alert_enabled': true,
    'marketing_agreed': false,
  };
  ApiException? generateError;
  ApiException? noSpendError;

  /// 무지출 기록에 쓸 '오늘' (없으면 실제 오늘).
  DateTime? today;
  bool failNotificationUpdate = false;
  int rewardsSeenCount = 0;
  final List<String> dismissedStores = [];
  final List<Map<String, Object?>> notificationUpdates = [];

  // ---------------------------------------------------------------- 가계부
  @override
  Future<Map<String, dynamic>> ledger({
    required String period,
    required DateTime anchor,
    String type = 'all',
    List<String> categories = const [],
    List<String> paymentMethods = const [],
  }) => ledgerFiltered(
    period: period,
    anchor: anchor,
    type: type,
    categories: categories,
    paymentMethods: paymentMethods,
  );

  @override
  Future<Map<String, dynamic>> ledgerFiltered({
    required String period,
    required DateTime anchor,
    String type = 'all',
    List<String> categories = const [],
    List<String> paymentMethods = const [],
    List<String> incomeCategories = const [],
  }) async {
    calls.add('GET /expenses');
    ledgerQueries.add({
      'type': type,
      'category': categories,
      'payment_method': paymentMethods,
      'income_category': incomeCategories,
    });
    if (incomeCategories.isNotEmpty &&
        (type == 'expense' ||
            categories.isNotEmpty ||
            paymentMethods.isNotEmpty)) {
      throw const ApiException(statusCode: 400, code: 'E605', message: '필터');
    }
    return _ledgerData(
      period,
      anchor,
      type,
      categories,
      paymentMethods,
      incomeCategories,
    );
  }

  @override
  Future<Map<String, dynamic>> ledgerSummary({
    required String period,
    required DateTime anchor,
    String type = 'all',
    List<String> categories = const [],
    List<String> paymentMethods = const [],
    List<String> incomeCategories = const [],
  }) async {
    calls.add('GET /expenses/summary');
    final data = _ledgerData(
      period,
      anchor,
      type,
      categories,
      paymentMethods,
      incomeCategories,
    );
    return {...data}..remove('days');
  }

  (DateTime, DateTime) _range(String period, DateTime anchor) {
    final day = DateTime(anchor.year, anchor.month, anchor.day);
    return switch (period) {
      'month' => (
        DateTime(anchor.year, anchor.month),
        DateTime(anchor.year, anchor.month + 1, 0),
      ),
      'week' => (
        day.subtract(Duration(days: day.weekday - 1)),
        day.add(Duration(days: 7 - day.weekday)),
      ),
      _ => (day, day),
    };
  }

  Map<String, dynamic> _ledgerData(
    String period,
    DateTime anchor,
    String type,
    List<String> categories,
    List<String> paymentMethods,
    List<String> incomeCategories,
  ) {
    final (start, end) = _range(period, anchor);
    bool inRange(String date) {
      final value = DateTime.parse(date.substring(0, 10));
      return !value.isBefore(start) && !value.isAfter(end);
    }

    final periodExpenses = expenses
        .where((e) => inRange(e['paid_at'] as String))
        .toList();
    final periodIncomes = incomes
        .where((e) => inRange(e['income_date'] as String))
        .toList();
    final filteredExpenses = type == 'income'
        ? <Map<String, dynamic>>[]
        : periodExpenses
              .where(
                (e) =>
                    (categories.isEmpty ||
                        categories.contains(e['category'])) &&
                    (paymentMethods.isEmpty ||
                        paymentMethods.contains(
                          normalizePaymentMethod(e['payment_method'] as String),
                        )),
              )
              .toList();
    final filteredIncomes = type == 'expense'
        ? <Map<String, dynamic>>[]
        : periodIncomes
              .where(
                (e) =>
                    incomeCategories.isEmpty ||
                    incomeCategories.contains(e['category']),
              )
              .toList();
    int sum(List<Map<String, dynamic>> list) =>
        list.fold(0, (total, item) => total + (item['amount'] as int));
    final dates = <String>{
      for (final e in filteredExpenses)
        (e['paid_at'] as String).substring(0, 10),
      for (final e in filteredIncomes) e['income_date'] as String,
    }.toList()..sort((a, b) => b.compareTo(a));
    return {
      'period': period,
      'start_date': start.toIso8601String().substring(0, 10),
      'end_date': end.toIso8601String().substring(0, 10),
      'total_expense_amount': sum(filteredExpenses),
      'total_income_amount': sum(filteredIncomes),
      'expense_count': filteredExpenses.length,
      'income_count': filteredIncomes.length,
      'unfiltered_total_expense_amount': type == 'income'
          ? 0
          : sum(periodExpenses),
      'unfiltered_total_income_amount': type == 'expense'
          ? 0
          : sum(periodIncomes),
      'balance': sum(filteredIncomes) - sum(filteredExpenses),
      'days': [
        for (final date in dates)
          {
            'date': date,
            'total_expense_amount': sum(
              filteredExpenses
                  .where((e) => (e['paid_at'] as String).startsWith(date))
                  .toList(),
            ),
            'expenses': filteredExpenses
                .where((e) => (e['paid_at'] as String).startsWith(date))
                .toList(),
            'incomes': [
              for (final e in filteredIncomes.where(
                (e) => e['income_date'] == date,
              ))
                {...e}..remove('income_date'),
            ],
          },
      ],
    };
  }

  // ---------------------------------------------------------------- 카테고리
  List<CategoryItem> _list(CategoryKind kind) =>
      kind == CategoryKind.expense ? expenseCategories : incomeCategories;

  @override
  Future<List<CategoryItem>> categories(CategoryKind kind) async {
    calls.add('GET /categories?type=${kind.apiValue}');
    return [
      for (final item in _list(kind))
        item.copyWith(
          recordCount: (kind == CategoryKind.expense ? expenses : incomes)
              .where((e) => e['category'] == item.name)
              .length,
        ),
    ];
  }

  @override
  Future<CategoryItem> createCategory({
    required String name,
    required String icon,
    required CategoryKind kind,
  }) async {
    calls.add('POST /categories $name $icon ${kind.apiValue}');
    if (_list(kind).any((item) => item.name == name)) {
      throw const ApiException(
        statusCode: 400,
        code: 'E512',
        message: '이미 있는 카테고리명',
      );
    }
    final item = CategoryItem(
      id: 'cat-${_list(kind).length + 1}',
      name: name,
      icon: icon,
      kind: kind,
    );
    _list(kind).add(item);
    return item;
  }

  @override
  Future<CategoryItem> updateCategory(
    CategoryItem category, {
    required String name,
    required String icon,
  }) async {
    calls.add('PATCH /categories/${category.id} $name $icon');
    final list = _list(category.kind);
    if (list.any((item) => item.name == name && item.id != category.id)) {
      throw const ApiException(
        statusCode: 400,
        code: 'E512',
        message: '이미 있는 카테고리명',
      );
    }
    final index = list.indexWhere((item) => item.id == category.id);
    final updated = CategoryItem(
      id: category.id,
      name: name,
      icon: icon,
      kind: category.kind,
    );
    list[index] = updated;
    final records = category.kind == CategoryKind.expense ? expenses : incomes;
    for (final record in records) {
      if (record['category'] == category.name) record['category'] = name;
    }
    return updated;
  }

  @override
  Future<Map<String, dynamic>> deleteCategory(
    CategoryItem category, {
    String? moveTo,
  }) async {
    calls.add(
      'DELETE /categories/${category.id}${moveTo == null ? '' : '?move_to=$moveTo'}',
    );
    _list(category.kind).removeWhere((item) => item.id == category.id);
    final records = category.kind == CategoryKind.expense ? expenses : incomes;
    var moved = 0;
    var deleted = 0;
    if (moveTo == null) {
      deleted = records.where((r) => r['category'] == category.name).length;
      records.removeWhere((r) => r['category'] == category.name);
    } else {
      for (final record in records) {
        if (record['category'] == category.name) {
          record['category'] = moveTo;
          moved++;
        }
      }
    }
    return {
      'message': '삭제했습니다',
      'moved_expense_count': moved,
      'deleted_expense_count': deleted,
      'deleted_dutch_pay_session_count': 0,
    };
  }

  // ---------------------------------------------------------------- 지출·수입
  @override
  Future<Map<String, dynamic>> createExpense(Map<String, Object?> body) async {
    calls.add('POST /expenses');
    createdExpense = body;
    return {'id': 'expense-new', ...body, 'no_spend_cancelled': false};
  }

  @override
  Future<Map<String, dynamic>> expenseDetail(String id) async {
    calls.add('GET /expenses/$id');
    return expenseDetailData;
  }

  @override
  Future<Map<String, dynamic>> updateExpense(
    String id,
    Map<String, Object?> body,
  ) async {
    calls.add('PATCH /expenses/$id');
    updatedExpense = body;
    return {...expenseDetailData, ...body};
  }

  @override
  Future<Map<String, dynamic>> createIncome(Map<String, Object?> body) async {
    calls.add('POST /incomes');
    createdIncome = body;
    return {'id': 'income-new', ...body};
  }

  @override
  Future<Map<String, dynamic>> profile() async => {
    'nickname': '소비로그',
    'email': 'test@sobilog.kr',
    'provider': 'apple',
    'bank_name': null,
    'bank_account_number': null,
  };

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, Object?> body) async {
    savedProfile = body;
    return {...body};
  }

  @override
  Future<Map<String, dynamic>> home() async => {
    'summary': {
      'has_records': true,
      'total_expense_amount': 128500,
      'year': 2026,
      'month': 8,
    },
    'recent': {'entries': const []},
  };

  @override
  Future<Map<String, dynamic>> analysis({
    required int year,
    required int month,
  }) async => {
    'year': year,
    'month': month,
    'total_expense_amount': 128500,
    'category_breakdown': const [],
    'goal': null,
  };

  @override
  Future<Map<String, dynamic>> uploadExpensePhoto(
    String expenseId,
    String imagePath,
  ) async => {'photos': const []};

  @override
  Future<Map<String, dynamic>> deleteExpensePhoto(
    String expenseId,
    String photoId,
  ) async => {};

  // ---------------------------------------------------------------- 출석·알림
  @override
  Future<Map<String, dynamic>> attendance({DateTime? month}) async {
    calls.add(
      'GET /mypage/attendance${month == null ? '' : '?month=${month.year}-${month.month}'}',
    );
    return attendanceData;
  }

  @override
  Future<void> markNoSpendDay() async {
    calls.add('POST /mypage/attendance/no-spend-day');
    if (noSpendError case final error?) throw error;
    final now = this.today ?? DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    attendanceData = {
      ...attendanceData,
      'current_streak': (attendanceData['current_streak'] as int) + 1,
      'this_month_recorded_days':
          (attendanceData['this_month_recorded_days'] as int) + 1,
      'this_month_no_spend_days':
          (attendanceData['this_month_no_spend_days'] as int) + 1,
      'calendar': [
        ...(attendanceData['calendar'] as List),
        {'date': today, 'status': 'no_spend'},
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> notificationSettings() async {
    calls.add('GET /mypage/notifications');
    return notificationData;
  }

  @override
  Future<Map<String, dynamic>> updateNotificationSettings(
    Map<String, Object?> body,
  ) async {
    calls.add('PATCH /mypage/notifications');
    notificationUpdates.add(body);
    if (failNotificationUpdate) {
      throw const ApiException(statusCode: 500, message: '오류');
    }
    notificationData = {...notificationData, ...body};
    return notificationData;
  }

  // ---------------------------------------------------------------- 분석·리워드
  @override
  Future<Map<String, dynamic>> rewards() async {
    calls.add('GET /mypage/rewards');
    return rewardsData;
  }

  @override
  Future<void> markRewardsSeen() async {
    calls.add('POST /mypage/rewards/seen');
    rewardsSeenCount++;
    rewardsData = {
      ...rewardsData,
      'new_count': 0,
      'rewards': [
        for (final item in rewardsData['rewards'] as List)
          {...item as Map<String, dynamic>, 'is_new': false},
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> aiOpinionStatus() async {
    calls.add('GET /analysis/ai-opinion');
    return aiOpinionData;
  }

  @override
  Future<Map<String, dynamic>> generateAiOpinion() async {
    calls.add('POST /analysis/ai-opinion');
    if (generateError case final error?) throw error;
    final result = sampleOpinionResult;
    aiOpinionData = {'quota': quota(remaining: 0), 'latest': result};
    return {'quota': quota(remaining: 0), 'result': result};
  }

  @override
  Future<Map<String, dynamic>> savingHintStatus() async {
    calls.add('GET /analysis/saving-hint');
    return savingHintData;
  }

  @override
  Future<Map<String, dynamic>> generateSavingHint() async {
    calls.add('POST /analysis/saving-hint');
    if (generateError case final error?) throw error;
    final consent = savingHintData['consent'] as Map<String, dynamic>;
    if (consent['agreed'] != true) {
      throw const ApiException(statusCode: 403, code: 'E715', message: '동의 필요');
    }
    savingHintData = {
      ...savingHintData,
      'quota': quota(remaining: 0),
      'latest': sampleSavingResult,
    };
    return {'quota': quota(remaining: 0), 'result': sampleSavingResult};
  }

  @override
  Future<Map<String, dynamic>> agreeSavingHintConsent() async {
    calls.add('POST /analysis/saving-hint/consent');
    final consent = {
      'agreed': true,
      'agreed_at': '2026-11-14T12:00:00+09:00',
      'required': true,
    };
    savingHintData = {...savingHintData, 'consent': consent};
    return {'consent': consent};
  }

  @override
  Future<Map<String, dynamic>> withdrawSavingHintConsent() async {
    calls.add('DELETE /analysis/saving-hint/consent');
    final consent = {'agreed': false, 'agreed_at': null, 'required': true};
    savingHintData = {...savingHintData, 'consent': consent};
    return {'consent': consent};
  }

  @override
  Future<Map<String, dynamic>> pattern() async {
    calls.add('GET /analysis/pattern');
    return patternData;
  }

  @override
  Future<Map<String, dynamic>> repurchase() async {
    calls.add('GET /analysis/repurchase');
    return repurchaseData;
  }

  @override
  Future<Map<String, dynamic>> recurringExpenses() async {
    calls.add('GET /analysis/recurring-expenses');
    return recurringData;
  }

  @override
  Future<void> dismissRecurringExpense(String storeName) async {
    calls.add('POST /analysis/recurring-expenses/dismiss $storeName');
    dismissedStores.add(storeName);
    final items = [
      for (final item in recurringData['items'] as List)
        if ((item as Map)['store_name'] != storeName) item,
    ];
    recurringData = {
      ...recurringData,
      'items': items,
      'monthly_fixed_total': items.fold<int>(
        0,
        (sum, item) => sum + (item['monthly_equivalent_amount'] as int),
      ),
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ------------------------------------------------------------------ 샘플 데이터
List<CategoryItem> _defaultExpenseCategories() => [
  ...defaultCategories(CategoryKind.expense),
  const CategoryItem(
    id: 'cat-hobby',
    name: '취미',
    icon: 'photo',
    kind: CategoryKind.expense,
  ),
];

List<CategoryItem> _defaultIncomeCategories() => [
  ...defaultCategories(CategoryKind.income),
  const CategoryItem(
    id: 'cat-alba',
    name: '알바',
    icon: 'store',
    kind: CategoryKind.income,
  ),
];

List<Map<String, dynamic>> _defaultExpenses() => [
  _expense('e1', '아주대학교 카페', '카페', '체크카드', 4500, '2026-08-19T10:30:00'),
  _expense('e2', '스타벅스 아주대점', '카페', '신용카드', 6500, '2026-08-19T15:10:00'),
  _expense('e3', '학생식당', '식비', '현금', 5500, '2026-08-21T12:10:00'),
  _expense('e4', '김밥천국', '식비', '체크카드', 12400, '2026-08-25T19:20:00'),
  _expense('e5', '사진관', '취미', '간편결제', 30000, '2026-08-22T14:00:00'),
  _expense('e6', '카메라 필름', '취미', '간편결제', 18000, '2026-08-24T18:00:00'),
  _expense('e7', '앨범 인화', '취미', '계좌이체', 12000, '2026-08-26T11:00:00'),
  _expense('e8', '버스', '교통', '체크카드', 1500, '2026-08-23T08:40:00'),
];

Map<String, dynamic> _expense(
  String id,
  String store,
  String category,
  String method,
  int amount,
  String paidAt,
) => {
  'id': id,
  'store_name': store,
  'category': category,
  'payment_method': method,
  'amount': amount,
  'item_count': 1,
  'representative_item_name': store,
  'paid_at': '$paidAt+09:00',
};

List<Map<String, dynamic>> _defaultIncomes() => [
  {
    'id': 'i1',
    'category': '급여',
    'amount': 320000,
    'memo': '근로장학금',
    'income_date': '2026-08-23',
  },
  {
    'id': 'i2',
    'category': '용돈',
    'amount': 300000,
    'memo': '용돈',
    'income_date': '2026-08-01',
  },
];

const sampleExpenseDetail = <String, dynamic>{
  'id': 'expense-1',
  'store_name': '아주대학교 카페',
  'paid_at': '2026-09-01T15:20:00+09:00',
  'category': '카페',
  'payment_method': '현금',
  'total_amount': 40500,
  'memo': '과제하다가 친구랑 마심',
  'receipt_image_url': 'https://example.com/receipt.jpg',
  'photos': [],
  'items': [
    {'item_name': '아메리카노', 'quantity': 3, 'unit_price': 4500, 'amount': 13500},
    {'item_name': '아메리카노', 'quantity': 3, 'unit_price': 4500, 'amount': 13500},
    {'item_name': '아메리카노', 'quantity': 3, 'unit_price': 4500, 'amount': 13500},
  ],
  'dutch_pay_session_id': null,
  'dutch_pay_status': null,
};

Map<String, dynamic> quota({required int remaining}) => {
  'month': '2026-11',
  'base_limit': 1,
  'bonus_granted': false,
  'limit': 1,
  'used': 1 - remaining,
  'remaining': remaining,
  'bonus_progress_current': 0,
  'bonus_progress_target': 0,
  'next_reset_date': '2026-12-01',
};

const sampleOpinionResult = <String, dynamic>{
  'id': 'op-1',
  'target_month': '2026-10',
  'created_at': '2026-11-14T12:00:00+09:00',
  'content': {
    'summary': '지난달에는 식비와 카페 지출이 전체의 절반을 넘었어요. 특히 평일 오후에 카페 결제가 자주 반복됐어요.',
    'improvement_points': [
      '카페 지출이 한 달에 18번으로 가장 잦았어요.',
      '배달 음식 결제가 주말 저녁에 몰려 있어요.',
    ],
    'action_suggestions': [
      '평일 오후 카페는 주 3회로 정해 보세요.',
      '주말 저녁 한 끼는 장을 봐서 해결해 보세요.',
    ],
  },
};

Map<String, dynamic> aiStatus({required int remaining, bool latest = false}) =>
    {
      'quota': quota(remaining: remaining),
      'latest': latest ? sampleOpinionResult : null,
    };

const sampleSavingResult = <String, dynamic>{
  'id': 'sh-1',
  'target_month': '2026-10',
  'created_at': '2026-11-14T12:00:00+09:00',
  'content': {
    'categories': [
      {
        'category': '식비',
        'rank': 1,
        'tip': '장보기는 주 1회로 모아서 해보세요.',
        'discount_method': '이마트 수원점에서 이번 주 신선식품 1+1 행사를 하고 있어요.',
        'store_address': '경기 수원시 영통구 매영로 150',
        'store_link': null,
      },
      {
        'category': '카페',
        'rank': 2,
        'tip': '텀블러를 쓰면 할인받을 수 있어요.',
        'discount_method': '온라인몰에서 원두 대용량 구매 시 20% 할인돼요.',
        'store_address': null,
        'store_link': 'https://example.com/coffee',
      },
    ],
    'disclaimer': '할인 정보는 실제와 다를 수 있어요. 매장에서 확인해 주세요.',
    'search_suggestions': [
      {
        'rendered_content': '<div>Google</div>',
        'queries': ['스타벅스 영통점 텀블러 할인', '생수 2L 묶음 할인'],
      },
    ],
  },
};

Map<String, dynamic> savingStatus({
  required int remaining,
  required bool agreed,
  bool latest = false,
}) => {
  'consent': {
    'agreed': agreed,
    'agreed_at': agreed ? '2026-11-01T10:00:00+09:00' : null,
    'required': true,
  },
  'quota': quota(remaining: remaining),
  'latest': latest ? sampleSavingResult : null,
};

Map<String, dynamic> rewardsFor({
  required int streak,
  required int month,
  bool streakNew = false,
  bool monthNew = false,
}) => {
  'rewards': [
    {
      'key': 'streak_7',
      'title': '연속 7일 기록',
      'unlock_target': 'analysis_pattern',
      'unlock_description': '소비 패턴 리포트',
      'earned': streak >= 7,
      'unlocked': streak >= 7,
      'earned_date': streak >= 7 ? '2026-11-10' : null,
      'progress_current': streak >= 7 ? 7 : streak,
      'progress_target': 7,
      'is_new': streakNew,
    },
    {
      'key': 'month_20',
      'title': '한 달 20일 기록',
      'unlock_target': 'analysis_repeat',
      'unlock_description': '반복 지출 분석',
      'earned': month >= 20,
      'unlocked': month >= 20,
      'earned_date': month >= 20 ? '2026-11-14' : null,
      'progress_current': month >= 20 ? 20 : month,
      'progress_target': 20,
      'is_new': monthNew,
    },
  ],
  'new_count': (streakNew ? 1 : 0) + (monthNew ? 1 : 0),
};

Map<String, dynamic> attendanceFor({
  int current = 0,
  int max = 0,
  int recorded = 0,
  int noSpend = 0,
  List<Map<String, dynamic>> calendar = const [],
}) => {
  'current_streak': current,
  'max_streak': max,
  'this_month_recorded_days': recorded,
  'this_month_recording_rate': 0.0,
  'this_month_no_spend_days': noSpend,
  'calendar': calendar,
};

const samplePattern = <String, dynamic>{
  'start_month': '2026-09',
  'end_month': '2026-11',
  'has_data': true,
  'months_with_data': 3,
  'total_expense_amount': 486300,
  'weekday_distribution': [
    {'weekday': '월', 'amount': 48000, 'count': 6, 'percentage': 7.0},
    {'weekday': '화', 'amount': 0, 'count': 0, 'percentage': 0.0},
    {'weekday': '수', 'amount': 48000, 'count': 5, 'percentage': 7.0},
    {'weekday': '목', 'amount': 32000, 'count': 4, 'percentage': 5.0},
    {'weekday': '금', 'amount': 128000, 'count': 10, 'percentage': 18.0},
    {'weekday': '토', 'amount': 192000, 'count': 9, 'percentage': 28.0},
    {'weekday': '일', 'amount': 149300, 'count': 8, 'percentage': 22.0},
  ],
  'time_slot_distribution': [
    {
      'slot': 'dawn',
      'label': '새벽(0~6시)',
      'amount': 19000,
      'count': 2,
      'percentage': 4.0,
    },
    {
      'slot': 'morning',
      'label': '오전(6~12시)',
      'amount': 68000,
      'count': 11,
      'percentage': 14.0,
    },
    {
      'slot': 'afternoon',
      'label': '오후(12~18시)',
      'amount': 155600,
      'count': 20,
      'percentage': 32.0,
    },
    {
      'slot': 'evening',
      'label': '저녁·밤(18~24시)',
      'amount': 243700,
      'count': 16,
      'percentage': 50.0,
    },
  ],
  'top_merchants': [
    {'store_name': 'CU 아주대점', 'visit_count': 12, 'total_amount': 48200},
    {'store_name': '스타벅스 영통점', 'visit_count': 8, 'total_amount': 41600},
    {'store_name': '이마트24', 'visit_count': 6, 'total_amount': 21300},
    {'store_name': '김밥천국', 'visit_count': 5, 'total_amount': 32500},
    {'store_name': '다이소', 'visit_count': 4, 'total_amount': 18000},
  ],
  'top_items': [],
  'category_trend': [],
  'payment_method_share': [
    {'payment_method': '현금', 'amount': 24300, 'count': 5, 'percentage': 5.0},
    {
      'payment_method': '체크카드',
      'amount': 218800,
      'count': 22,
      'percentage': 45.0,
    },
    {
      'payment_method': '신용카드',
      'amount': 72900,
      'count': 10,
      'percentage': 15.0,
    },
    {
      'payment_method': '간편결제',
      'amount': 145900,
      'count': 9,
      'percentage': 30.0,
    },
    {'payment_method': '계좌이체', 'amount': 14600, 'count': 2, 'percentage': 3.0},
    {'payment_method': '기타', 'amount': 9800, 'count': 1, 'percentage': 2.0},
  ],
  'summary': ['토요일에 가장 많이 썼어요', '저녁·밤 시간대에 절반을 썼어요', 'CU 아주대점을 가장 자주 갔어요'],
};

Map<String, dynamic> _repeatItem(
  String name,
  int count,
  num? interval,
  int perPurchase,
  int? monthly,
  String last,
  List<List<Object>> purchases,
) => {
  'item_name': name,
  'purchase_count': count,
  'total_quantity': count,
  'average_interval_days': interval,
  'average_amount_per_purchase': perPurchase,
  'monthly_equivalent_amount': monthly,
  'last_purchased_date': last,
  'purchases': [
    for (final p in purchases)
      {'expense_id': p[0], 'date': p[1], 'amount': p[2]},
  ],
};

final sampleRepurchase = <String, dynamic>{
  'start_month': '2026-09',
  'end_month': '2026-11',
  'has_data': true,
  'monthly_repeat_total': 32000,
  'items': [
    _repeatItem('아메리카노', 7, 4.0, 2100, 15800, '2026-11-04', [
      ['expense-1', '2026-11-04', 2100],
      ['expense-2', '2026-10-31', 2100],
    ]),
    _repeatItem('생수 2L', 5, 6.0, 1900, 9500, '2026-11-03', [
      ['expense-3', '2026-11-03', 1900],
      ['expense-4', '2026-10-28', 1900],
      ['expense-5', '2026-10-21', 1900],
    ]),
    _repeatItem('삼각김밥', 9, 9.0, 1350, 4500, '2026-11-02', [
      ['expense-6', '2026-11-02', 1350],
    ]),
    _repeatItem('컵라면', 2, null, 1300, null, '2026-11-01', [
      ['expense-7', '2026-11-01', 1300],
    ]),
    _repeatItem('바나나우유', 4, 12.0, 1700, 2100, '2026-10-30', [
      ['expense-8', '2026-10-30', 1700],
    ]),
    _repeatItem('휴지', 3, 20.0, 3900, 1200, '2026-10-25', [
      ['expense-9', '2026-10-25', 3900],
    ]),
    _repeatItem('초코바', 3, 15.0, 1200, 900, '2026-10-22', [
      ['expense-10', '2026-10-22', 1200],
    ]),
    _repeatItem('물티슈', 2, 25.0, 2500, 600, '2026-10-20', [
      ['expense-11', '2026-10-20', 2500],
    ]),
  ],
};

const sampleRecurring = <String, dynamic>{
  'has_data': true,
  'monthly_fixed_total': 27000,
  'this_month_total_amount': 150000,
  'items': [
    {
      'store_name': '넷플릭스',
      'amount': 13500,
      'cycle': '매월',
      'average_interval_days': 30.0,
      'next_expected_date': '2026-11-18',
      'monthly_equivalent_amount': 13500,
      'purchase_count': 3,
      'purchases': [
        {'expense_id': 'expense-12', 'date': '2026-10-18', 'amount': 13500},
      ],
    },
    {
      'store_name': '학교 앞 세탁소',
      'amount': 3000,
      'cycle': '매주',
      'average_interval_days': 7.0,
      'next_expected_date': '2026-11-10',
      'monthly_equivalent_amount': 13500,
      'purchase_count': 6,
      'purchases': [
        {'expense_id': 'expense-13', 'date': '2026-11-03', 'amount': 3000},
      ],
    },
  ],
  'disclaimer': '결제 간격이 일정한 내역만 찾아요.',
};
