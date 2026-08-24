import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../home/presentation/home_screen.dart';
import '../../ledger/presentation/ledger_screen.dart';
import '../../register/presentation/register_type_screen.dart';

class AnalysisDetailScreen extends StatelessWidget {
  const AnalysisDetailScreen({super.key, this.onNavigationSelected});

  final ValueChanged<int>? onNavigationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScrollableDesignCanvas(
        height: 2151,
        child: Stack(
          children: [
            const Positioned(
              left: 46,
              top: 214,
              child: Text(
                '소비분석',
                style: TextStyle(
                  color: AppColors.text,
                  fontFamily: 'BujangnimNunchi',
                  fontSize: 75,
                  height: 1,
                ),
              ),
            ),
            const Positioned(left: 0, top: 307, child: _MonthSelector()),
            const Positioned(left: 0, top: 435, child: _TopCategorySection()),
            const Positioned(left: 0, top: 700, child: _TopItemsSection()),
            const Positioned(left: 0, top: 1021, child: _SpendingGoalSection()),
            const Positioned(
              left: 45.5,
              top: 1235,
              child: _LockedAnalysisCard(title: '소비 패턴 분석'),
            ),
            const Positioned(
              left: 45.5,
              top: 1433,
              child: _LockedAnalysisCard(title: '재구매 충동구매 분석'),
            ),
            Positioned(
              left: 0,
              top: 1982,
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

class _MonthSelector extends StatelessWidget {
  const _MonthSelector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 749,
      height: 97,
      child: Stack(
        children: [
          Positioned(
            left: 79,
            top: 37,
            width: 21,
            height: 23,
            child: Transform.rotate(
              angle: 3.141592653589793,
              child: SvgPicture.asset(AppAssets.monthArrowActive),
            ),
          ),
          Positioned(
            left: 672,
            top: 37,
            width: 21,
            height: 23,
            child: SvgPicture.asset(AppAssets.monthArrowDim),
          ),
          const Positioned(
            left: 253,
            top: 17,
            child: Text(
              '2026',
              style: TextStyle(
                color: AppColors.text,
                fontFamily: 'Amarante',
                fontSize: 50,
                height: 1,
              ),
            ),
          ),
          const Positioned(
            left: 376,
            top: 31,
            child: Text(
              '년',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 25,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
          const Positioned(
            left: 434,
            top: 17,
            child: Text(
              '8',
              style: TextStyle(
                color: AppColors.text,
                fontFamily: 'Amarante',
                fontSize: 50,
                height: 1,
              ),
            ),
          ),
          const Positioned(
            left: 475,
            top: 31,
            child: Text(
              '월',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 25,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCategorySection extends StatelessWidget {
  const _TopCategorySection();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.secondary,
      child: SizedBox(
        width: 749,
        height: 223,
        child: Stack(
          children: [
            const Positioned(
              left: 46,
              top: 37,
              child: _SectionLabel('가장 많이 지출한 카테고리'),
            ),
            Positioned(
              left: 34,
              top: 113,
              width: 64,
              height: 64,
              child: Center(
                child: SvgPicture.asset(
                  AppAssets.categoryFood,
                  width: 36,
                  height: 36,
                ),
              ),
            ),
            const Positioned(
              left: 111,
              top: 124,
              child: Text(
                '식비',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),
            const Positioned(
              left: 111,
              top: 174,
              child: Text(
                '53%',
                style: TextStyle(
                  color: Color(0xCCE2E2F9),
                  fontSize: 23,
                  height: 1,
                ),
              ),
            ),
            const Positioned(
              right: 46,
              top: 121,
              child: _MoneyAmount('150,000'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopItemsSection extends StatelessWidget {
  const _TopItemsSection();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.secondary,
      child: SizedBox(
        width: 749,
        height: 279,
        child: Stack(
          children: [
            Positioned(
              left: 46,
              top: 37,
              child: _SectionLabel('가장 많이 산 품목 TOP 5'),
            ),
            Positioned(left: 0, top: 86, child: _TopItemRow(name: '토마토')),
            Positioned(left: 0, top: 173, child: _TopItemRow(name: '딸기')),
          ],
        ),
      ),
    );
  }
}

class _TopItemRow extends StatelessWidget {
  const _TopItemRow({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 749,
      height: 87,
      child: Stack(
        children: [
          Positioned(
            left: 46,
            top: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontFamily: 'BujangnimNunchi',
                    fontSize: 50,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 22),
                const Text(
                  '5개',
                  style: TextStyle(
                    color: Color(0xCCE2E2F9),
                    fontSize: 23,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(right: 46, top: 20, child: _MoneyAmount('150,000')),
        ],
      ),
    );
  }
}

class _SpendingGoalSection extends StatelessWidget {
  const _SpendingGoalSection();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.secondary,
      child: SizedBox(
        width: 749,
        height: 172,
        child: Stack(
          children: [
            Positioned(left: 46, top: 37, child: _SectionLabel('4월 지출 목표')),
            Positioned(
              right: 46,
              top: 37,
              child: Text(
                '00원 중 00원 사용',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 23,
                  height: 1,
                ),
              ),
            ),
            Positioned(
              left: 46,
              top: 95,
              child: Text(
                '20%',
                style: TextStyle(
                  color: AppColors.text,
                  fontFamily: 'Amarante',
                  fontSize: 40,
                  height: 1,
                ),
              ),
            ),
            Positioned(left: 150, top: 104, child: _GoalProgress()),
          ],
        ),
      ),
    );
  }
}

class _GoalProgress extends StatelessWidget {
  const _GoalProgress();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 553,
        height: 32,
        child: Stack(
          children: const [
            Positioned.fill(child: ColoredBox(color: AppColors.selected)),
            Positioned(
              left: -52,
              top: 0,
              width: 204,
              height: 32,
              child: ColoredBox(color: AppColors.main),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedAnalysisCard extends StatelessWidget {
  const _LockedAnalysisCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 658,
      height: 156,
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.text30),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 36,
            top: 45,
            width: 64,
            height: 64,
            child: SvgPicture.asset(AppAssets.analysisLocked),
          ),
          Positioned(
            left: 123,
            top: 35,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
          const Positioned(
            left: 123,
            top: 88,
            child: Text(
              '연속 7일 기록하면 열려요 0/1일',
              style: TextStyle(
                color: Color(0xCCE2E2F9),
                fontSize: 23,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Color(0xCCE2E2F9), fontSize: 23, height: 1),
    );
  }
}

class _MoneyAmount extends StatelessWidget {
  const _MoneyAmount(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
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
    );
  }
}
