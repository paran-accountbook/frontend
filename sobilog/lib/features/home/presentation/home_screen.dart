import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../ledger/presentation/ledger_screen.dart';
import '../../register/presentation/register_type_screen.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/design_canvas.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onNavigationSelected});

  final ValueChanged<int>? onNavigationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFCECEFF),
                Color(0x00121215),
                AppColors.background,
              ],
              stops: [0.155, 0.545, 0.75],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 288,
                top: 104,
                width: 173,
                height: 35,
                child: Stack(
                  children: [
                    Positioned(
                      left: 36.3,
                      top: 1.3,
                      width: 136.7,
                      height: 33.2,
                      child: SvgPicture.asset(AppAssets.homeLogoWordmark),
                    ),
                    Positioned(
                      width: 34.9,
                      height: 35,
                      child: SvgPicture.asset(AppAssets.homeLogoSymbol),
                    ),
                  ],
                ),
              ),
              const Positioned(left: 33, top: 184, child: _SummaryCard()),
              const Positioned(
                left: 303,
                top: 664,
                child: Text(
                  '최근 등록 내역',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Positioned(
                left: 33,
                top: 737,
                child: Column(
                  children: [_RecentRow(), _RecentRow(), _RecentRow()],
                ),
              ),
              Positioned(
                left: 0,
                top: 1459,
                child: AppBottomNavigation(
                  selectedIndex: 0,
                  onSelected: (index) {
                    if (onNavigationSelected case final callback?) {
                      callback(index);
                      return;
                    }
                    if (index == 1) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => const LedgerScreen(),
                        ),
                      );
                    } else if (index == 2) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RegisterTypeScreen(),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 683,
      height: 442,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -26,
            top: -22,
            width: 735,
            height: 494,
            child: Stack(
              children: [
                Positioned.fill(
                  top: 4,
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 13, sigmaY: 13),
                    child: SvgPicture.asset(
                      AppAssets.homeReceipt,
                      fit: BoxFit.fill,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.2),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: SvgPicture.asset(
                    AppAssets.homeReceipt,
                    fit: BoxFit.fill,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            left: 51,
            top: 65,
            child: Text(
              '소비요약',
              style: TextStyle(
                color: Color(0xFF1B1B1B),
                fontSize: 25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            left: 440,
            top: 65,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.outline),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text(
                    '소비 요약 보러가기',
                    style: TextStyle(color: AppColors.background, fontSize: 20),
                  ),
                  const SizedBox(width: 10),
                  SvgPicture.asset(AppAssets.arrowSmall, width: 9, height: 10),
                ],
              ),
            ),
          ),
          const Positioned(left: 53, top: 128, child: _DarkAsterisks()),
          const Positioned(
            top: 165,
            width: 683,
            child: Text(
              '이번 달 총 지출액',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1B1B1B),
                fontFamily: 'BujangnimNunchi',
                fontSize: 55,
                height: 1,
              ),
            ),
          ),
          Positioned(
            top: 235,
            width: 683,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '총',
                  style: TextStyle(
                    color: Color(0xFF1B1B1B),
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  '150,000',
                  style: TextStyle(
                    color: Color(0xFF1B1B1B),
                    fontFamily: 'Amarante',
                    fontSize: 50,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 5),
                SvgPicture.asset(AppAssets.wonDark, width: 37, height: 41),
              ],
            ),
          ),
          const Positioned(left: 53, top: 323, child: _DarkAsterisks()),
          Positioned(
            left: 272,
            top: 369,
            width: 139,
            height: 29,
            child: SvgPicture.asset(AppAssets.homeBarcode),
          ),
        ],
      ),
    );
  }
}

class _DarkAsterisks extends StatelessWidget {
  const _DarkAsterisks();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 577,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          18,
          (_) => const Text(
            '*',
            style: TextStyle(
              color: Color(0x33121215),
              fontSize: 20,
              height: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 683,
      height: 148,
      child: Stack(
        children: [
          Positioned(
            left: 25,
            width: 633,
            child: SvgPicture.asset(AppAssets.divider),
          ),
          const Positioned(
            left: 13,
            top: 57,
            child: Text(
              '8/19',
              style: TextStyle(
                color: Color(0x80E2E2F9),
                fontFamily: 'Amarante',
                fontSize: 25,
              ),
            ),
          ),
          const Positioned(
            left: 85,
            top: 27,
            child: Text(
              '아주대학교 카페',
              style: TextStyle(
                color: AppColors.text,
                fontFamily: 'BujangnimNunchi',
                fontSize: 50,
                height: 1,
              ),
            ),
          ),
          Positioned(
            left: 85,
            top: 85,
            child: Text(
              '오전 10:30',
              style: TextStyle(color: AppColors.text50, fontSize: 23),
            ),
          ),
          Positioned(
            right: 10,
            top: 49,
            child: Row(
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
        ],
      ),
    );
  }
}
