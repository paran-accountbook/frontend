import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../../../shared/widgets/app_chevron.dart';
import '../../../shared/widgets/design_canvas.dart';
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
  final _categories = const ['급여', '용돈', '부수입', '환급·환불', '기타'];
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
    final categoryIndex = category == null ? -1 : _categories.indexOf(category);
    if (categoryIndex >= 0) _category = categoryIndex;
    _incomeDate =
        DateTime.tryParse(data?['income_date'] as String? ?? '') ??
        DateTime.now();
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
    final selected = await showDatePicker(
      context: context,
      initialDate: _incomeDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.background,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '카테고리',
                style: TextStyle(color: AppColors.text, fontSize: 15),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 10,
                children: List.generate(
                  _categories.length,
                  (index) => ChoiceChip(
                    label: Text(_categories[index]),
                    selected: _category == index,
                    onSelected: (_) => Navigator.pop(context, index),
                  ),
                ),
              ),
            ],
          ),
        ),
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
              ],
            ),
          ),
          AuthBottomAction(
            label: _isLoading ? '저장 중...' : (_isEditing ? '수정 완료' : '저장'),
            onPressed: _isLoading ? () {} : _save,
          ),
        ],
      ),
    ),
  );
}

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
