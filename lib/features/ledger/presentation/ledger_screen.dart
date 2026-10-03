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
import '../../../shared/widgets/app_toast.dart';
import '../../analysis/presentation/analysis_overview_screen.dart';
import '../../finance/data/finance_service.dart';
import '../../home/presentation/home_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../register/presentation/register_type_screen.dart';
import '../../register/presentation/register_income_screen.dart';
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
    this.initialData,
  });

  final VoidCallback? onEntrySelected;
  final FinanceService? financeService;
  final DateTime? initialAnchor;
  final int initialPeriod;
  final DateTime? currentDate;
  final Map<String, dynamic>? initialData;

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  late int _period;
  int _type = 0;
  late DateTime _anchor;
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _unfilteredData;
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
    _data = widget.initialData;
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
      if (mounted) {
        setState(() {
          _data = data;
          if (_categories.isEmpty && _paymentMethods.isEmpty) {
            _unfilteredData = data;
          }
        });
      }
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
    final hasFilters = _categories.isNotEmpty || _paymentMethods.isNotEmpty;
    final showIncomePrompt =
        !hasFilters &&
        _type == 0 &&
        !_isLoading &&
        !_hasLedgerIncome(_data) &&
        _hasLedgerExpense(_data);
    final hasSingleTypeSummary = !hasFilters && !showIncomePrompt && _type != 0;
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
        if (context.mounted &&
            (result == LedgerEditResult.deleted || result == true)) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(appSuccessToast('내역을 삭제했어요'));
        }
      }
    }

    Future<void> openIncomeRegistration() async {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) =>
              RegisterIncomeScreen(financeService: widget.financeService),
        ),
      );
      await _load();
    }

    return Scaffold(
      body: DesignCanvas(
        child: Stack(
          children: [
            const ColoredBox(color: AppColors.background),
            Positioned(
              left: 24,
              top: 122,
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
              top: 265,
              width: 354,
              height: 37,
              child: _PeriodSelector(
                anchor: _anchor,
                period: _period,
                onPrevious: () => _movePeriod(-1),
                onNext: _canMoveNext ? () => _movePeriod(1) : null,
              ),
            ),
            const Positioned(
              left: 24,
              top: 322,
              width: 354,
              child: _AsteriskDivider(),
            ),
            Positioned(
              left: 24,
              top: 347,
              width: 354,
              child: _isLoading
                  ? const _LedgerTotalsSkeleton()
                  : hasFilters
                  ? _FilteredSummary(
                      data: _data,
                      unfilteredData: _unfilteredData,
                      categories: _categories,
                      paymentMethods: _paymentMethods,
                    )
                  : _Totals(
                      data: _data,
                      type: _type,
                      period: _period,
                      anchor: _anchor,
                      preview: widget.financeService == null,
                    ),
            ),
            Positioned(
              left: 24,
              top: hasFilters
                  ? 421
                  : showIncomePrompt
                  ? 501
                  : hasSingleTypeSummary
                  ? 429
                  : 483,
              width: 354,
              child: _AsteriskDivider(),
            ),
            if (showIncomePrompt)
              Positioned(
                left: 24,
                top: 394,
                width: 354,
                child: _IncomePromptCard(onTap: openIncomeRegistration),
              ),
            if (hasFilters)
              Positioned(
                left: 24,
                top: 449,
                width: 354,
                child: _AppliedFilters(
                  categories: _categories,
                  paymentMethods: _paymentMethods,
                  onRemove: (value) {
                    setState(() {
                      _categories.remove(value);
                      _paymentMethods.remove(value);
                    });
                    _load();
                  },
                  onClear: () {
                    setState(() {
                      _categories.clear();
                      _paymentMethods.clear();
                    });
                    _load();
                  },
                ),
              ),
            Positioned(
              left: 24,
              top: hasFilters
                  ? 515
                  : showIncomePrompt
                  ? 534
                  : hasSingleTypeSummary
                  ? 462
                  : 517,
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
                    selectedLeadingAsset: AppAssets.ledgerFilterSelected,
                    fixedWidth: 99,
                    selected:
                        _categories.isNotEmpty || _paymentMethods.isNotEmpty,
                    badgeCount: _categories.length + _paymentMethods.length,
                    onTap: _showFilters,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              top: hasFilters
                  ? 586
                  : showIncomePrompt
                  ? 607
                  : hasSingleTypeSummary
                  ? 535
                  : 588,
              right: 24,
              bottom: 0,
              child: SingleChildScrollView(
                key: const Key('ledger-entries-scroll'),
                padding: const EdgeInsets.only(bottom: 124),
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
                        onRegisterIncome: openIncomeRegistration,
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
    this.selectedLeadingAsset,
    this.fixedWidth,
    this.badgeCount = 0,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final String? leadingAsset;
  final String? selectedLeadingAsset;
  final double? fixedWidth;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 47,
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
              SvgPicture.asset(
                selected
                    ? selectedLeadingAsset ?? leadingAsset!
                    : leadingAsset!,
                width: 18,
                height: 18,
              ),
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
            if (badgeCount > 0) ...[
              const SizedBox(width: 3),
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Color(0xFFA8A3FF),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
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
    if (period == 1) {
      final start = _startOfWeek(anchor);
      final end = start.add(const Duration(days: 6));
      return [
        TextSpan(text: '${start.month}', style: _periodNumberStyle),
        const WidgetSpan(child: SizedBox(width: 4)),
        const TextSpan(text: '월', style: _periodUnitStyle),
        const WidgetSpan(child: SizedBox(width: 20)),
        TextSpan(text: '${start.day}', style: _periodNumberStyle),
        const WidgetSpan(child: SizedBox(width: 4)),
        const TextSpan(text: '일', style: _periodUnitStyle),
        const WidgetSpan(child: SizedBox(width: 20)),
        const TextSpan(text: '~', style: _periodUnitStyle),
        const WidgetSpan(child: SizedBox(width: 20)),
        TextSpan(text: '${end.month}', style: _periodNumberStyle),
        const WidgetSpan(child: SizedBox(width: 4)),
        const TextSpan(text: '월', style: _periodUnitStyle),
        const WidgetSpan(child: SizedBox(width: 20)),
        TextSpan(text: '${end.day}', style: _periodNumberStyle),
        const WidgetSpan(child: SizedBox(width: 4)),
        const TextSpan(text: '일', style: _periodUnitStyle),
      ];
    }
    final parts = <(String, bool)>[
      ('${anchor.year}', true),
      ('년', false),
      ('${anchor.month}', true),
      ('월', false),
    ];
    if (period == 2) {
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
        if (index == 1 ||
            (index == 3 && period != 0) ||
            (index == 5 && period == 2))
          const WidgetSpan(child: SizedBox(width: 16)),
      ],
    ];
  }

  String _plainTitle() => switch (period) {
    1 => _weekRangeLabel(anchor),
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
  return ((date.day - 1) ~/ 7) + 1;
}

String _weekRangeLabel(DateTime anchor) {
  final start = _startOfWeek(anchor);
  final end = start.add(const Duration(days: 6));
  return '${start.month}월 ${start.day}일 ~ ${end.month}월 ${end.day}일';
}

const _periodNumberStyle = TextStyle(
  fontFamily: 'Amarante',
  fontSize: 24,
  fontWeight: FontWeight.w400,
);

const _periodUnitStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);

String _weekday(int weekday) =>
    const ['월', '화', '수', '목', '금', '토', '일'][weekday - 1];

class _AsteriskDivider extends StatelessWidget {
  const _AsteriskDivider();

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    AppAssets.asteriskDividerDark,
    width: 354,
    height: 7,
    fit: BoxFit.fill,
  );
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
    final hasIncome = data == null ? preview : _hasLedgerIncome(data);
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
            alignment: Alignment.center,
            child: Text(
              '${_periodLabel(anchor, period)} · ${type == 1 ? '지출' : '수입'} $count건',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.text50, fontSize: 14),
            ),
          ),
        ],
      );
    }
    if (!hasIncome && _hasLedgerExpense(data)) {
      return _TotalRow(label: '총 지출', amount: '-${_formatAmount(expense)} ₩');
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

bool _hasLedgerIncome(Map<String, dynamic>? data) {
  if (data == null) return false;
  final count = data['income_count'];
  if (count is num && count > 0) return true;
  final total = data['total_income_amount'];
  if (total is num && total != 0) return true;
  return _ledgerDaysContain(data, 'incomes');
}

bool _hasLedgerExpense(Map<String, dynamic>? data) {
  if (data == null) return false;
  final count = data['expense_count'];
  if (count is num && count > 0) return true;
  final total = data['total_expense_amount'];
  if (total is num && total != 0) return true;
  return _ledgerDaysContain(data, 'expenses');
}

bool _ledgerDaysContain(Map<String, dynamic> data, String key) {
  final days = data['days'];
  if (days is! List) return false;
  return days.whereType<Map<String, dynamic>>().any((day) {
    final entries = day[key];
    return entries is List && entries.isNotEmpty;
  });
}

class _IncomePromptCard extends StatelessWidget {
  const _IncomePromptCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    height: 87,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: AppColors.secondary,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            '수입을 등록하면\n잔액도 함께 보여요',
            style: TextStyle(
              color: AppColors.text80,
              fontSize: 12,
              height: 1.51,
            ),
          ),
        ),
        SizedBox(
          width: 135,
          height: 47,
          child: FilledButton(
            key: const Key('ledger-income-zero-register'),
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.main,
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppColors.text20, width: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              '수입 등록하기',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    ),
  );
}

class _FilteredSummary extends StatelessWidget {
  const _FilteredSummary({
    required this.data,
    required this.unfilteredData,
    required this.categories,
    required this.paymentMethods,
  });

  final Map<String, dynamic>? data;
  final Map<String, dynamic>? unfilteredData;
  final Set<String> categories;
  final Set<String> paymentMethods;

  @override
  Widget build(BuildContext context) {
    final filtered = data?['total_expense_amount'] as int? ?? 0;
    final total = unfilteredData?['total_expense_amount'] as int? ?? 0;
    final rate = total <= 0 ? 0 : (filtered * 100 / total).round();
    final labels = [...categories, ...paymentMethods];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${labels.join(' ')} 지출',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFA8A3FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '전체 지출 ${_formatAmount(total)}원의 $rate%',
                style: const TextStyle(color: AppColors.text80, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _Price(amount: filtered == 0 ? '0' : '-${_formatAmount(filtered)}'),
      ],
    );
  }
}

class _AppliedFilters extends StatelessWidget {
  const _AppliedFilters({
    required this.categories,
    required this.paymentMethods,
    required this.onRemove,
    required this.onClear,
  });

  final Set<String> categories;
  final Set<String> paymentMethods;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final value in [...categories, ...paymentMethods]) ...[
          GestureDetector(
            key: Key('ledger-applied-filter-$value'),
            onTap: () => onRemove(value),
            child: Container(
              height: 38,
              padding: const EdgeInsets.only(left: 15, right: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFA8A3FF),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.text20, width: .5),
              ),
              child: Row(
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF1B1B1B),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SvgPicture.asset(
                    AppAssets.ledgerFilterRemove,
                    width: 24,
                    height: 24,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        TextButton(
          key: const Key('ledger-clear-all-filters'),
          onPressed: onClear,
          child: const Text(
            '전체 해제',
            style: TextStyle(color: AppColors.text50, fontSize: 12),
          ),
        ),
      ],
    ),
  );
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
          style: const TextStyle(
            color: AppColors.text50,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
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
    this.onRegisterIncome,
  });

  final ValueChanged<_LedgerEntryTarget> onTap;
  final int type;
  final Map<String, dynamic>? data;
  final bool preview;
  final bool filtered;
  final VoidCallback? onClearFilters;
  final VoidCallback? onRegisterIncome;

  @override
  Widget build(BuildContext context) {
    final days = (data?['days'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    if (days != null && days.isNotEmpty) return _buildRemote(days);
    if (data != null) {
      if (filtered) {
        return _FilteredEmptyState(onClearFilters: onClearFilters);
      }
      return SizedBox(
        width: 354,
        height: 120,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                type == 2 ? '수입을 등록하면 잔액도 함께 보여요' : '등록된 내역이 없어요',
                style: const TextStyle(color: AppColors.text50, fontSize: 14),
              ),
              if (type == 2) ...[
                const SizedBox(height: 8),
                TextButton(
                  key: const Key('ledger-empty-income-register'),
                  onPressed: onRegisterIncome,
                  child: const Text('수입 등록하기'),
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
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 16));
      final date = DateTime.tryParse(day['date'] as String? ?? '');
      widgets.add(
        Text(
          date == null
              ? ''
              : '${date.month}월 ${date.day}일 (${_weekday(date.weekday)})',
          style: const TextStyle(
            color: AppColors.text50,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 17 / 14,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 16));
      final entries = <Widget>[
        for (final item
            in (day['expenses'] as List? ?? const [])
                .whereType<Map<String, dynamic>>())
          _Entry(
            amount: '-${_formatAmount(item['amount'] as int? ?? 0)}',
            onTap: () =>
                onTap(_LedgerEntryTarget.expense(item['id'] as String?)),
            title: item['store_name'] as String?,
            category: item['category'] as String?,
            subtitle: _expenseSubtitle(item),
          ),
        for (final item
            in (day['incomes'] as List? ?? const [])
                .whereType<Map<String, dynamic>>())
          _Entry(
            amount: '+${_formatAmount(item['amount'] as int? ?? 0)}',
            onTap: () => onTap(
              _LedgerEntryTarget.income({...item, 'income_date': day['date']}),
            ),
            title: item['category'] as String?,
            subtitle: item['memo'] as String? ?? '수입',
          ),
      ];
      for (var index = 0; index < entries.length; index++) {
        widgets.add(const _LedgerEntryDivider());
        widgets.add(const SizedBox(height: 16));
        widgets.add(entries[index]);
        if (index != entries.length - 1) {
          widgets.add(const SizedBox(height: 16));
        }
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

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({this.onClearFilters});

  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 354,
    height: 158,
    child: Column(
      children: [
        const SizedBox(height: 30),
        SvgPicture.asset(AppAssets.ledgerEmptyFilter, width: 36, height: 36),
        const SizedBox(height: 20),
        const Text(
          '선택한 조건에 맞는 내역이 없어요',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 17 / 14,
          ),
        ),
        const SizedBox(height: 26),
        GestureDetector(
          key: const Key('ledger-empty-clear-filters'),
          onTap: onClearFilters,
          child: Container(
            width: 108,
            height: 29,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.text50),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              '필터 해제하기',
              style: TextStyle(
                color: AppColors.text50,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    ),
  );
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
  final parts = <String>[
    itemLabel,
    if (item['payment_method'] case final String paymentMethod) paymentMethod,
    ?_ledgerEntryTimeLabel(item),
  ];
  return parts.where((part) => part.isNotEmpty).join('  ·  ');
}

String? _ledgerEntryTimeLabel(Map<String, dynamic> item) {
  final raw =
      item['paid_at'] ??
      item['registered_at'] ??
      item['occurred_at'] ??
      item['created_at'];
  if (raw is! String) return null;
  final value = DateTime.tryParse(raw)?.toLocal();
  if (value == null) return null;
  final period = value.hour < 12 ? '오전' : '오후';
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  return '$period $hour:${value.minute.toString().padLeft(2, '0')}';
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
      child: SizedBox(
        height: 47,
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
                      height: 17 / 14,
                    ),
                  ),
                  const SizedBox(height: 9),
                  _LedgerEntrySubtitle(
                    value: subtitle ?? '카페  ·  카드  ·  오전 10:30',
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

class _LedgerEntryDivider extends StatelessWidget {
  const _LedgerEntryDivider();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 354,
    height: 0.5,
    child: ColoredBox(color: AppColors.text10),
  );
}

class _LedgerEntrySubtitle extends StatelessWidget {
  const _LedgerEntrySubtitle({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final parts = value.split('  ·  ');
    return Row(
      children: [
        Text(
          parts.first,
          style: const TextStyle(
            color: AppColors.text80,
            fontSize: 12,
            height: 1.75,
          ),
        ),
        if (parts.length > 1) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              parts.skip(1).join('  ·  '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text50,
                fontSize: 12,
                height: 1.75,
              ),
            ),
          ),
        ],
      ],
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
    final isIncome = amount.trimLeft().startsWith('+');
    final color = accent || isIncome ? const Color(0xFFA8A3FF) : AppColors.text;
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
