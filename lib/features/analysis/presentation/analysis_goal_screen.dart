import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../finance/data/finance_service.dart';
import '../../home/presentation/home_screen.dart';
import '../../ledger/presentation/ledger_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../register/presentation/register_type_screen.dart';

/// 분석_002: 월간 지출 목표 설정/수정 화면.
class AnalysisGoalScreen extends StatefulWidget {
  const AnalysisGoalScreen({
    required this.background,
    super.key,
    this.onNavigationSelected,
    this.year,
    this.month,
    this.initialAmount = 150000,
    this.monthlyIncome,
    this.financeService,
    this.onSaved,
  });

  final Widget background;
  final ValueChanged<int>? onNavigationSelected;
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
    return Scaffold(
      body: DesignCanvas(
        width: 749,
        height: 1628,
        child: Stack(
          children: [
            Positioned.fill(child: widget.background),
            const Positioned.fill(child: ColoredBox(color: Color(0xCC121215))),
            Positioned(
              left: 342,
              top: 577,
              width: 64,
              height: 64,
              child: GestureDetector(
                key: const ValueKey('analysis-goal-close'),
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: Center(
                  child: SvgPicture.asset(
                    AppAssets.closeLight,
                    width: 28,
                    height: 28,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 46,
              top: 673,
              child: _GoalDialog(
                amount: _amount,
                onEdit: _editAmount,
                percentAmount: _percentAmount,
                onSelectPercent: (amount) => setState(() => _amount = amount),
              ),
            ),
            Positioned(
              left: 46,
              top: 1070,
              child: GestureDetector(
                onTap: _isSaving ? null : _save,
                child: Container(
                  width: 656,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF252552), AppColors.main],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0x4DE2E2F9)),
                  ),
                  child: Text(
                    _isSaving ? '저장 중...' : '목표 저장',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            if (_error case final message?)
              Positioned(
                left: 46,
                top: 1180,
                width: 656,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFFF6B7A), fontSize: 20),
                ),
              ),
            Positioned(
              left: 0,
              top: 1459,
              child: AppBottomNavigation(
                selectedIndex: 3,
                onSelected: (index) => _handleNavigation(context, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    if (widget.onNavigationSelected case final callback?) {
      callback(index);
      return;
    }

    final Widget? destination = switch (index) {
      0 => const HomeScreen(),
      1 => const LedgerScreen(),
      2 => const RegisterTypeScreen(),
      4 => const ProfileScreen(),
      _ => null,
    };
    if (destination == null) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
  }
}

class _GoalDialog extends StatelessWidget {
  const _GoalDialog({
    required this.amount,
    required this.onEdit,
    required this.percentAmount,
    required this.onSelectPercent,
  });

  final int amount;
  final VoidCallback onEdit;
  final int? Function(int percent) percentAmount;
  final ValueChanged<int> onSelectPercent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 656,
      height: 378,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(60),
        border: Border.all(color: AppColors.text30),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: -1,
            top: -1,
            width: 658,
            height: 189,
            child: ColoredBox(color: AppColors.secondary),
          ),
          const Positioned(
            left: 46,
            top: 37,
            child: Text(
              '지출 목표 설정',
              style: TextStyle(
                color: Color(0xCCE2E2F9),
                fontSize: 23,
                height: 1,
              ),
            ),
          ),
          Positioned(
            left: 47,
            top: 103,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatAmount(amount),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontFamily: 'Amarante',
                    fontSize: 40,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 5),
                SvgPicture.asset(AppAssets.wonLight, width: 29, height: 31),
              ],
            ),
          ),
          Positioned(
            left: 558,
            top: 96,
            width: 64,
            height: 64,
            child: GestureDetector(
              onTap: onEdit,
              child: Center(
                child: SvgPicture.asset(
                  AppAssets.editLight,
                  width: 31.34,
                  height: 30,
                ),
              ),
            ),
          ),
          const Positioned(
            left: 46,
            top: 217,
            child: Text(
              '수입 기준으로 설정',
              style: TextStyle(
                color: Color(0xCCE2E2F9),
                fontSize: 23,
                height: 1,
              ),
            ),
          ),
          Positioned(
            left: 46,
            top: 276,
            child: Row(
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
                _GoalChip(label: '직접 입력', onTap: onEdit),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
        height: selected ? 59 : 55,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.text : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: AppColors.text, width: selected ? 3 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.surface : AppColors.text,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1,
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
