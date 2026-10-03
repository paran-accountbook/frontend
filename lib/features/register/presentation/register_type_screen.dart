import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/app_chevron.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../analysis/presentation/analysis_overview_screen.dart';
import '../../finance/data/finance_service.dart';
import '../../home/presentation/home_screen.dart';
import '../../ledger/presentation/ledger_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'register_income_screen.dart';
import 'register_method_screen.dart';

class RegisterTypeScreen extends StatelessWidget {
  const RegisterTypeScreen({
    super.key,
    this.onExpense,
    this.onIncome,
    this.financeService,
    this.onNavigationSelected,
  });

  final VoidCallback? onExpense;
  final VoidCallback? onIncome;
  final FinanceService? financeService;
  final ValueChanged<int>? onNavigationSelected;

  @override
  Widget build(BuildContext context) {
    final expense =
        onExpense ??
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                RegisterMethodScreen(financeService: financeService),
          ),
        );
    final income =
        onIncome ??
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                RegisterIncomeScreen(financeService: financeService),
          ),
        );
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
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: SvgPicture.asset(AppAssets.arrowBackLight),
              ),
            ),
            const Positioned(
              left: 24,
              top: 128,
              child: Text(
                '등록',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Positioned(
              left: 24,
              top: 177,
              child: Text(
                '무엇을 기록할까요?',
                style: TextStyle(
                  color: Color(0xCCE2E2F9),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 393,
              child: _RegisterChoice(label: '소비 등록', onTap: expense),
            ),
            Positioned(
              left: 24,
              top: 447,
              child: _RegisterChoice(label: '수입 등록', onTap: income),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: AppBottomNavigation(
                selectedIndex: 2,
                onSelected: (index) => _navigate(context, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    if (onNavigationSelected case final callback?) {
      callback(index);
      return;
    }
    final Widget? destination = switch (index) {
      0 => HomeScreen(financeService: financeService),
      1 => LedgerScreen(financeService: financeService),
      3 => AnalysisOverviewScreen(financeService: financeService),
      4 => ProfileScreen(financeService: financeService),
      _ => null,
    };
    if (destination == null) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
  }
}

class _RegisterChoice extends StatelessWidget {
  const _RegisterChoice({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 354,
          height: 34,
          child: Row(
            children: [
              const SizedBox.square(
                dimension: 34,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.main,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(dimension: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const AppChevron(color: AppColors.text80),
            ],
          ),
        ),
      ),
    );
  }
}
