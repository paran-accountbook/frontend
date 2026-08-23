import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/design_canvas.dart';

class RegisterTypeScreen extends StatelessWidget {
  const RegisterTypeScreen({super.key, this.onExpense, this.onIncome});

  final VoidCallback? onExpense;
  final VoidCallback? onIncome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        child: Stack(
          children: [
            const Positioned(
              left: 46,
              top: 144,
              child: Text(
                '등록',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 50,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Positioned(
              left: 46,
              top: 250,
              child: Text(
                '무엇을 기록할까요?',
                style: TextStyle(color: AppColors.text80, fontSize: 29),
              ),
            ),
            Positioned(
              left: 46,
              top: 748,
              child: _RegisterChoice(label: '소비 등록', onTap: onExpense),
            ),
            Positioned(
              left: 46,
              top: 850,
              child: _RegisterChoice(label: '수입 등록', onTap: onIncome),
            ),
            const Positioned(
              left: 0,
              top: 1459,
              child: AppBottomNavigation(selectedIndex: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterChoice extends StatelessWidget {
  const _RegisterChoice({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 653,
        height: 78,
        child: Row(
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.main,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(dimension: 20),
            ),
            const SizedBox(width: 31),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 39,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text('〉', style: TextStyle(color: AppColors.text50, fontSize: 44)),
          ],
        ),
      ),
    );
  }
}
