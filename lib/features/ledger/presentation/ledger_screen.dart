import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/app_category_icon.dart';
import '../../../shared/widgets/app_chevron.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../analysis/presentation/analysis_overview_screen.dart';
import '../../finance/data/finance_service.dart';
import '../../home/presentation/home_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../register/presentation/register_type_screen.dart';
import 'ledger_edit_screen.dart';
import 'ledger_detail_screen.dart';
import 'income_detail_screen.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({
    super.key,
    this.onEntrySelected,
    this.financeService,
    this.initialAnchor,
    this.initialPeriod = 0,
    this.currentDate,
  });

  final VoidCallback? onEntrySelected;
  final FinanceService? financeService;
  final DateTime? initialAnchor;
  final int initialPeriod;
  final DateTime? currentDate;

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  late int _period;
  int _type = 0;
  late DateTime _anchor;
  Map<String, dynamic>? _data;
  Set<String> _categories = {};
  Set<String> _paymentMethods = {};
  late bool _isLoading;
  String? _error;

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod.clamp(0, 2);
    _anchor =
        widget.initialAnchor ??
        (widget.financeService == null
            ? DateTime(2026, 8, 19)
            : (widget.currentDate ?? DateTime.now()));
    _isLoading = widget.financeService != null;
    _load();
  }

  Future<void> _load() async {
    final service = widget.financeService;
    if (service == null) return;
    setState(() => _isLoading = true);
    try {
      setState(() => _error = null);
      final data = await service.ledger(
        period: const ['month', 'week', 'day'][_period],
        anchor: _anchor,
        type: const ['all', 'expense', 'income'][_type],
        categories: _categories.toList(),
        paymentMethods: _paymentMethods.toList(),
      );
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted && _data == null) {
        setState(() => _error = '가계부 내역을 불러오지 못했습니다.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Future<void> openDetail(_LedgerEntryTarget target) async {
      if (widget.onEntrySelected case final callback?) {
        callback();
        return;
      }
      final result = await Navigator.of(context).push<Object?>(
        MaterialPageRoute<Object?>(
          builder: (_) => target.isIncome
              ? IncomeDetailScreen(
                  incomeId: target.id!,
                  initialData: target.data!,
                  financeService: widget.financeService,
                )
              : LedgerDetailScreen(
                  expenseId: target.id,
                  financeService: widget.financeService,
                ),
        ),
      );
      if (result == LedgerEditResult.updated ||
          result == LedgerEditResult.deleted ||
          result == true) {
        await _load();
      }
    }

    return Scaffold(
      body: DesignCanvas(
        child: Stack(
          children: [
            const ColoredBox(color: AppColors.background),
            const Positioned(
              left: 24,
              top: 128,
              child: Text(
                '가계부',
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
                children: List.generate(3, (index) {
                  return Padding(
                    padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
                    child: _Chip(
                      key: Key('ledger-period-$index'),
                      label: const ['월', '주', '일'][index],
                      selected: _period == index,
                      onTap: () {
                        setState(() => _period = index);
                        _load();
                      },
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              left: 24,
              top: 272,
              width: 354,
              child: _PeriodSelector(
                anchor: _anchor,
                period: _period,
                onPrevious: () => _movePeriod(-1),
                onNext: _canMoveNext ? () => _movePeriod(1) : null,
              ),
            ),
            const Positioned(
              left: 24,
              top: 321,
              width: 354,
              child: _AsteriskDivider(),
            ),
            Positioned(
              left: 24,
              top: 353,
              width: 354,
              child: _isLoading
                  ? const _LedgerTotalsSkeleton()
                  : _Totals(
                      data: _data,
                      type: _type,
                      period: _period,
                      anchor: _anchor,
                      preview: widget.financeService == null,
                    ),
            ),
            const Positioned(
              left: 24,
              top: 483,
              width: 354,
              child: _AsteriskDivider(),
            ),
            Positioned(
              left: 24,
              top: 517,
              child: Row(
                children: [
                  ...List.generate(3, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _Chip(
                        label: const ['전체', '지출', '수입'][index],
                        selected: _type == index,
                        onTap: () {
                          setState(() => _type = index);
                          _load();
                        },
                      ),
                    );
                  }),
                  _Chip(
                    label: '필터',
                    leadingAsset: AppAssets.filterLight,
                    fixedWidth: 99,
                    selected:
                        _categories.isNotEmpty || _paymentMethods.isNotEmpty,
                    onTap: _showFilters,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              top: 588,
              right: 24,
              bottom: 100,
              child: SingleChildScrollView(
                key: const Key('ledger-entries-scroll'),
                padding: const EdgeInsets.only(bottom: 24),
                child: _isLoading
                    ? const AppSkeletonList(rows: 4)
                    : _error != null && _data == null
                    ? _LedgerLoadError(message: _error!, onRetry: _load)
                    : _Entries(
                        onTap: openDetail,
                        type: _type,
                        data: _data,
                        preview: widget.financeService == null,
                        filtered:
                            _categories.isNotEmpty ||
                            _paymentMethods.isNotEmpty,
                        onClearFilters: () {
                          setState(() {
                            _categories.clear();
                            _paymentMethods.clear();
                          });
                          _load();
                        },
                      ),
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: AppBottomNavigation(
                selectedIndex: 1,
                onSelected: (index) => _navigate(context, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _movePeriod(int direction) {
    setState(() {
      _anchor = switch (_period) {
        0 => DateTime(_anchor.year, _anchor.month + direction, 1),
        1 => _anchor.add(Duration(days: 7 * direction)),
        _ => _anchor.add(Duration(days: direction)),
      };
    });
    _load();
  }

  bool get _canMoveNext => _isBeforeCurrentPeriod(
    anchor: _anchor,
    period: _period,
    currentDate: widget.currentDate ?? DateTime.now(),
  );

  Future<void> _showFilters() async {
    final result = await showDialog<_LedgerFilters>(
      context: context,
      barrierColor: const Color(0xD9111216),
      builder: (context) => _FilterDialog(
        initialCategories: _categories,
        initialPaymentMethods: _paymentMethods,
        initialData: _data,
        financeService: widget.financeService,
        period: const ['month', 'week', 'day'][_period],
        anchor: _anchor,
        type: const ['all', 'expense', 'income'][_type],
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _categories = result.categories;
      _paymentMethods = result.paymentMethods;
      if (result.previewData != null) _data = result.previewData;
    });
    if (result.previewData == null) await _load();
  }

  void _navigate(BuildContext context, int index) {
    final Widget? page = switch (index) {
      0 => HomeScreen(financeService: widget.financeService),
      2 => RegisterTypeScreen(financeService: widget.financeService),
      3 => AnalysisOverviewScreen(financeService: widget.financeService),
      4 => ProfileScreen(financeService: widget.financeService),
      _ => null,
    };
    if (page == null) return;
    final route = MaterialPageRoute<void>(builder: (_) => page);
    if (index == 2) {
      Navigator.of(context).push(route);
    } else {
      Navigator.of(context).pushReplacement(route);
    }
  }
}

class _LedgerTotalsSkeleton extends StatelessWidget {
  const _LedgerTotalsSkeleton();

  @override
  Widget build(BuildContext context) => const AppSkeleton(
    child: Column(
      children: [
        _SkeletonTotalRow(),
        SizedBox(height: 20),
        _SkeletonTotalRow(),
        SizedBox(height: 20),
        _SkeletonTotalRow(),
      ],
    ),
  );
}

class _SkeletonTotalRow extends StatelessWidget {
  const _SkeletonTotalRow();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      AppSkeletonBox(width: 58, height: 14),
      AppSkeletonBox(width: 96, height: 20),
    ],
  );
}

class _LedgerFilters {
  const _LedgerFilters({
    required this.categories,
    required this.paymentMethods,
    this.previewData,
  });

  final Set<String> categories;
  final Set<String> paymentMethods;
  final Map<String, dynamic>? previewData;
}

class _FilterDialog extends StatefulWidget {
  const _FilterDialog({
    required this.initialCategories,
    required this.initialPaymentMethods,
    required this.initialData,
    required this.financeService,
    required this.period,
    required this.anchor,
    required this.type,
  });

  final Set<String> initialCategories;
  final Set<String> initialPaymentMethods;
  final Map<String, dynamic>? initialData;
  final FinanceService? financeService;
  final String period;
  final DateTime anchor;
  final String type;

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  static const _categoryValues = [
    '식비',
    '카페',
    '쇼핑',
    '의료',
    '문화',
    '교통',
    '교육',
    '기타',
  ];
  static const _paymentValues = ['현금', '카드', '미지정'];

  late final Set<String> _categories = {...widget.initialCategories};
  late final Set<String> _paymentMethods = {...widget.initialPaymentMethods};
  late Map<String, dynamic>? _previewData = widget.initialData;
  bool _isLoading = false;
  int _requestGeneration = 0;

  int get _expenseTotal => _previewData?['total_expense_amount'] as int? ?? 0;

  int get _entryCount =>
      (_previewData?['expense_count'] as int? ?? 0) +
      (_previewData?['income_count'] as int? ?? 0);

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    backgroundColor: Colors.transparent,
    child: DesignCanvas(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: ColoredBox(
          color: const Color(0x99121215),
          child: Stack(
            children: [
              Positioned(
                left: 184,
                top: 238,
                width: 34,
                height: 34,
                child: IconButton(
                  key: const Key('close-ledger-filter'),
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  icon: SvgPicture.asset(
                    AppAssets.ledgerFilterClose,
                    width: 34,
                    height: 34,
                  ),
                ),
              ),
              const Positioned(
                top: 289,
                left: 0,
                right: 0,
                child: Text(
                  '필터',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Positioned(
                top: 323,
                left: 0,
                right: 0,
                child: Text(
                  '중복 선택 가능',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.text50, fontSize: 12),
                ),
              ),
              Positioned(
                left: 24,
                top: 389,
                width: 354,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 10,
                  children: _categoryValues
                      .map(
                        (value) => _FilterChoice(
                          value: value,
                          category: value,
                          selected: _categories.contains(value),
                          onTap: () => _toggle(_categories, value),
                        ),
                      )
                      .toList(),
                ),
              ),
              const Positioned(
                top: 598,
                left: 0,
                right: 0,
                child: Text(
                  '지출에만 적용',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.text50, fontSize: 12),
                ),
              ),
              Positioned(
                left: 24,
                top: 636,
                width: 354,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: _paymentValues
                      .map(
                        (value) => _FilterChoice(
                          value: value,
                          selected: _paymentMethods.contains(value),
                          onTap: () => _toggle(_paymentMethods, value),
                        ),
                      )
                      .toList(),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                top: 741,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '선택한 조건의 지출 합계',
                      style: TextStyle(color: AppColors.text50, fontSize: 12),
                    ),
                    _Price(
                      key: const Key('ledger-filter-expense-total'),
                      amount: _formatAmount(_expenseTotal),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 40,
                height: 56,
                child: FilledButton(
                  key: const Key('apply-ledger-filter'),
                  onPressed: () => Navigator.pop(
                    context,
                    _LedgerFilters(
                      categories: {..._categories},
                      paymentMethods: {..._paymentMethods},
                      previewData: _isLoading ? null : _previewData,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5C52FF),
                    disabledBackgroundColor: const Color(0xFF5C52FF),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    _isLoading ? '조회 중...' : '$_entryCount건 보기',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Pretendard',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _toggle(Set<String> values, String value) async {
    setState(() {
      values.contains(value) ? values.remove(value) : values.add(value);
    });
    await _loadPreview();
  }

  Future<void> _loadPreview() async {
    final service = widget.financeService;
    if (service == null) return;
    final generation = ++_requestGeneration;
    setState(() => _isLoading = true);
    try {
      final data = await service.ledger(
        period: widget.period,
        anchor: widget.anchor,
        type: widget.type,
        categories: _categories.toList(),
        paymentMethods: _paymentMethods.toList(),
      );
      if (mounted && generation == _requestGeneration) {
        setState(() => _previewData = data);
      }
    } catch (_) {
      // Keep the previous preview when the request cannot complete.
    } finally {
      if (mounted && generation == _requestGeneration) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _FilterChoice extends StatelessWidget {
  const _FilterChoice({
    required this.value,
    required this.selected,
    required this.onTap,
    this.category,
  });

  final String value;
  final bool selected;
  final VoidCallback onTap;
  final String? category;

  @override
  Widget build(BuildContext context) {
    final categoryIcon = AppCategoryIcon(category: category, slotSize: 26);
    return GestureDetector(
      key: Key('ledger-filter-$value'),
      onTap: onTap,
      child: Container(
        height: category == null ? 48 : 54,
        padding: EdgeInsets.symmetric(horizontal: category == null ? 26 : 24),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFA8A3FF) : AppColors.selected,
          border: Border.all(color: AppColors.outline, width: 0.5),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category != null) ...[
              if (selected)
                ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF1B1B1B),
                    BlendMode.srcIn,
                  ),
                  child: categoryIcon,
                )
              else
                categoryIcon,
              const SizedBox(width: 6),
            ],
            Text(
              value,
              style: TextStyle(
                color: selected ? const Color(0xFF1B1B1B) : AppColors.text50,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    super.key,
    this.selected = false,
    this.onTap,
    this.leadingAsset,
    this.fixedWidth,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final String? leadingAsset;
  final double? fixedWidth;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: fixedWidth,
        constraints: const BoxConstraints(minWidth: 66),
        padding: EdgeInsets.symmetric(horizontal: fixedWidth == null ? 26 : 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFA8A3FF) : AppColors.selected,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.outline, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingAsset != null) ...[
              SvgPicture.asset(leadingAsset!, width: 18, height: 18),
              const SizedBox(width: 2),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFF1B1B1B) : AppColors.text50,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.anchor,
    required this.period,
    required this.onPrevious,
    required this.onNext,
  });
  final DateTime anchor;
  final int period;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          key: const Key('ledger-period-previous'),
          onTap: onPrevious,
          child: Transform.flip(
            flipX: true,
            child: SvgPicture.asset(
              AppAssets.monthArrowActive,
              width: 10,
              height: 12,
            ),
          ),
        ),
        Text.rich(
          key: const Key('ledger-period-title'),
          TextSpan(children: _titleSpans()),
          semanticsLabel: _plainTitle(),
          style: const TextStyle(color: AppColors.text),
        ),
        GestureDetector(
          key: const Key('ledger-period-next'),
          onTap: onNext,
          child: SvgPicture.asset(
            onNext == null
                ? AppAssets.monthArrowDim
                : AppAssets.monthArrowActive,
            width: 10,
            height: 12,
          ),
        ),
      ],
    );
  }

  List<InlineSpan> _titleSpans() {
    final parts = <(String, bool)>[
      ('${anchor.year}', true),
      ('년', false),
      ('${anchor.month}', true),
      ('월', false),
    ];
    if (period == 1) {
      parts.addAll([('${_weekOfMonth(anchor)}', true), ('주차', false)]);
    } else if (period == 2) {
      parts.addAll([
        ('${anchor.day}', true),
        ('일', false),
        ('(${_weekday(anchor.weekday)})', false),
      ]);
    }
    return [
      for (var index = 0; index < parts.length; index++) ...[
        if (index > 0) const WidgetSpan(child: SizedBox(width: 4)),
        TextSpan(
          text: parts[index].$1,
          style: TextStyle(
            fontFamily: parts[index].$2 ? 'Amarante' : null,
            fontSize: parts[index].$2 ? 24 : 14,
            fontWeight: parts[index].$2 ? FontWeight.w400 : FontWeight.w500,
          ),
        ),
        if (index == 1 || index == 3 || (period == 2 && index == 5))
          const WidgetSpan(child: SizedBox(width: 16)),
      ],
    ];
  }

  String _plainTitle() => switch (period) {
    1 => '${anchor.year}년 ${anchor.month}월 ${_weekOfMonth(anchor)}주차',
    2 =>
      '${anchor.year}년 ${anchor.month}월 ${anchor.day}일 '
          '(${_weekday(anchor.weekday)})',
    _ => '${anchor.year}년 ${anchor.month}월',
  };
}

bool _isBeforeCurrentPeriod({
  required DateTime anchor,
  required int period,
  required DateTime currentDate,
}) {
  final anchorDate = DateTime(anchor.year, anchor.month, anchor.day);
  final today = DateTime(currentDate.year, currentDate.month, currentDate.day);
  return switch (period) {
    0 => DateTime(
      anchor.year,
      anchor.month,
    ).isBefore(DateTime(today.year, today.month)),
    1 => _startOfWeek(anchorDate).isBefore(_startOfWeek(today)),
    _ => anchorDate.isBefore(today),
  };
}

DateTime _startOfWeek(DateTime date) =>
    date.subtract(Duration(days: date.weekday - DateTime.monday));

int _weekOfMonth(DateTime date) {
  final firstDay = DateTime(date.year, date.month, 1);
  final daysBeforeFirstMonday = firstDay.weekday - DateTime.monday;
  return ((date.day + daysBeforeFirstMonday - 1) ~/ 7) + 1;
}

String _weekday(int weekday) =>
    const ['월', '화', '수', '목', '금', '토', '일'][weekday - 1];

class _AsteriskDivider extends StatelessWidget {
  const _AsteriskDivider();

  @override
  Widget build(BuildContext context) {
    return Text(
      List.filled(18, '*').join('   '),
      maxLines: 1,
      style: const TextStyle(color: AppColors.text20, fontSize: 11),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({
    this.data,
    required this.type,
    required this.period,
    required this.anchor,
    this.preview = false,
  });
  final Map<String, dynamic>? data;
  final int type;
  final int period;
  final DateTime anchor;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final expense =
        data?['total_expense_amount'] as int? ?? (preview ? 150000 : 0);
    final income =
        data?['total_income_amount'] as int? ?? (preview ? 150000 : 0);
    final balance = data?['balance'] as int? ?? (preview ? 150000 : 0);
    final count = type == 1
        ? (data?['expense_count'] as int? ?? 0)
        : (data?['income_count'] as int? ?? 0);
    if (type != 0) {
      return Column(
        children: [
          _TotalRow(
            label: type == 1 ? '총 지출' : '총 수입',
            amount:
                '${type == 1 ? '-' : '+'}${_formatAmount(type == 1 ? expense : income)} ₩',
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_periodLabel(anchor, period)} · ${type == 1 ? '지출' : '수입'} $count건',
              style: const TextStyle(color: AppColors.text50, fontSize: 14),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        _TotalRow(label: '총 지출', amount: '-${_formatAmount(expense)} ₩'),
        const SizedBox(height: 20),
        _TotalRow(label: '총 수입', amount: '+${_formatAmount(income)} ₩'),
        const SizedBox(height: 20),
        _TotalRow(
          label: '잔액',
          amount: '${balance >= 0 ? '+' : ''}${_formatAmount(balance)} ₩',
          accent: true,
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.amount,
    this.accent = false,
  });

  final String label;
  final String amount;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.text50, fontSize: 14),
        ),
        _Price(amount: amount.replaceAll(' ₩', ''), accent: accent),
      ],
    );
  }
}

class _Entries extends StatelessWidget {
  const _Entries({
    required this.onTap,
    required this.type,
    this.data,
    this.preview = false,
    this.filtered = false,
    this.onClearFilters,
  });

  final ValueChanged<_LedgerEntryTarget> onTap;
  final int type;
  final Map<String, dynamic>? data;
  final bool preview;
  final bool filtered;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final days = (data?['days'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    if (days != null && days.isNotEmpty) return _buildRemote(days);
    if (data != null) {
      return SizedBox(
        width: 354,
        height: 120,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                filtered ? '선택한 조건에 맞는 내역이 없어요' : '등록된 내역이 없어요',
                style: const TextStyle(color: AppColors.text50, fontSize: 14),
              ),
              if (filtered) ...[
                const SizedBox(height: 6),
                const Text(
                  '기간을 바꾸거나 필터를 해제해 보세요',
                  style: TextStyle(color: AppColors.text50, fontSize: 12),
                ),
                TextButton(
                  onPressed: onClearFilters,
                  child: const Text('필터 해제하기'),
                ),
              ],
            ],
          ),
        ),
      );
    }
    if (!preview) return const SizedBox.shrink();
    final amounts = type == 2
        ? const ['+150,000', '+150,000', '+150,000', '+150,000']
        : const ['-4,500', '-4,500', '-4,500', '-4,500'];
    return SizedBox(
      width: 354,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '8월 19일 (월)',
            style: TextStyle(color: AppColors.text50, fontSize: 14),
          ),
          const SizedBox(height: 14),
          ...List.generate(
            4,
            (index) => _Entry(
              amount: amounts[index],
              onTap: () => onTap(const _LedgerEntryTarget.expense(null)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemote(List<Map<String, dynamic>> days) {
    final widgets = <Widget>[];
    for (final day in days) {
      final date = DateTime.tryParse(day['date'] as String? ?? '');
      widgets.add(
        Text(
          date == null ? '' : '${date.month}월 ${date.day}일',
          style: const TextStyle(color: AppColors.text50, fontSize: 14),
        ),
      );
      widgets.add(const SizedBox(height: 14));
      for (final item
          in (day['expenses'] as List? ?? const [])
              .whereType<Map<String, dynamic>>()) {
        widgets.add(
          _Entry(
            amount: '-${_formatAmount(item['amount'] as int? ?? 0)}',
            onTap: () =>
                onTap(_LedgerEntryTarget.expense(item['id'] as String?)),
            title: item['store_name'] as String?,
            category: item['category'] as String?,
            subtitle: _expenseSubtitle(item),
          ),
        );
      }
      for (final item
          in (day['incomes'] as List? ?? const [])
              .whereType<Map<String, dynamic>>()) {
        widgets.add(
          _Entry(
            amount: '+${_formatAmount(item['amount'] as int? ?? 0)}',
            onTap: () => onTap(
              _LedgerEntryTarget.income({...item, 'income_date': day['date']}),
            ),
            title: item['category'] as String?,
            subtitle: item['memo'] as String? ?? '수입',
          ),
        );
      }
    }
    return SizedBox(
      width: 354,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }
}

String _expenseSubtitle(Map<String, dynamic> item) {
  final count = item['item_count'] as int? ?? 0;
  final representative =
      item['representative_item_name'] as String? ??
      item['category'] as String? ??
      '';
  final itemLabel = count > 1
      ? '$representative 외 ${count - 1}건'
      : representative;
  return '$itemLabel  ·  ${item['payment_method']}';
}

String _periodLabel(DateTime anchor, int period) => switch (period) {
  0 => '${anchor.year}년 ${anchor.month}월',
  1 => '${anchor.month}월 ${_weekOfMonth(anchor)}주차',
  _ =>
    '${anchor.year}년 ${anchor.month}월 ${anchor.day}일(${_weekday(anchor.weekday)})',
};

class _LedgerLoadError extends StatelessWidget {
  const _LedgerLoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 354,
    height: 120,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(message, style: const TextStyle(color: AppColors.text50)),
        TextButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    ),
  );
}

class _LedgerEntryTarget {
  const _LedgerEntryTarget.expense(this.id) : isIncome = false, data = null;
  _LedgerEntryTarget.income(Map<String, dynamic> data)
    : isIncome = true,
      id = data['id'] as String?,
      data = data;

  final bool isIncome;
  final String? id;
  final Map<String, dynamic>? data;
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.amount,
    required this.onTap,
    this.title,
    this.subtitle,
    this.category,
  });

  final String amount;
  final VoidCallback onTap;
  final String? title;
  final String? subtitle;
  final String? category;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x0DE2E2F9))),
        ),
        child: Row(
          children: [
            AppCategoryIcon(
              key: Key('ledger-category-${category ?? '식비'}'),
              category: category,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? '아주대학교 카페',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle ?? '카페  ·  카드  ·  오전 10:30',
                    style: const TextStyle(
                      color: AppColors.text50,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _Price(amount: amount),
            const SizedBox(width: 6),
            const AppChevron(),
          ],
        ),
      ),
    );
  }
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

class _Price extends StatelessWidget {
  const _Price({required this.amount, super.key, this.accent = false});

  final String amount;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ? const Color(0xFFA8A3FF) : AppColors.text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          amount,
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
