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
      width: 402,
      height: 100,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00121215), Color(0xE6121215)],
                stops: [0, 0.8],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 42,
                  bottom: 46,
                  width: 318,
                  height: 30,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, _buildItem),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int index) {
    final selected = index == selectedIndex;
    final isRegister = index == 2;
    return Semantics(
      button: true,
      selected: selected,
      label: const ['홈', '가계부', '등록', '분석', '마이페이지'][index],
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected?.call(index),
        child: SizedBox(
          width: isRegister ? 48 : 30,
          height: 30,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (isRegister)
                Container(
                  width: 48,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.main,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.outline, width: 0.5),
                  ),
                ),
              SvgPicture.asset(
                _assets[index],
                width: isRegister ? 36 : 30,
                height: 30,
                colorFilter: ColorFilter.mode(
                  isRegister || selected ? Colors.white : Colors.white38,
                  BlendMode.srcIn,
                ),
              ),
              if (selected && !isRegister)
                const Positioned(
                  bottom: -5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(dimension: 4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
