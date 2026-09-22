import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/app_category_icon.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../finance/data/finance_service.dart';
import '../../home/presentation/home_screen.dart';
import '../../ledger/presentation/ledger_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../register/presentation/register_type_screen.dart';
import 'analysis_goal_screen.dart';

class AnalysisOverviewScreen extends StatefulWidget {
  const AnalysisOverviewScreen({
    super.key,
    this.onNavigationSelected,
    this.financeService,
  });
  final ValueChanged<int>? onNavigationSelected;
  final FinanceService? financeService;
  @override
  State<AnalysisOverviewScreen> createState() => _AnalysisOverviewScreenState();
}

class _AnalysisOverviewScreenState extends State<AnalysisOverviewScreen> {
  int _tab = 0;
  late DateTime _month;
  Map<String, dynamic>? _report;
  late bool _isLoading;

  @override
  void initState() {
    super.initState();
    _month = widget.financeService == null ? DateTime(2026, 8) : DateTime.now();
    _isLoading = widget.financeService != null;
    _load();
  }

  Future<void> _load() async {
    final service = widget.financeService;
    if (service == null) return;
    setState(() => _isLoading = true);
    try {
      final report = await service.analysis(
        year: _month.year,
        month: _month.month,
      );
      if (mounted) setState(() => _report = report);
    } catch (_) {
      // Preserve the latest report while a transient request fails.
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
          initialAmount: currentAmount > 0 ? currentAmount : 150000,
          monthlyIncome: income,
          financeService: service,
          onSaved: (_) => _load(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportMode = _tab == 0;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: reportMode
                ? ScrollableDesignCanvas(
                    width: 402,
                    height: 1490,
                    child: _buildCanvas(),
                  )
                : DesignCanvas(width: 402, height: 874, child: _buildCanvas()),
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
        top: 128,
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
        child: Row(
          children: List.generate(
            2,
            (index) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _TabChip(
                label: const ['리포트', 'AI분석'][index],
                selected: _tab == index,
                onTap: () => setState(() => _tab = index),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: 24,
        top: 264,
        width: 354,
        child: _MonthSelector(
          month: _month,
          onPrevious: () => _moveMonth(-1),
          onNext: () => _moveMonth(1),
        ),
      ),
      Positioned(left: 24, top: 321, width: 354, child: _content()),
    ],
  );

  Widget _content() => switch (_tab) {
    0 =>
      _isLoading
          ? const _AnalysisSkeleton()
          : _Report(
              data: _report,
              month: _month.month,
              onEditGoal: () => _openGoalEditor(),
            ),
    _ => const _LockedList(
      items: [
        ('소비 패턴 분석', '연속 7일 기록하면 열려요 0/7 일'),
        ('AI 소비 의견', '연속 14일 기록하면 열려요 0/14 일'),
        ('재구매 분석', '연속 20일 기록하면 열려요 0/20 일'),
      ],
    ),
  };

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
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFA8A3FF) : AppColors.selected,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline, width: .5),
      ),
      child: Text(
        label,
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
  });
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
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
        onTap: onNext,
        child: SvgPicture.asset(AppAssets.monthArrowDim, width: 10, height: 12),
      ),
    ],
  );
}

class _Report extends StatelessWidget {
  const _Report({this.data, required this.month, this.onEditGoal});
  final Map<String, dynamic>? data;
  final int month;
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
    final total = data?['total_expense_amount'] as int? ?? 150000;
    final daily = data?['daily_average_expense'] as int? ?? 40000;
    final income = data?['total_income_amount'] as int? ?? 150000;
    final balance = data?['balance'] as int? ?? 150000;
    final change = data?['change_amount'] as int? ?? 2500;
    final changeRate = data?['change_rate'] as num? ?? 12;
    final remoteCategories = (data?['category_breakdown'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    final visibleCategories = data == null
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
    final goal = data?['goal'] as Map<String, dynamic>?;
    final goalAmount = goal?['amount'] as int? ?? 0;
    final goalUsageRate =
        goal?['usage_rate'] as num? ?? (data == null ? 20 : 0);
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
        _Metric(label: '총 수입', value: _formatAmount(income)),
        _Metric(
          label: '잔액',
          value: '${balance >= 0 ? '+' : ''}${_formatAmount(balance)}',
          accent: true,
        ),
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
          child: const Row(
            children: [
              _BarSegment(flex: 31, color: Color(0xFFFA9441)),
              _BarSegment(flex: 22, color: Color(0xFFE53180)),
              _BarSegment(flex: 16, color: Color(0xFF3BBEFF)),
              _BarSegment(flex: 12, color: Color(0xFFE74646)),
              _BarSegment(flex: 8, color: Color(0xFFB5ABAB)),
              _BarSegment(flex: 11, color: AppColors.main),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...visibleCategories.map(
          (item) => SizedBox(
            height: 64,
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
        GestureDetector(
          onTap: onEditGoal,
          behavior: HitTestBehavior.opaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$month월 지출 목표',
                    style: const TextStyle(
                      color: AppColors.text50,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    goalAmount > 0
                        ? '${_formatAmount(goalAmount)}원 중 ${_formatAmount(total)}원 사용'
                        : '목표를 설정해 주세요',
                    style: const TextStyle(color: AppColors.text, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '$goalUsageRate%',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontFamily: 'Amarante',
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (goalUsageRate / 100).clamp(0, 1).toDouble(),
                      minHeight: 15,
                      color: AppColors.main,
                      backgroundColor: AppColors.selected,
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
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

class _LockedList extends StatelessWidget {
  const _LockedList({required this.items});
  final List<(String, String)> items;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const _Asterisks(),
      const SizedBox(height: 12),
      ...List.generate(
        items.length,
        (index) => Container(
          height: 80,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x0DE2E2F9))),
          ),
          child: Row(
            children: [
              SizedBox.square(
                key: ValueKey('analysis-locked-icon-slot-$index'),
                dimension: 26,
                child: Center(
                  child: SizedBox(
                    key: ValueKey('analysis-locked-icon-$index'),
                    width: index == 0 ? 18 : 26,
                    height: index == 0 ? 18 : 26,
                    child: SvgPicture.asset(switch (index) {
                      0 => AppAssets.analysisPattern,
                      1 => AppAssets.analysisAi,
                      _ => AppAssets.analysisRepurchase,
                    }, fit: BoxFit.fill),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      items[index].$1,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      items[index].$2,
                      style: const TextStyle(
                        color: AppColors.text50,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SvgPicture.asset(
                AppAssets.analysisArrowRight,
                width: 24,
                height: 24,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
