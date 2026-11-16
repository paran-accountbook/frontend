import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/app_category_icon.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/p2_widgets.dart';
import '../../finance/data/finance_service.dart';
import '../data/insight_service.dart';
import '../../home/presentation/home_screen.dart';
import '../../ledger/presentation/ledger_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../register/presentation/register_type_screen.dart';
import 'ai_analysis_section.dart';
import 'analysis_goal_screen.dart';

/// 소비 분석 위쪽 탭.
enum AnalysisTab { report, ai }

class AnalysisOverviewScreen extends StatefulWidget {
  const AnalysisOverviewScreen({
    super.key,
    this.onNavigationSelected,
    this.financeService,
    this.initialMonth,
    this.initialTab = AnalysisTab.report,
    this.insightService,
  });
  final ValueChanged<int>? onNavigationSelected;
  final FinanceService? financeService;
  final DateTime? initialMonth;
  final AnalysisTab initialTab;

  /// 없으면 financeService 가 InsightService 를 구현할 때 그것을 쓴다.
  final InsightService? insightService;
  @override
  State<AnalysisOverviewScreen> createState() => _AnalysisOverviewScreenState();
}

class _AnalysisOverviewScreenState extends State<AnalysisOverviewScreen> {
  late DateTime _month;
  Map<String, dynamic>? _report;
  late bool _isLoading;
  String? _error;
  late AnalysisTab _tab = widget.initialTab;

  InsightService? get _insight =>
      widget.insightService ??
      switch (widget.financeService) {
        final InsightService service => service,
        _ => null,
      };

  @override
  void initState() {
    super.initState();
    _month =
        widget.initialMonth ??
        (widget.financeService == null ? DateTime(2026, 8) : DateTime.now());
    _isLoading = widget.financeService != null;
    _load();
  }

  Future<void> _load() async {
    final service = widget.financeService;
    if (service == null) return;
    setState(() => _isLoading = true);
    try {
      setState(() => _error = null);
      final report = await service.analysis(
        year: _month.year,
        month: _month.month,
      );
      if (mounted) setState(() => _report = report);
    } catch (_) {
      if (mounted && _report == null) {
        setState(() => _error = '소비 분석을 불러오지 못했습니다.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _moveMonth(int direction) {
    setState(() => _month = DateTime(_month.year, _month.month + direction));
    _load();
  }

  Future<void> _openGoalEditor() async {
    final service = widget.financeService;
    if (service == null) return;
    final goal = _report?['goal'] as Map<String, dynamic>?;
    final currentAmount = goal?['amount'] as int? ?? 0;
    final income = _report?['total_income_amount'] as int?;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnalysisGoalScreen(
          year: _month.year,
          month: _month.month,
          initialAmount: currentAmount,
          monthlyIncome: income,
          financeService: service,
          onSaved: (_) => _load(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasGoalLayout =
        widget.financeService == null || _report?['goal'] != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: _tab == AnalysisTab.ai
                ? _buildAiTab()
                : ScrollableDesignCanvas(
                    width: 402,
                    height: hasGoalLayout ? 1723 : 1808,
                    child: _buildCanvas(),
                  ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: AppBottomNavigation(
                selectedIndex: 3,
                onSelected: (index) => _navigate(context, index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas() => Stack(
    children: [
      const ColoredBox(color: AppColors.background),
      Positioned(
        left: 24,
        top: 125,
        child: Text(
          '소비분석',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 27,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Positioned(
        left: 24,
        top: 192,
        width: 354,
        child: Align(alignment: Alignment.centerLeft, child: _tabs()),
      ),
      Positioned(
        left: 24,
        top: 265,
        width: 354,
        child: _MonthSelector(
          month: _month,
          onPrevious: () => _moveMonth(-1),
          onNext: () => _moveMonth(1),
          canMoveNext: _month.isBefore(
            DateTime(DateTime.now().year, DateTime.now().month),
          ),
        ),
      ),
      Positioned(left: 24, top: 322, width: 354, child: _content()),
    ],
  );

  Widget _tabs() => Row(
    children: [
      _TabChip(
        key: const Key('analysis-tab-report'),
        label: '리포트',
        selected: _tab == AnalysisTab.report,
        onTap: () => setState(() => _tab = AnalysisTab.report),
      ),
      const SizedBox(width: 8),
      _TabChip(
        key: const Key('analysis-tab-ai'),
        label: 'AI분석',
        selected: _tab == AnalysisTab.ai,
        onTap: () => setState(() => _tab = AnalysisTab.ai),
      ),
    ],
  );

  /// 분석_008-01: [AI분석] 탭. 뒤로가기는 [리포트] 탭으로 돌아간다.
  Widget _buildAiTab() {
    final insight = _insight;
    return P2DesignFrame(
      child: SingleChildScrollView(
        key: const Key('analysis-ai-scroll'),
        padding: const EdgeInsets.fromLTRB(24, 50, 24, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            P2BackButton(
              onTap: () => setState(() => _tab = AnalysisTab.report),
            ),
            const SizedBox(height: 41),
            const Text(
              '소비 분석',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 27,
                fontWeight: FontWeight.w700,
                height: 32 / 27,
              ),
            ),
            const SizedBox(height: 35),
            if (insight == null)
              _tabs()
            else
              AiAnalysisSection(
                service: insight,
                financeService: widget.financeService,
                tabs: _tabs(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _content() => _isLoading
      ? const _AnalysisSkeleton()
      : _error != null && _report == null
      ? _AnalysisLoadError(message: _error!, onRetry: _load)
      : _Report(
          data: _report,
          month: _month.month,
          preview: widget.financeService == null,
          onEditGoal: () => _openGoalEditor(),
        );

  void _navigate(BuildContext context, int index) {
    if (widget.onNavigationSelected case final callback?) {
      callback(index);
      return;
    }
    final Widget? page = switch (index) {
      0 => HomeScreen(financeService: widget.financeService),
      1 => LedgerScreen(financeService: widget.financeService),
      2 => RegisterTypeScreen(financeService: widget.financeService),
      4 => ProfileScreen(financeService: widget.financeService),
      _ => null,
    };
    if (page == null) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _AnalysisSkeleton extends StatelessWidget {
  const _AnalysisSkeleton();

  @override
  Widget build(BuildContext context) => const AppSkeleton(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSkeletonBox(width: 354, height: 7),
        SizedBox(height: 22),
        AppSkeletonBox(width: 58, height: 14),
        SizedBox(height: 8),
        AppSkeletonBox(width: 148, height: 30),
        SizedBox(height: 12),
        AppSkeletonBox(width: 112, height: 14),
        SizedBox(height: 28),
        _AnalysisSkeletonMetric(),
        SizedBox(height: 18),
        _AnalysisSkeletonMetric(),
        SizedBox(height: 18),
        _AnalysisSkeletonMetric(),
        SizedBox(height: 28),
        AppSkeletonBox(width: 354, height: 7),
        SizedBox(height: 28),
        AppSkeletonBox(width: 90, height: 14),
        SizedBox(height: 24),
        AppSkeletonBox(width: 354, height: 16),
        SizedBox(height: 24),
        AppSkeletonList(rows: 5),
      ],
    ),
  );
}

class _AnalysisSkeletonMetric extends StatelessWidget {
  const _AnalysisSkeletonMetric();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      AppSkeletonBox(width: 88, height: 14),
      AppSkeletonBox(width: 96, height: 20),
    ],
  );
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 92,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFA8A3FF) : AppColors.selected,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline, width: .5),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          color: selected ? const Color(0xFF1B1B1B) : AppColors.text50,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.canMoveNext,
  });
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canMoveNext;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      GestureDetector(
        onTap: onPrevious,
        child: Transform.rotate(
          angle: 3.141592653589793,
          child: SvgPicture.asset(
            AppAssets.monthArrowActive,
            width: 10,
            height: 12,
          ),
        ),
      ),
      Row(
        children: [
          Text(
            '${month.year}',
            style: TextStyle(
              color: AppColors.text,
              fontFamily: 'Amarante',
              fontSize: 24,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            '년',
            style: TextStyle(color: AppColors.text, fontSize: 14),
          ),
          const SizedBox(width: 18),
          Text(
            '${month.month}',
            style: TextStyle(
              color: AppColors.text,
              fontFamily: 'Amarante',
              fontSize: 24,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            '월',
            style: TextStyle(color: AppColors.text, fontSize: 14),
          ),
        ],
      ),
      GestureDetector(
        key: const ValueKey('analysis-next-month'),
        onTap: canMoveNext ? onNext : null,
        child: SvgPicture.asset(
          canMoveNext ? AppAssets.monthArrowActive : AppAssets.monthArrowDim,
          width: 10,
          height: 12,
        ),
      ),
    ],
  );
}

class _Report extends StatelessWidget {
  const _Report({
    this.data,
    required this.month,
    this.preview = false,
    this.onEditGoal,
  });
  final Map<String, dynamic>? data;
  final int month;
  final bool preview;
  final VoidCallback? onEditGoal;
  static const categories = [
    ('식비', '53%', '4,500'),
    ('쇼핑', '30%', '4,500'),
    ('카페', '8%', '4,500'),
    ('의료', '4%', '4,500'),
    ('교통', '3%', '4,500'),
    ('문화', '2%', '4,500'),
    ('교육', '2%', '4,500'),
    ('기타', '2%', '4,500'),
  ];
  @override
  Widget build(BuildContext context) {
    final total =
        data?['total_expense_amount'] as int? ?? (preview ? 150000 : 0);
    final daily =
        data?['daily_average_expense'] as int? ?? (preview ? 40000 : 0);
    final income =
        data?['total_income_amount'] as int? ?? (preview ? 150000 : 0);
    final incomeCount =
        data?['income_count'] as int? ?? ((preview || income > 0) ? 1 : 0);
    final balance = data?['balance'] as int? ?? (preview ? 150000 : 0);
    final change = data?['change_amount'] as int? ?? (preview ? 2500 : 0);
    final changeRate = data?['change_rate'] as num? ?? (preview ? 12 : 0);
    final remoteCategories = (data?['category_breakdown'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    final visibleCategories = data == null && preview
        ? categories
        : (remoteCategories ?? const <Map<String, dynamic>>[])
              .map(
                (item) => (
                  item['category'] as String? ?? '기타',
                  '${item['percentage'] ?? 0}%',
                  _formatAmount(item['amount'] as int? ?? 0),
                ),
              )
              .toList();
    final remoteGoal = data?['goal'] as Map<String, dynamic>?;
    final hasGoal = remoteGoal != null || preview;
    final goalAmount = remoteGoal?['amount'] as int? ?? (preview ? 563700 : 0);
    final goalUsageRate =
        remoteGoal?['usage_rate'] as num? ?? (preview ? 20 : 0);
    final remainingBudget =
        remoteGoal?['remaining_budget'] as int? ??
        (preview
            ? 413700
            : hasGoal
            ? goalAmount - total
            : 0);
    final dailyBudget =
        remoteGoal?['daily_budget_remaining'] as int? ?? (preview ? 17200 : 0);
    final today = DateTime.now();
    final remainingDays =
        remoteGoal?['remaining_days'] as int? ??
        (preview
            ? 24
            : data != null &&
                  data?['year'] == today.year &&
                  data?['month'] == today.month
            ? DateTime(today.year, today.month + 1, 0).day - today.day + 1
            : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Asterisks(),
        const SizedBox(height: 14),
        const Text(
          '총 지출',
          style: TextStyle(color: AppColors.text50, fontSize: 14),
        ),
        const SizedBox(height: 5),
        _PriceText(
          value: _formatAmount(total),
          size: 30,
          wonWidth: 20,
          wonHeight: 22,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _ChangePrice(change: change),
            const SizedBox(width: 12),
            Text(
              '전월 대비 ${changeRate.toString()}%',
              style: const TextStyle(color: AppColors.text50, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _Metric(label: '일 평균 지출액', value: _formatAmount(daily)),
        if (incomeCount > 0) ...[
          _Metric(label: '총 수입', value: _formatAmount(income)),
          _Metric(
            label: '잔액',
            value: '${balance >= 0 ? '+' : ''}${_formatAmount(balance)}',
            accent: true,
          ),
        ],
        const SizedBox(height: 16),
        const _Asterisks(),
        const SizedBox(height: 24),
        const Text(
          '카테고리별 비중',
          style: TextStyle(color: AppColors.text50, fontSize: 12),
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: _CategoryBar(categories: visibleCategories),
        ),
        const SizedBox(height: 16),
        ...visibleCategories.map(
          (item) => SizedBox(
            height: 73,
            child: Row(
              children: [
                AppCategoryIcon(category: item.$1),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        item.$2,
                        style: const TextStyle(
                          color: AppColors.text50,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _PriceText(value: item.$3, size: 20),
              ],
            ),
          ),
        ),
        const _Asterisks(),
        const SizedBox(height: 24),
        _GoalReportSection(
          month: month,
          hasGoal: hasGoal,
          goalAmount: goalAmount,
          spentAmount: total,
          usageRate: goalUsageRate,
          remainingBudget: remainingBudget,
          remainingDays: remainingDays,
          dailyBudget: dailyBudget,
          onEditGoal: onEditGoal,
        ),
      ],
    );
  }
}

class _GoalReportSection extends StatelessWidget {
  const _GoalReportSection({
    required this.month,
    required this.hasGoal,
    required this.goalAmount,
    required this.spentAmount,
    required this.usageRate,
    required this.remainingBudget,
    required this.remainingDays,
    required this.dailyBudget,
    this.onEditGoal,
  });

  final int month;
  final bool hasGoal;
  final int goalAmount;
  final int spentAmount;
  final num usageRate;
  final int remainingBudget;
  final int? remainingDays;
  final int dailyBudget;
  final VoidCallback? onEditGoal;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (!hasGoal) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  '이번 달 지출 목표를 등록하면 하루 사용 가능 금액을 확인할 수 있어요',
                  style: TextStyle(
                    color: AppColors.text80,
                    fontSize: 12,
                    height: 1.51,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                key: const ValueKey('analysis-register-goal'),
                onTap: onEditGoal,
                child: Container(
                  width: 118,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.main,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.text20, width: .5),
                  ),
                  child: const Text(
                    '목표 등록하기',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
      ],
      GestureDetector(
        onTap: hasGoal ? onEditGoal : null,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$month월 지출 목표',
                    style: const TextStyle(
                      color: AppColors.text50,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_formatAmount(hasGoal ? goalAmount : 0)}원 중 '
                        '${_formatAmount(hasGoal ? spentAmount : 0)}원 사용',
                        maxLines: 1,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${hasGoal ? usageRate : 0}%',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontFamily: 'Amarante',
                    fontSize: 20,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: LinearProgressIndicator(
                    value: hasGoal
                        ? (usageRate / 100).clamp(0, 1).toDouble()
                        : 0,
                    minHeight: 15,
                    color: AppColors.main,
                    backgroundColor: AppColors.selected,
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _GoalBudgetCard(
              hasGoal: hasGoal,
              remainingBudget: hasGoal ? remainingBudget : 0,
              remainingDays: hasGoal ? remainingDays : null,
              dailyBudget: hasGoal ? dailyBudget : 0,
            ),
          ],
        ),
      ),
    ],
  );
}

class _GoalBudgetCard extends StatelessWidget {
  const _GoalBudgetCard({
    required this.hasGoal,
    required this.remainingBudget,
    required this.remainingDays,
    required this.dailyBudget,
  });

  final bool hasGoal;
  final int remainingBudget;
  final int? remainingDays;
  final int dailyBudget;

  @override
  Widget build(BuildContext context) {
    final daysText = hasGoal && remainingDays != null
        ? '$remainingDays일'
        : '-일';
    final calculation = hasGoal && remainingDays != null
        ? '남은 예산 ${_formatAmount(remainingBudget)}원 ÷ $daysText'
        : '남은 예산 -원 ÷ -일';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                _GoalMetricRow(label: '남은 예산', amount: remainingBudget),
                const SizedBox(height: 16),
                _GoalMetricRow(
                  label: '남은 일수',
                  remainingDays: hasGoal ? remainingDays : null,
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: .5, color: AppColors.text20),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '하루 사용 가능',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        calculation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text80,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _PriceText(
                  value: _formatAmount(dailyBudget),
                  size: 20,
                  accent: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalMetricRow extends StatelessWidget {
  const _GoalMetricRow({required this.label, this.amount, this.remainingDays});

  final String label;
  final int? amount;
  final int? remainingDays;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppColors.text50, fontSize: 14),
      ),
      if (amount case final value?)
        _PriceText(value: _formatAmount(value), size: 20)
      else
        Row(
          children: [
            const Text(
              '오늘 포함',
              style: TextStyle(color: AppColors.text50, fontSize: 12),
            ),
            const SizedBox(width: 7),
            Text(
              remainingDays?.toString() ?? '-',
              style: const TextStyle(
                color: AppColors.text,
                fontFamily: 'Amarante',
                fontSize: 20,
              ),
            ),
            const Text(
              '일',
              style: TextStyle(color: AppColors.text, fontSize: 20),
            ),
          ],
        ),
    ],
  );
}

class _BarSegment extends StatelessWidget {
  const _BarSegment({required this.flex, required this.color});

  final int flex;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: ColoredBox(color: color, child: const SizedBox(height: 16)),
  );
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.categories});
  final List<(String, String, String)> categories;

  static const _colors = [
    Color(0xFFFA9441),
    Color(0xFFE53180),
    Color(0xFF3BBEFF),
    Color(0xFFE74646),
    Color(0xFFB5ABAB),
    AppColors.main,
    Color(0xFF8A84D6),
    Color(0xFF6E9CFF),
  ];

  @override
  Widget build(BuildContext context) {
    final segments = <Widget>[];
    for (var index = 0; index < categories.length; index++) {
      final raw = categories[index].$2.replaceAll('%', '');
      final flex = ((double.tryParse(raw) ?? 0) * 10).round();
      if (flex > 0) {
        segments.add(
          _BarSegment(flex: flex, color: _colors[index % _colors.length]),
        );
      }
    }
    return Row(
      children: segments.isEmpty
          ? const [
              Expanded(
                child: ColoredBox(
                  color: AppColors.selected,
                  child: SizedBox(height: 16),
                ),
              ),
            ]
          : segments,
    );
  }
}

class _AnalysisLoadError extends StatelessWidget {
  const _AnalysisLoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 180,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(message, style: const TextStyle(color: AppColors.text50)),
        TextButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    ),
  );
}

String _formatAmount(int amount) {
  final negative = amount < 0;
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return '${negative ? '-' : ''}$buffer';
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.accent = false,
  });
  final String label;
  final String value;
  final bool accent;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 34,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.text50, fontSize: 14),
        ),
        _PriceText(value: value, size: 20, accent: accent),
      ],
    ),
  );
}

class _PriceText extends StatelessWidget {
  const _PriceText({
    required this.value,
    required this.size,
    this.accent = false,
    this.wonWidth = 14,
    this.wonHeight = 15,
  });
  final String value;
  final double size;
  final bool accent;
  final double wonWidth;
  final double wonHeight;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        style: TextStyle(
          color: accent ? const Color(0xFFA8A3FF) : AppColors.text,
          fontFamily: 'Amarante',
          fontSize: size,
        ),
      ),
      const SizedBox(width: 4),
      SvgPicture.asset(
        AppAssets.wonLight,
        width: wonWidth,
        height: wonHeight,
        colorFilter: accent
            ? const ColorFilter.mode(Color(0xFFA8A3FF), BlendMode.srcIn)
            : null,
      ),
    ],
  );
}

class _ChangePrice extends StatelessWidget {
  const _ChangePrice({required this.change});

  final int change;

  @override
  Widget build(BuildContext context) {
    final color = change >= 0
        ? const Color(0xFFCF376A)
        : const Color(0xFF4777D9);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 10,
          height: 9,
          child: RotatedBox(
            quarterTurns: change >= 0 ? 3 : 1,
            child: SvgPicture.asset(
              AppAssets.spendUp,
              width: 9,
              height: 10,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          _formatAmount(change.abs()),
          style: TextStyle(color: color, fontFamily: 'Amarante', fontSize: 20),
        ),
        const SizedBox(width: 4),
        SvgPicture.asset(
          AppAssets.wonLight,
          width: 14,
          height: 15,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ],
    );
  }
}

class _Asterisks extends StatelessWidget {
  const _Asterisks();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: List.generate(
      18,
      (_) => const Text(
        '*',
        style: TextStyle(color: AppColors.text20, fontSize: 10),
      ),
    ),
  );
}
