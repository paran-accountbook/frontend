/// 분석_003~008, 마이_003: AI 분석·리워드 API.
abstract interface class InsightService {
  /// GET /mypage/rewards
  Future<Map<String, dynamic>> rewards();

  /// POST /mypage/rewards/seen
  Future<void> markRewardsSeen();

  /// GET /analysis/ai-opinion
  Future<Map<String, dynamic>> aiOpinionStatus();

  /// POST /analysis/ai-opinion (month 생략 = 지난달)
  Future<Map<String, dynamic>> generateAiOpinion();

  /// GET /analysis/saving-hint
  Future<Map<String, dynamic>> savingHintStatus();

  /// POST /analysis/saving-hint
  Future<Map<String, dynamic>> generateSavingHint();

  /// POST /analysis/saving-hint/consent
  Future<Map<String, dynamic>> agreeSavingHintConsent();

  /// DELETE /analysis/saving-hint/consent
  Future<Map<String, dynamic>> withdrawSavingHintConsent();

  /// GET /analysis/pattern
  Future<Map<String, dynamic>> pattern();

  /// GET /analysis/repurchase
  Future<Map<String, dynamic>> repurchase();

  /// GET /analysis/recurring-expenses
  Future<Map<String, dynamic>> recurringExpenses();

  /// POST /analysis/recurring-expenses/dismiss
  Future<void> dismissRecurringExpense(String storeName);
}

/// 보상 목록에서 key 로 항목을 찾는다 (streak_7 / month_20).
Map<String, dynamic>? rewardByKey(Map<String, dynamic>? rewards, String key) {
  final list = rewards?['rewards'];
  if (list is! List) return null;
  for (final item in list) {
    if (item is Map<String, dynamic> && item['key'] == key) return item;
  }
  return null;
}
