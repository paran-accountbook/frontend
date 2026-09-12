import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.selectedIndex,
    super.key,
    this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  static const _assets = [
    AppAssets.navHome,
    AppAssets.navLedger,
    AppAssets.navRegister,
    AppAssets.navAnalysis,
    AppAssets.navProfile,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 749,
      height: 169,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                width: 612,
                height: 100,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xA6292929),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.07),
                      blurRadius: 30,
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, _buildItem),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(int index) {
    final selected = index == selectedIndex;
    final isRegister = index == 2;
    return GestureDetector(
      onTap: () => onSelected?.call(index),
      child: SizedBox(
        width: isRegister ? 96 : 73,
        height: 73,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (selected && !isRegister)
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.22),
                      blurRadius: 26,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
            if (isRegister)
              Container(
                width: 96,
                height: 73,
                decoration: BoxDecoration(
                  color: AppColors.main,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
            SvgPicture.asset(
              _assets[index],
              width: index == 4 ? 32 : (isRegister ? 50 : 43),
              height: isRegister ? 35 : 43,
              colorFilter: ColorFilter.mode(
                isRegister || selected ? Colors.white : Colors.white54,
                BlendMode.srcIn,
              ),
            ),
            if (selected && !isRegister)
              const Positioned(
                bottom: -2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(dimension: 8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
