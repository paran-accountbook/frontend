import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/p2_widgets.dart';
import '../../category/data/category_models.dart';
import '../../category/data/category_service.dart';
import '../../category/presentation/category_flows.dart';
import '../../finance/data/finance_service.dart';
import '../../finance/data/payment_methods.dart';

/// 가계_001·002: 가계부 목록에 적용한 필터 조건.
@immutable
class LedgerFilterSelection {
  const LedgerFilterSelection({
    this.expenseCategories = const {},
    this.paymentMethods = const {},
    this.incomeCategories = const {},
  });

  static const empty = LedgerFilterSelection();

  final Set<String> expenseCategories;
  final Set<String> paymentMethods;
  final Set<String> incomeCategories;

  bool get hasExpense =>
      expenseCategories.isNotEmpty || paymentMethods.isNotEmpty;
  bool get hasIncome => incomeCategories.isNotEmpty;
  bool get isEmpty => !hasExpense && !hasIncome;
  bool get isNotEmpty => !isEmpty;

  /// 지출 조건과 수입 조건을 섞어 고름 → 서버는 type=all 로 받고 앱에서 거른다.
  bool get isMixed => hasExpense && hasIncome;
  int get count =>
      expenseCategories.length +
      paymentMethods.length +
      incomeCategories.length;

  LedgerFilterSelection copyWith({
    Set<String>? expenseCategories,
    Set<String>? paymentMethods,
    Set<String>? incomeCategories,
  }) => LedgerFilterSelection(
    expenseCategories: expenseCategories ?? this.expenseCategories,
    paymentMethods: paymentMethods ?? this.paymentMethods,
    incomeCategories: incomeCategories ?? this.incomeCategories,
  );

  /// 서버로 보낼 type (all/expense/income).
  String serverType(String tabType) {
    if (isMixed) return 'all';
    if (hasExpense) return 'expense';
    if (hasIncome) return 'income';
    return tabType;
  }

  @override
  bool operator ==(Object other) =>
      other is LedgerFilterSelection &&
      _sameSet(other.expenseCategories, expenseCategories) &&
      _sameSet(other.paymentMethods, paymentMethods) &&
      _sameSet(other.incomeCategories, incomeCategories);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(expenseCategories),
    Object.hashAllUnordered(paymentMethods),
    Object.hashAllUnordered(incomeCategories),
  );
}

bool _sameSet(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);

/// 필터 조건으로 내역을 조회한다. 섞어 고른 경우 type=all 로 받아 앱에서 거른다.
Future<Map<String, dynamic>> loadFilteredLedger(
  FinanceService service, {
  required String period,
  required DateTime anchor,
  required String tabType,
  required LedgerFilterSelection selection,
}) async {
  final type = selection.serverType(tabType);
  if (service is LedgerFilterService) {
    final filterService = service as LedgerFilterService;
    if (selection.isMixed) {
      final all = await filterService.ledgerFiltered(
        period: period,
        anchor: anchor,
        type: 'all',
      );
      return applyLedgerFilter(all, selection);
    }
    return filterService.ledgerFiltered(
      period: period,
      anchor: anchor,
      type: type,
      categories: selection.expenseCategories.toList(),
      paymentMethods: selection.paymentMethods.toList(),
      incomeCategories: selection.incomeCategories.toList(),
    );
  }
  final data = await service.ledger(
    period: period,
    anchor: anchor,
    type: selection.hasIncome && !selection.hasExpense ? 'income' : type,
    categories: selection.expenseCategories.toList(),
    paymentMethods: selection.paymentMethods.toList(),
  );
  return selection.hasIncome ? applyLedgerFilter(data, selection) : data;
}

/// 지출·수입을 섞어 고른 경우 앱에서 거르고 건수·합계를 다시 계산한다.
Map<String, dynamic> applyLedgerFilter(
  Map<String, dynamic> data,
  LedgerFilterSelection selection,
) {
  bool keepExpense(Map<String, dynamic> item) {
    if (!selection.hasExpense) return false;
    final category = item['category'] as String?;
    final method = normalizePaymentMethod(item['payment_method'] as String?);
    return (selection.expenseCategories.isEmpty ||
            selection.expenseCategories.contains(category)) &&
        (selection.paymentMethods.isEmpty ||
            selection.paymentMethods.contains(method));
  }

  bool keepIncome(Map<String, dynamic> item) =>
      selection.incomeCategories.contains(item['category'] as String?);

  var expenseCount = 0;
  var incomeCount = 0;
  var expenseTotal = 0;
  var incomeTotal = 0;
  final days = <Map<String, dynamic>>[];
  for (final day
      in (data['days'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()) {
    final expenses = (day['expenses'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where(keepExpense)
        .toList();
    final incomes = (day['incomes'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where(keepIncome)
        .toList();
    if (expenses.isEmpty && incomes.isEmpty) continue;
    final dayExpense = expenses.fold<int>(
      0,
      (sum, item) => sum + (item['amount'] as int? ?? 0),
    );
    expenseCount += expenses.length;
    incomeCount += incomes.length;
    expenseTotal += dayExpense;
    incomeTotal += incomes.fold<int>(
      0,
      (sum, item) => sum + (item['amount'] as int? ?? 0),
    );
    days.add({
      ...day,
      'expenses': expenses,
      'incomes': incomes,
      'total_expense_amount': dayExpense,
    });
  }
  return {
    ...data,
    'days': days,
    'expense_count': expenseCount,
    'income_count': incomeCount,
    'total_expense_amount': expenseTotal,
    'total_income_amount': incomeTotal,
    'balance': incomeTotal - expenseTotal,
    'unfiltered_total_expense_amount':
        data['unfiltered_total_expense_amount'] ?? data['total_expense_amount'],
    'unfiltered_total_income_amount':
        data['unfiltered_total_income_amount'] ?? data['total_income_amount'],
  };
}

/// 가계_002-01 필터 시트를 띄운다. [N건 보기]를 누르면 고른 조건을 돌려준다.
/// [tabType]: 0 전체 / 1 지출 / 2 수입
Future<LedgerFilterSelection?> showLedgerFilterSheet(
  BuildContext context, {
  required int tabType,
  required LedgerFilterSelection initial,
  required FinanceService? financeService,
  required String period,
  required DateTime anchor,
  CategoryService? categoryService,
}) => showGeneralDialog<LedgerFilterSelection>(
  context: context,
  barrierDismissible: false,
  barrierLabel: '필터',
  barrierColor: Colors.transparent,
  transitionDuration: const Duration(milliseconds: 150),
  transitionBuilder: (context, animation, secondaryAnimation, child) =>
      FadeTransition(opacity: animation, child: child),
  pageBuilder: (dialogContext, animation, secondaryAnimation) => Material(
    color: Colors.transparent,
    child: LedgerFilterSheet(
      tabType: tabType,
      initial: initial,
      financeService: financeService,
      categoryService:
          categoryService ??
          (financeService is CategoryService
              ? financeService as CategoryService
              : null),
      period: period,
      anchor: anchor,
    ),
  ),
);

class LedgerFilterSheet extends StatefulWidget {
  const LedgerFilterSheet({
    required this.tabType,
    required this.initial,
    required this.financeService,
    required this.categoryService,
    required this.period,
    required this.anchor,
    super.key,
  });

  final int tabType;
  final LedgerFilterSelection initial;
  final FinanceService? financeService;
  final CategoryService? categoryService;
  final String period;
  final DateTime anchor;

  @override
  State<LedgerFilterSheet> createState() => _LedgerFilterSheetState();
}

class _LedgerFilterSheetState extends State<LedgerFilterSheet> {
  late final Set<String> _expenseCategories = {
    ...widget.initial.expenseCategories,
  };
  late final Set<String> _paymentMethods = {...widget.initial.paymentMethods};
  late final Set<String> _incomeCategories = {
    ...widget.initial.incomeCategories,
  };
  late CategoryKind _side = widget.tabType == 2
      ? CategoryKind.income
      : widget.tabType == 0 &&
            widget.initial.hasIncome &&
            !widget.initial.hasExpense
      ? CategoryKind.income
      : CategoryKind.expense;
  int? _count;
  bool _countLoading = false;
  int _generation = 0;
  CategoryItem? _menuFor;
  Rect? _menuRect;
  final _stackKey = GlobalKey();
  final _chipKeys = <String, GlobalKey>{};

  LedgerFilterSelection get _selection => LedgerFilterSelection(
    expenseCategories: {..._expenseCategories},
    paymentMethods: {..._paymentMethods},
    incomeCategories: {..._incomeCategories},
  );

  List<CategoryItem> get _categories => CategoryStore.instance.of(_side);

  @override
  void initState() {
    super.initState();
    CategoryStore.instance.addListener(_onStoreChanged);
    _loadCategories();
    _loadCount();
  }

  @override
  void dispose() {
    CategoryStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCategories() async {
    final service = widget.categoryService;
    if (service == null) return;
    try {
      await CategoryStore.instance.loadAll(service);
    } catch (_) {
      // 목록 조회에 실패하면 기본 카테고리로 표시한다.
    }
  }

  Future<void> _loadCount() async {
    final service = widget.financeService;
    if (service == null) return;
    final generation = ++_generation;
    setState(() => _countLoading = true);
    final selection = _selection;
    final tabType = const ['all', 'expense', 'income'][widget.tabType];
    try {
      int count;
      if (!selection.isMixed && service is LedgerFilterService) {
        final summary = await (service as LedgerFilterService).ledgerSummary(
          period: widget.period,
          anchor: widget.anchor,
          type: selection.serverType(tabType),
          categories: selection.expenseCategories.toList(),
          paymentMethods: selection.paymentMethods.toList(),
          incomeCategories: selection.incomeCategories.toList(),
        );
        count =
            (summary['expense_count'] as int? ?? 0) +
            (summary['income_count'] as int? ?? 0);
      } else {
        final data = await loadFilteredLedger(
          service,
          period: widget.period,
          anchor: widget.anchor,
          tabType: tabType,
          selection: selection,
        );
        count =
            (data['expense_count'] as int? ?? 0) +
            (data['income_count'] as int? ?? 0);
      }
      if (mounted && generation == _generation) setState(() => _count = count);
    } catch (_) {
      // 이전 건수를 유지한다.
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _countLoading = false);
      }
    }
  }

  void _toggle(Set<String> values, String value) {
    setState(() {
      values.contains(value) ? values.remove(value) : values.add(value);
    });
    _loadCount();
  }

  void _reset() {
    setState(() {
      _expenseCategories.clear();
      _paymentMethods.clear();
      _incomeCategories.clear();
    });
    _loadCount();
  }

  Future<void> _add() async {
    final kind = _side;
    if (_categories.length >= kind.maxCount) {
      showTopToast(
        context,
        '${kind.label} 카테고리는 최대 ${kind.maxCount}개까지 만들 수 있어요',
        error: true,
      );
      return;
    }
    final service = widget.categoryService;
    if (service == null) return;
    final saved = await showCategoryEditor(
      context,
      kind: kind,
      service: service,
    );
    if (saved == null || !mounted) return;
    await _afterSaved(service, kind);
  }

  Future<void> _afterSaved(CategoryService service, CategoryKind kind) async {
    try {
      await CategoryStore.instance.load(service, kind);
    } catch (_) {}
    if (mounted) showTopToast(context, '카테고리를 저장했어요');
  }

  void _longPress(CategoryItem category) {
    if (category.isDefault) {
      showTopToast(context, '기본 카테고리는 수정·삭제할 수 없어요', error: true);
      return;
    }
    final chipBox =
        _chipKeys[category.name]?.currentContext?.findRenderObject()
            as RenderBox?;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (chipBox == null || stackBox == null) return;
    final topLeft = chipBox.localToGlobal(Offset.zero, ancestor: stackBox);
    setState(() {
      _menuFor = category;
      _menuRect = topLeft & chipBox.size;
    });
  }

  void _closeMenu() => setState(() {
    _menuFor = null;
    _menuRect = null;
  });

  Future<void> _edit(CategoryItem category) async {
    _closeMenu();
    final service = widget.categoryService;
    if (service == null) return;
    final saved = await showCategoryEditor(
      context,
      kind: category.kind,
      service: service,
      existing: category,
    );
    if (saved == null || !mounted) return;
    final values = category.kind == CategoryKind.expense
        ? _expenseCategories
        : _incomeCategories;
    if (values.remove(category.name)) values.add(saved.name);
    await _afterSaved(service, category.kind);
  }

  Future<void> _delete(CategoryItem category) async {
    _closeMenu();
    final service = widget.categoryService;
    if (service == null) return;
    final deleted = await runCategoryDeleteFlow(
      context,
      category: category,
      service: service,
      sameKindCategories: CategoryStore.instance.of(category.kind),
    );
    if (!deleted || !mounted) return;
    (category.kind == CategoryKind.expense
            ? _expenseCategories
            : _incomeCategories)
        .remove(category.name);
    try {
      await CategoryStore.instance.load(service, category.kind);
    } catch (_) {}
    _loadCount();
  }

  @override
  Widget build(BuildContext context) => P2DesignFrame(
    child: Stack(
      key: _stackKey,
      children: [
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: const ColoredBox(color: P2Colors.dim),
            ),
          ),
        ),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              key: const Key('ledger-filter-scroll'),
              padding: const EdgeInsets.only(bottom: 121),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 121,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 25),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: _content(),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(left: 0, right: 0, bottom: 0, child: _bottomBar()),
        if (_menuFor case final category?) ..._menu(category),
      ],
    ),
  );

  List<Widget> _content() => [
    P2CloseIcon(
      key: const Key('close-ledger-filter'),
      label: '필터',
      onTap: () => Navigator.of(context).pop(),
    ),
    const SizedBox(height: 26),
    if (widget.tabType == 0) ...[_switch(), const SizedBox(height: 26)],
    _categoryHeader(),
    const SizedBox(height: 26),
    _categoryGrid(),
    if (_side == CategoryKind.expense) ...[
      const SizedBox(height: 26),
      const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '결제수단',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            height: 24 / 20,
          ),
        ),
      ),
      const SizedBox(height: 26),
      _paymentGrid(),
    ],
  ];

  Widget _switch() {
    Widget button(CategoryKind kind, int count) {
      final active = _side == kind;
      return Expanded(
        child: GestureDetector(
          key: Key('ledger-filter-side-${kind.apiValue}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _side = kind),
          child: Container(
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? P2Colors.lavender : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kind.label,
                  style: TextStyle(
                    color: active ? P2Colors.black : AppColors.text50,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 18 / 15,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? P2Colors.black : AppColors.text50,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: active ? P2Colors.lavender : P2Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: 354,
      height: 65,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.text20, width: .5),
      ),
      child: Row(
        children: [
          button(
            CategoryKind.expense,
            _expenseCategories.length + _paymentMethods.length,
          ),
          button(CategoryKind.income, _incomeCategories.length),
        ],
      ),
    );
  }

  Widget _categoryHeader() => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '카테고리',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          height: 24 / 20,
        ),
      ),
      SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              '직접 만든 카테고리는 꾹 눌러 수정·삭제할 수 있어요',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text80,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 21 / 12,
              ),
            ),
          ),
          Text(
            '중복 선택 가능',
            style: TextStyle(
              color: AppColors.text80,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 21 / 12,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _categoryGrid() {
    final values = _side == CategoryKind.expense
        ? _expenseCategories
        : _incomeCategories;
    return SizedBox(
      // Figma: 지출 칩 109 × 3 (x29부터), 수입 칩 112 × 3 (x25부터), 간격 8.
      width: _side == CategoryKind.income ? 352 : 343,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final category in _categories)
            KeyedSubtree(
              key: _chipKeys.putIfAbsent(category.name, GlobalKey.new),
              child: P2CategoryChip(
                category: category,
                selected: values.contains(category.name),
                onTap: () => _toggle(values, category.name),
                onLongPress: () => _longPress(category),
              ),
            ),
          if (widget.categoryService != null) P2AddCategoryChip(onTap: _add),
        ],
      ),
    );
  }

  Widget _paymentGrid() => Wrap(
    spacing: 9,
    runSpacing: 8,
    children: [
      for (final method in paymentMethods)
        P2TextChip(
          key: Key('ledger-payment-$method'),
          label: method,
          width: 112,
          selected: _paymentMethods.contains(method),
          onTap: () => _toggle(_paymentMethods, method),
        ),
    ],
  );

  Widget _bottomBar() => Container(
    padding: const EdgeInsets.fromLTRB(24, 25, 24, 40),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0, .795],
        colors: [Color(0x00121215), Color(0xE6121215)],
      ),
    ),
    child: Row(
      children: [
        P2Button(
          key: const Key('reset-ledger-filter'),
          label: '초기화',
          tone: P2ButtonTone.grey,
          width: 99,
          onPressed: _reset,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: P2Button(
            key: const Key('apply-ledger-filter'),
            label: _countLoading && _count == null
                ? '조회 중...'
                : '${_count ?? 0}건 보기',
            width: null,
            onPressed: () => Navigator.of(context).pop(_selection),
          ),
        ),
      ],
    ),
  );

  List<Widget> _menu(CategoryItem category) {
    final rect = _menuRect!;
    final menuTop = (rect.top - 111).clamp(24.0, double.infinity);
    final menuLeft = (rect.right - 250).clamp(24.0, 402 - 24 - 250.0);
    return [
      Positioned.fill(
        child: GestureDetector(
          key: const Key('category-menu-barrier'),
          onTap: _closeMenu,
          // Figma 2086-35301: 흐림 없이 검정 46% 딤.
          child: const ColoredBox(color: Color(0x75000000)),
        ),
      ),
      Positioned(
        left: rect.left,
        top: rect.top,
        child: P2CategoryChip(category: category, highlighted: true),
      ),
      Positioned(
        left: menuLeft,
        top: menuTop,
        child: Container(
          width: 250,
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 10),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.text10, width: .5),
          ),
          decoration: BoxDecoration(
            color: const Color(0xE62A2B33),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 40,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _menuItem(
                key: const Key('category-menu-edit'),
                icon: p2MenuEditIcon,
                label: '카테고리 수정',
                color: Colors.white,
                onTap: () => _edit(category),
              ),
              _menuItem(
                key: const Key('category-menu-delete'),
                icon: p2MenuDeleteIcon,
                label: '카테고리 삭제',
                color: const Color(0xFFFF4D8D),
                onTap: () => _delete(category),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _menuItem({
    required Key key,
    required String icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) => GestureDetector(
    key: key,
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.only(left: 22),
        child: Row(
          children: [
            SvgPicture.asset(icon, width: 34, height: 34),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w400,
                height: 20 / 17,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
