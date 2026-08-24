import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../home/presentation/home_screen.dart';
import '../../ledger/presentation/ledger_screen.dart';
import '../../register/presentation/register_type_screen.dart';

class AnalysisGoalScreen extends StatelessWidget {
  const AnalysisGoalScreen({
    required this.background,
    super.key,
    this.onNavigationSelected,
  });

  final Widget background;
  final ValueChanged<int>? onNavigationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        height: 1628,
        child: Stack(
          children: [
            Positioned.fill(child: background),
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
            const Positioned(left: 46, top: 673, child: _GoalDialog()),
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
    if (onNavigationSelected case final callback?) {
      callback(index);
      return;
    }

    final Widget? destination = switch (index) {
      0 => const HomeScreen(),
      1 => const LedgerScreen(),
      2 => const RegisterTypeScreen(),
      _ => null,
    };
    if (destination == null) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
  }
}

class _GoalDialog extends StatelessWidget {
  const _GoalDialog();

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
                const Text(
                  '150,000',
                  style: TextStyle(
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
            child: Center(
              child: SvgPicture.asset(
                AppAssets.editLight,
                width: 31.34,
                height: 30,
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
          const Positioned(
            left: 46,
            top: 276,
            child: _GoalChip(label: '수입의 50%', width: 172, selected: true),
          ),
          const Positioned(
            left: 235,
            top: 278,
            child: _GoalChip(label: '수입의 60%', width: 170),
          ),
          const Positioned(
            left: 422,
            top: 278,
            child: _GoalChip(label: '수입의 80%', width: 170),
          ),
          const Positioned(
            left: 609,
            top: 278,
            child: _GoalChip(label: '직접 입력', width: 140),
          ),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.label,
    required this.width,
    this.selected = false,
  });

  final String label;
  final double width;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: selected ? 59 : 55,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.text : Colors.transparent,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.text, width: selected ? 3 : 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.background : AppColors.text,
          fontSize: 25,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}
