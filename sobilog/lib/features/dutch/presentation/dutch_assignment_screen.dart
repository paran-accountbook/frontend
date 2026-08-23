import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';

class DutchAssignmentScreen extends StatelessWidget {
  const DutchAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DesignCanvas(
      child: Stack(
        children: [
          const Positioned(
            left: 46,
            top: 144,
            child: Text(
              '항목별 인원 배정',
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
              '배정 완료 -/- 품목',
              style: TextStyle(color: AppColors.text80, fontSize: 29),
            ),
          ),
          const Positioned(
            left: 57,
            top: 329,
            child: SizedBox(
              width: 635,
              child: Divider(color: AppColors.outline),
            ),
          ),
          const Positioned(
            left: 46,
            top: 377,
            child: Text(
              '커피',
              style: TextStyle(
                color: AppColors.text,
                fontFamily: 'BujangnimNunchi',
                fontSize: 42,
                height: 1,
              ),
            ),
          ),
          Positioned(
            left: 47,
            top: 425,
            child: Text(
              'X 34',
              style: TextStyle(color: AppColors.text50, fontSize: 22),
            ),
          ),
          Positioned(
            right: 47,
            top: 382,
            child: Row(
              children: [
                const Text(
                  '150,000',
                  style: TextStyle(
                    color: AppColors.text,
                    fontFamily: 'Amarante',
                    fontSize: 42,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                SvgPicture.asset(AppAssets.wonLight, width: 30, height: 32),
              ],
            ),
          ),
          Positioned(
            left: 57,
            top: 1458,
            child: _ActionButton(
              label: '이전',
              gradient: false,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          const Positioned(
            left: 386,
            top: 1458,
            child: _ActionButton(label: '다음', gradient: true),
          ),
        ],
      ),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.gradient,
    this.onTap,
  });
  final String label;
  final bool gradient;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 306,
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient
              ? const [Color(0xFF33298F), AppColors.main]
              : const [Color(0xFF121215), Color(0xFF454650)],
        ),
        borderRadius: BorderRadius.circular(29),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
