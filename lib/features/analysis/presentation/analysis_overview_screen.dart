import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../finance/data/finance_service.dart';
import '../../home/presentation/home_screen.dart';
import '../../ledger/presentation/ledger_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../register/presentation/register_type_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _month = widget.financeService == null ? DateTime(2026, 8) : DateTime.now();
    _load();
  }

  Future<void> _load() async {
    final service = widget.financeService;
    if (service == null) return;
    try {
      final report = await service.analysis(
        year: _month.year,
        month: _month.month,
      );
      if (mounted) setState(() => _report = report);
    } catch (_) {
      // Preserve the latest report while a transient request fails.
    }
  }

  void _moveMonth(int direction) {
    setState(() => _month = DateTime(_month.year, _month.month + direction));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        child: Stack(
          children: [
            const ColoredBox(color: AppColors.background),
            Positioned(
              left: 24,
              top: 87,
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
              left: 16,
              top: 132,
              child: Row(
                children: List.generate(
                  4,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _TabChip(
                      label: const ['요약', '패턴', '반복지출', 'AI'][index],
                      selected: _tab == index,
                      onTap: () => setState(() => _tab = index),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 194,
              width: 354,
              child: _MonthSelector(
                month: _month,
                onPrevious: () => _moveMonth(-1),
                onNext: () => _moveMonth(1),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: 225,
              bottom: 84,
              child: _content(),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: AppBottomNavigation(
                selectedIndex: 3,
                onSelected: (index) => _navigate(context, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() => switch (_tab) {
    0 => _Report(data: _report, month: _month.month),
    1 => const _LockedList(items: [('소비 패턴 분석', '연속 7일 기록하면 열려요 0/7 일')]),
    2 => const _LockedList(
      items: [
        ('재구매 분석', '연속 20일 기록하면 열려요 0/20 일'),
        ('정기 지출 감지', '충분한 내역이 쌓이면 알려드려요'),
      ],
    ),
    _ => const _LockedList(
      items: [
        ('AI 소비 의견', '연속 14일 기록하면 열려요 0/14 일'),
        ('절약 대안 힌트', '소비 패턴을 바탕으로 제안해 드려요'),
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
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          fontSize: 13,
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
        child: SvgPicture.asset(
          AppAssets.monthArrowActive,
          width: 10,
          height: 12,
        ),
      ),
      Row(
        children: [
          Text(
            '${month.year}',
            style: TextStyle(
              color: AppColors.text,
              fontFamily: 'Amarante',
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            '년',
            style: TextStyle(color: AppColors.text, fontSize: 12),
          ),
          const SizedBox(width: 18),
          Text(
            '${month.month}',
            style: TextStyle(
              color: AppColors.text,
              fontFamily: 'Amarante',
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            '월',
            style: TextStyle(color: AppColors.text, fontSize: 12),
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
  const _Report({this.data, required this.month});
  final Map<String, dynamic>? data;
  final int month;
  static const categories = [
    ('식비', '53%', '4,500', AppAssets.categoryFood),
    ('쇼핑', '30%', '4,500', AppAssets.categoryShopping),
    ('카페', '8%', '4,500', AppAssets.categoryCulture),
    ('의료', '4%', '4,500', AppAssets.categoryMedical),
    ('교통', '3%', '4,500', AppAssets.categoryTransport),
    ('문화', '2%', '4,500', AppAssets.categoryCulture),
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
                  _categoryAsset(item['category'] as String?),
                ),
              )
              .toList();
    final goal = data?['goal'] as Map<String, dynamic>?;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Asterisks(),
          const SizedBox(height: 14),
          const Text(
            '총 지출',
            style: TextStyle(color: AppColors.text50, fontSize: 12),
          ),
          const SizedBox(height: 5),
          _PriceText(value: _formatAmount(total), size: 26),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${change >= 0 ? '▲' : '▼'} ${_formatAmount(change.abs())}',
                style: TextStyle(
                  color: change >= 0
                      ? const Color(0xFFCF376A)
                      : const Color(0xFF4777D9),
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '전월 대비 ${changeRate.toString()}%',
                style: const TextStyle(color: AppColors.text50, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _Metric(label: '일 평균 지출액', value: _formatAmount(daily)),
          _Metric(label: '총 수입', value: _formatAmount(income)),
          _Metric(
            label: '잔액',
            value: '${balance >= 0 ? '+' : ''}${_formatAmount(balance)}',
            accent: true,
          ),
          const SizedBox(height: 12),
          const _Asterisks(),
          const SizedBox(height: 14),
          const Text(
            '카테고리별 비중',
            style: TextStyle(color: AppColors.text50, fontSize: 12),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const Row(
              children: [
                Expanded(
                  flex: 53,
                  child: ColoredBox(
                    color: Color(0xFFFF9345),
                    child: SizedBox(height: 12),
                  ),
                ),
                Expanded(
                  flex: 30,
                  child: ColoredBox(
                    color: Color(0xFFD92B80),
                    child: SizedBox(height: 12),
                  ),
                ),
                Expanded(
                  flex: 17,
                  child: ColoredBox(
                    color: AppColors.main,
                    child: SizedBox(height: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...visibleCategories.map(
            (item) => SizedBox(
              height: 45,
              child: Row(
                children: [
                  SvgPicture.asset(item.$4, width: 26, height: 26),
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
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          item.$2,
                          style: const TextStyle(
                            color: AppColors.text50,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _PriceText(value: item.$3, size: 16),
                ],
              ),
            ),
          ),
          if (data == null || goal != null) ...[
            const _Asterisks(),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$month월 지출 목표',
                  style: const TextStyle(color: AppColors.text50, fontSize: 12),
                ),
                Text(
                  '${_formatAmount(goal?['amount'] as int? ?? 0)}원 중 ${_formatAmount(total)}원 사용',
                  style: const TextStyle(color: AppColors.text, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${goal?['usage_rate'] ?? 20}%',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontFamily: 'Amarante',
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LinearProgressIndicator(
                    value: ((goal?['usage_rate'] as num? ?? 20) / 100)
                        .clamp(0, 1)
                        .toDouble(),
                    minHeight: 10,
                    color: AppColors.main,
                    backgroundColor: AppColors.selected,
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _categoryAsset(String? category) => switch (category) {
  '쇼핑' => AppAssets.categoryShopping,
  '의료' => AppAssets.categoryMedical,
  '교통' => AppAssets.categoryTransport,
  '문화' => AppAssets.categoryCulture,
  _ => AppAssets.categoryFood,
};

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
          style: const TextStyle(color: AppColors.text50, fontSize: 12),
        ),
        _PriceText(value: value, size: 16, accent: accent),
      ],
    ),
  );
}

class _PriceText extends StatelessWidget {
  const _PriceText({
    required this.value,
    required this.size,
    this.accent = false,
  });
  final String value;
  final double size;
  final bool accent;
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
      SvgPicture.asset(AppAssets.wonLight, width: 12, height: 13),
    ],
  );
}

class _Asterisks extends StatelessWidget {
  const _Asterisks();
  @override
  Widget build(BuildContext context) => Text(
    List.filled(18, '*').join('   '),
    maxLines: 1,
    style: const TextStyle(color: AppColors.text20, fontSize: 10),
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
      ...items.map(
        (item) => Container(
          height: 80,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x0DE2E2F9))),
          ),
          child: Row(
            children: [
              SvgPicture.asset(AppAssets.analysisLocked, width: 28, height: 28),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 8),
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
              const Text(
                '〉',
                style: TextStyle(color: AppColors.text, fontSize: 22),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
