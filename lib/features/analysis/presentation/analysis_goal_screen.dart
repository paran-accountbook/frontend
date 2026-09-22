import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../finance/data/finance_service.dart';

/// 분석_002: 월간 지출 목표 설정/수정 화면.
class AnalysisGoalScreen extends StatefulWidget {
  const AnalysisGoalScreen({
    super.key,
    this.year,
    this.month,
    this.initialAmount = 150000,
    this.monthlyIncome,
    this.financeService,
    this.onSaved,
  });

  final int? year;
  final int? month;
  final int initialAmount;
  final int? monthlyIncome;
  final FinanceService? financeService;
  final ValueChanged<int>? onSaved;

  @override
  State<AnalysisGoalScreen> createState() => _AnalysisGoalScreenState();
}

class _AnalysisGoalScreenState extends State<AnalysisGoalScreen> {
  late int _amount;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amount = widget.initialAmount;
  }

  int? _percentAmount(int percent) {
    final income = widget.monthlyIncome;
    if (income == null || income <= 0) return null;
    return (income * percent / 100).round();
  }

  Future<void> _editAmount() async {
    final controller = TextEditingController(text: _amount.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지출 목표 직접 입력'),
        content: TextField(
          controller: controller,
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
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text) ?? _amount),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (result != null && result > 0) setState(() => _amount = result);
  }

  Future<void> _save() async {
    final service = widget.financeService;
    final year = widget.year;
    final month = widget.month;
    if (service == null || year == null || month == null) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await service.setMonthlyGoal(year: year, month: month, amount: _amount);
      if (!mounted) return;
      widget.onSaved?.call(_amount);
      Navigator.of(context).maybePop();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final year = widget.year ?? now.year;
    final month = widget.month ?? now.month;

    return Scaffold(
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
                key: const ValueKey('analysis-goal-close'),
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: SvgPicture.asset(AppAssets.arrowBackLight),
              ),
            ),
            const Positioned(
              left: 24,
              top: 128,
              child: Text(
                '지출 목표 설정',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 178,
              child: _GoalForm(
                year: year,
                month: month,
                amount: _amount,
                onEdit: _editAmount,
                percentAmount: _percentAmount,
                onSelectPercent: (amount) => setState(() => _amount = amount),
              ),
            ),
            if (_error case final message?)
              Positioned(
                left: 24,
                right: 24,
                bottom: 110,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFFF6B7A), fontSize: 14),
                ),
              ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 40,
              child: GestureDetector(
                onTap: _isSaving ? null : _save,
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.main,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isSaving ? '저장 중...' : '저장',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalForm extends StatelessWidget {
  const _GoalForm({
    required this.year,
    required this.month,
    required this.amount,
    required this.onEdit,
    required this.percentAmount,
    required this.onSelectPercent,
  });

  final int year;
  final int month;
  final int amount;
  final VoidCallback onEdit;
  final int? Function(int percent) percentAmount;
  final ValueChanged<int> onSelectPercent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 354,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AsteriskDivider(),
          const SizedBox(height: 20),
          Text(
            '$year년 $month월 목표 금액',
            style: const TextStyle(color: AppColors.text50, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatAmount(amount),
                    style: const TextStyle(
                      color: AppColors.text,
                      fontFamily: 'Amarante',
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SvgPicture.asset(AppAssets.wonLight, width: 16, height: 17),
                ],
              ),
              GestureDetector(
                onTap: onEdit,
                child: SvgPicture.asset(
                  AppAssets.editLight,
                  width: 17,
                  height: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _AsteriskDivider(),
          const SizedBox(height: 20),
          Row(
            children: [
              for (final percent in [50, 60, 80])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _GoalChip(
                    label: '수입의 $percent%',
                    selected: percentAmount(percent) == amount,
                    onTap: () {
                      final value = percentAmount(percent);
                      if (value != null) onSelectPercent(value);
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AsteriskDivider extends StatelessWidget {
  const _AsteriskDivider();

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    AppAssets.asteriskDividerDark,
    width: 354,
    height: 15,
    colorFilter: const ColorFilter.mode(Color(0xFFE2E2F9), BlendMode.srcIn),
  );
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.label, this.selected = false, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFA8A3FF) : AppColors.selected,
          border: Border.all(color: AppColors.outline, width: 0.5),
          borderRadius: BorderRadius.circular(30),
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
}

String _formatAmount(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return '${amount < 0 ? '-' : ''}$buffer';
}
