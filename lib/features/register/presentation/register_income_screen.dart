import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/form_save_button.dart';
import '../../../shared/widgets/app_chevron.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../category/data/category_models.dart';
import '../../category/data/category_service.dart';
import '../../finance/data/finance_service.dart';
import '../../ledger/presentation/ledger_screen.dart';

class RegisterIncomeScreen extends StatefulWidget {
  const RegisterIncomeScreen({
    super.key,
    this.financeService,
    this.incomeId,
    this.initialData,
  });
  final FinanceService? financeService;
  final String? incomeId;
  final Map<String, dynamic>? initialData;

  @override
  State<RegisterIncomeScreen> createState() => _RegisterIncomeScreenState();
}

class _RegisterIncomeScreenState extends State<RegisterIncomeScreen> {
  final _amount = TextEditingController();
  final _memo = TextEditingController();
  final _categories = categoryNames(CategoryKind.income);
  int _category = 0;
  late DateTime _incomeDate;
  bool _isLoading = false;
  String? _error;

  bool get _isEditing => widget.incomeId != null;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _amount.text = data?['amount']?.toString() ?? '';
    _memo.text = data?['memo'] as String? ?? '';
    final category = data?['category'] as String?;
    if (category != null &&
        category.isNotEmpty &&
        !_categories.contains(category)) {
      _categories.add(category);
    }
    final categoryIndex = _categories.indexOf(category ?? '');
    if (categoryIndex >= 0) _category = categoryIndex;
    _incomeDate =
        DateTime.tryParse(data?['income_date'] as String? ?? '') ??
        DateTime.now();
    _refreshCategories();
  }

  /// 필터 시트에서 직접 만든 수입 카테고리도 선택 목록에 보여준다.
  Future<void> _refreshCategories() async {
    await preloadCategories(widget.financeService);
    if (!mounted) return;
    final current = _categories[_category];
    setState(() {
      _categories
        ..clear()
        ..addAll(categoryNames(CategoryKind.income, including: current));
      _category = _categories.indexOf(current).clamp(0, _categories.length - 1);
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = int.tryParse(_amount.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      setState(() => _error = '수입 금액을 입력해 주세요');
      return;
    }
    final service = widget.financeService;
    if (service == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final payload = <String, Object?>{
        'amount': amount,
        'income_date': _incomeDate.toIso8601String().substring(0, 10),
        'category': _categories[_category],
        'memo': _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      };
      final saved = _isEditing
          ? await service.updateIncome(widget.incomeId!, payload)
          : await service.createIncome(payload);
      if (!mounted) return;
      if (_isEditing) {
        Navigator.of(context).pop(IncomeEditResult.updated(saved));
        return;
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LedgerScreen(financeService: service),
      ),
      (_) => false,
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDialog<DateTime>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => _IncomeDateDialog(initialValue: _incomeDate),
    );
    if (selected != null && mounted) setState(() => _incomeDate = selected);
  }

  Future<void> _editAmount() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _IncomeAmountDialog(initialValue: _amount.text),
    );
    if (result != null && mounted) {
      setState(() {
        _amount.text = result;
        _error = null;
      });
    }
  }

  Future<void> _selectCategory() async {
    final selected = await showDialog<int>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => _IncomeCategoryDialog(
        categories: _categories,
        selectedIndex: _category,
      ),
    );
    if (selected != null && mounted) setState(() => _category = selected);
  }

  Future<void> _delete() async {
    final service = widget.financeService;
    final id = widget.incomeId;
    if (service == null || id == null || _isLoading) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('수입 내역 삭제'),
        content: const Text('삭제한 내역은 되돌릴 수 없습니다. 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            key: const Key('confirm-delete-income'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await service.deleteIncome(id);
      if (mounted) Navigator.of(context).pop(const IncomeEditResult.deleted());
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DesignCanvas(
      fitWidthWithKeyboard: MediaQuery.viewInsetsOf(context).bottom > 0,
      child: Stack(
        children: [
          const ColoredBox(color: AppColors.background),
          Positioned(
            left: 24,
            top: 50,
            width: 34,
            height: 34,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: SvgPicture.asset(AppAssets.arrowBackLight),
            ),
          ),
          Positioned(
            left: 24,
            top: 125,
            child: Text(
              _isEditing ? '수입 수정' : '수입 등록',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 27,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            top: 192,
            bottom: 0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  SvgPicture.asset(
                    AppAssets.asteriskDividerDark,
                    width: 354,
                    height: 8,
                    fit: BoxFit.fill,
                  ),
                  const SizedBox(height: 26),
                  _IncomeFieldRow(
                    key: const Key('income-amount-row'),
                    label: '금액',
                    value: '${_formatAmount(int.tryParse(_amount.text) ?? 0)}원',
                    valueKey: const Key('income-amount-value'),
                    chevronKey: const Key('income-amount-chevron'),
                    onTap: _editAmount,
                  ),
                  const SizedBox(height: 16),
                  _IncomeFieldRow(
                    key: const Key('income-date-picker'),
                    label: '수입일',
                    value: _formatIncomeDate(_incomeDate),
                    valueKey: const Key('income-date-value'),
                    chevronKey: const Key('income-date-chevron'),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 16),
                  _IncomeFieldRow(
                    key: const Key('income-category-picker'),
                    label: '카테고리',
                    value: _categories[_category],
                    valueKey: const Key('income-category-value'),
                    chevronKey: const Key('income-category-chevron'),
                    onTap: _selectCategory,
                  ),
                  const SizedBox(height: 26),
                  SvgPicture.asset(
                    AppAssets.asteriskDividerDark,
                    width: 354,
                    height: 8,
                    fit: BoxFit.fill,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 92,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _memo,
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      maxLength: 500,
                      maxLines: 2,
                      style: const TextStyle(
                        color: AppColors.text80,
                        fontSize: 12,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        labelText: '메모 (선택)',
                        labelStyle: TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        key: const Key('delete-income'),
                        onPressed: _delete,
                        child: const Text(
                          '수입 내역 삭제',
                          style: TextStyle(color: Color(0xFFCF376A)),
                        ),
                      ),
                    ),
                  ],
                  if (_error case final message?) ...[
                    const SizedBox(height: 14),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Color(0xFFFF6B7A),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FormSaveButton(
                    keyboardVisible:
                        MediaQuery.viewInsetsOf(context).bottom > 0,
                    label: _isLoading
                        ? '저장 중...'
                        : (_isEditing ? '수정 완료' : '저장'),
                    onPressed: _isLoading ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _IncomeCategoryDialog extends StatefulWidget {
  const _IncomeCategoryDialog({
    required this.categories,
    required this.selectedIndex,
  });

  final List<String> categories;
  final int selectedIndex;

  @override
  State<_IncomeCategoryDialog> createState() => _IncomeCategoryDialogState();
}

class _IncomeCategoryDialogState extends State<_IncomeCategoryDialog> {
  late int _selectedIndex = widget.selectedIndex;

  @override
  Widget build(BuildContext context) => _IncomePickerDialog(
    title: '카테고리',
    closeKey: const Key('close-income-category-picker'),
    completeKey: const Key('complete-income-category-picker'),
    onComplete: () => Navigator.pop(context, _selectedIndex),
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var index = 0; index < widget.categories.length; index++)
          ChoiceChip(
            key: ValueKey('income-category-option-$index'),
            label: Text(widget.categories[index]),
            selected: _selectedIndex == index,
            selectedColor: const Color(0xFFA8A3FF),
            labelStyle: TextStyle(
              color: _selectedIndex == index ? Colors.black : AppColors.text80,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            showCheckmark: false,
            shape: const StadiumBorder(),
            backgroundColor: AppColors.selected,
            side: const BorderSide(color: AppColors.text20, width: .5),
            onSelected: (_) => setState(() => _selectedIndex = index),
          ),
      ],
    ),
  );
}

class _IncomeDateDialog extends StatefulWidget {
  const _IncomeDateDialog({required this.initialValue});
  final DateTime initialValue;

  @override
  State<_IncomeDateDialog> createState() => _IncomeDateDialogState();
}

class _IncomeDateDialogState extends State<_IncomeDateDialog> {
  late DateTime value = DateUtils.dateOnly(widget.initialValue);

  @override
  Widget build(BuildContext context) => _IncomePickerDialog(
    title: '수입일',
    closeKey: const Key('close-income-date-picker'),
    completeKey: const Key('complete-income-date-picker'),
    onComplete: () => Navigator.pop(context, value),
    child: SizedBox(
      height: 173,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 59,
            decoration: BoxDecoration(
              color: AppColors.selected,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.text20),
            ),
          ),
          _IncomeDateWheels(
            key: const Key('income-date-wheel'),
            initialValue: value,
            onChanged: (next) => value = next,
          ),
        ],
      ),
    ),
  );
}

class _IncomePickerDialog extends StatelessWidget {
  const _IncomePickerDialog({
    required this.title,
    required this.closeKey,
    required this.completeKey,
    required this.onComplete,
    required this.child,
  });

  final String title;
  final Key closeKey;
  final Key completeKey;
  final VoidCallback onComplete;
  final Widget child;

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    backgroundColor: Colors.transparent,
    child: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: ColoredBox(
          color: const Color(0x80121215),
          child: SafeArea(
            minimum: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: IconButton(
                      key: closeKey,
                      tooltip: '닫기',
                      onPressed: () => Navigator.pop(context),
                      icon: SvgPicture.asset(AppAssets.closeLight),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(title, textAlign: TextAlign.center),
                  const Divider(height: 32, color: AppColors.text20),
                  Flexible(child: SingleChildScrollView(child: child)),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      key: completeKey,
                      onPressed: onComplete,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.main,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('완료'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _IncomeDateWheels extends StatefulWidget {
  const _IncomeDateWheels({
    required this.initialValue,
    required this.onChanged,
    super.key,
  });

  final DateTime initialValue;
  final ValueChanged<DateTime> onChanged;

  @override
  State<_IncomeDateWheels> createState() => _IncomeDateWheelsState();
}

class _IncomeDateWheelsState extends State<_IncomeDateWheels> {
  late DateTime value = widget.initialValue;
  late final List<int> years = [value.year - 1, value.year, value.year + 1];

  void _update({int? year, int? month, int? day}) {
    final nextYear = year ?? value.year;
    final nextMonth = month ?? value.month;
    final maxDay = DateUtils.getDaysInMonth(nextYear, nextMonth);
    final next = DateTime(
      nextYear,
      nextMonth,
      (day ?? value.day).clamp(1, maxDay),
    );
    setState(() => value = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final days = DateUtils.getDaysInMonth(value.year, value.month);
    return CupertinoTheme(
      data: const CupertinoThemeData(brightness: Brightness.dark),
      child: Row(
        children: [
          Expanded(
            flex: 81,
            child: _IncomeWheel(
              itemCount: years.length,
              selectedItem: years.indexOf(value.year),
              itemBuilder: (index, selected) => _dateWheelNumber(
                '${years[index]}',
                suffix: selected ? '년' : null,
                selected: selected,
              ),
              onSelected: (index) => _update(year: years[index]),
            ),
          ),
          Expanded(
            flex: 51,
            child: _IncomeWheel(
              itemCount: 12,
              selectedItem: value.month - 1,
              itemBuilder: (index, selected) => _dateWheelNumber(
                '${index + 1}',
                suffix: selected ? '월' : null,
                selected: selected,
              ),
              onSelected: (index) => _update(month: index + 1),
            ),
          ),
          Expanded(
            flex: 58,
            child: _IncomeWheel(
              itemCount: days,
              selectedItem: value.day - 1,
              itemBuilder: (index, selected) => _dateWheelNumber(
                '${index + 1}',
                suffix: selected ? '일' : null,
                selected: selected,
              ),
              onSelected: (index) => _update(day: index + 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeWheel extends StatefulWidget {
  const _IncomeWheel({
    required this.itemCount,
    required this.selectedItem,
    required this.itemBuilder,
    required this.onSelected,
  });

  final int itemCount;
  final int selectedItem;
  final Widget Function(int index, bool selected) itemBuilder;
  final ValueChanged<int> onSelected;

  @override
  State<_IncomeWheel> createState() => _IncomeWheelState();
}

class _IncomeWheelState extends State<_IncomeWheel> {
  late final _controller = FixedExtentScrollController(
    initialItem: widget.selectedItem,
  );

  @override
  void didUpdateWidget(covariant _IncomeWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount == widget.itemCount) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _controller.hasClients &&
          _controller.selectedItem != widget.selectedItem) {
        _controller.jumpToItem(widget.selectedItem);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CupertinoPicker.builder(
    scrollController: _controller,
    itemExtent: 59,
    diameterRatio: 1.15,
    squeeze: 1,
    useMagnifier: false,
    selectionOverlay: const SizedBox.shrink(),
    childCount: widget.itemCount,
    onSelectedItemChanged: widget.onSelected,
    itemBuilder: (context, index) => Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: widget.itemBuilder(index, index == widget.selectedItem),
      ),
    ),
  );
}

Widget _dateWheelNumber(
  String value, {
  String? suffix,
  required bool selected,
}) => Text.rich(
  TextSpan(
    children: [
      TextSpan(
        text: value,
        style: TextStyle(
          color: selected ? AppColors.text : AppColors.text20,
          fontFamily: 'Amarante',
          fontSize: 20,
          fontWeight: FontWeight.w400,
        ),
      ),
      if (suffix != null) ...[
        const WidgetSpan(child: SizedBox(width: 6)),
        TextSpan(
          text: suffix,
          style: const TextStyle(
            color: AppColors.text80,
            fontFamily: 'Pretendard',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ],
  ),
  maxLines: 1,
);

class _IncomeAmountDialog extends StatefulWidget {
  const _IncomeAmountDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_IncomeAmountDialog> createState() => _IncomeAmountDialogState();
}

class _IncomeAmountDialogState extends State<_IncomeAmountDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('수입 금액'),
    content: TextField(
      key: const Key('income-amount-input'),
      controller: _controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(suffixText: '원'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text),
        child: const Text('확인'),
      ),
    ],
  );
}

class IncomeEditResult {
  const IncomeEditResult.updated(this.data) : deleted = false;
  const IncomeEditResult.deleted() : deleted = true, data = const {};

  final bool deleted;
  final Map<String, dynamic> data;
}

class _IncomeFieldRow extends StatelessWidget {
  const _IncomeFieldRow({
    required this.label,
    required this.value,
    required this.valueKey,
    required this.chevronKey,
    required this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final Key valueKey;
  final Key chevronKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      height: 36,
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.text50, fontSize: 14),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              key: valueKey,
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.text, fontSize: 14),
            ),
          ),
          const SizedBox(width: 6),
          AppChevron(key: chevronKey, size: 24),
        ],
      ),
    ),
  );
}

String _formatAmount(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (match) => ',',
);

String _formatIncomeDate(DateTime value) {
  return '${value.year}년 ${value.month}월 ${value.day}일';
}
