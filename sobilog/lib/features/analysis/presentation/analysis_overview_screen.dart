import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../home/presentation/home_screen.dart';
import '../../ledger/presentation/ledger_screen.dart';
import '../../register/presentation/register_type_screen.dart';

class AnalysisOverviewScreen extends StatelessWidget {
  const AnalysisOverviewScreen({super.key, this.onNavigationSelected});

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
            const Positioned(left: 0, top: 427, child: _SpendSummary()),
            const Positioned(left: 0, top: 740, child: _IncomeAndBalance()),
            const Positioned(left: 0, top: 958, child: _CategorySection()),
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

class _SpendSummary extends StatelessWidget {
  const _SpendSummary();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 749,
      height: 283,
      child: Stack(
        children: [
          const Positioned(left: 46, top: 0, child: _LightDivider()),
          const Positioned(
            left: 46,
            top: 54,
            child: Text(
              '총 지출',
              style: TextStyle(
                color: Color(0x80E2E2F9),
                fontSize: 23,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
          Positioned(
            left: 46,
            top: 97,
            child: _Amount(
              value: '150,000',
              fontSize: 55,
              iconWidth: 37,
              iconHeight: 40,
            ),
          ),
          Positioned(
            left: 46,
            top: 179,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RotatedBox(
                  quarterTurns: 3,
                  child: SvgPicture.asset(
                    AppAssets.spendUp,
                    width: 18,
                    height: 19,
                  ),
                ),
                const SizedBox(width: 12),
                _Amount(
                  value: '2,500',
                  color: AppColors.main,
                  fontSize: 40,
                  iconWidth: 29,
                  iconHeight: 31,
                ),
              ],
            ),
          ),
          const Positioned(
            left: 223,
            top: 189,
            child: Text(
              '전월 대비 12%',
              style: TextStyle(
                color: Color(0x80E2E2F9),
                fontSize: 23,
                height: 1,
              ),
            ),
          ),
          const Positioned(left: 46, top: 268, child: _LightDivider()),
        ],
      ),
    );
  }
}

class _LightDivider extends StatelessWidget {
  const _LightDivider();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AppAssets.asteriskDividerDark,
      width: 657,
      height: 15,
      fit: BoxFit.fill,
      colorFilter: const ColorFilter.mode(Color(0x33E2E2F9), BlendMode.srcIn),
    );
  }
}

class _IncomeAndBalance extends StatelessWidget {
  const _IncomeAndBalance();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 749,
      height: 188,
      child: Stack(
        children: [
          Positioned(
            left: 46,
            top: 0,
            right: 46,
            child: _MetricRow(label: '총 수입', value: '+150,000'),
          ),
          Positioned(
            left: 46,
            top: 101,
            right: 46,
            child: _MetricRow(label: '잔액', value: '150,000'),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 87,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xCCE2E2F9),
              fontSize: 30,
              fontWeight: FontWeight.w600,
            ),
          ),
          _Amount(value: value, fontSize: 40, iconWidth: 29, iconHeight: 31),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection();

  static const _items = [
    _CategoryData('식비', '53%', AppAssets.categoryFood, 36, 36),
    _CategoryData('쇼핑', '12%', AppAssets.categoryShopping, 36, 34),
    _CategoryData('교통', '50%', AppAssets.categoryTransport, 40, 40),
    _CategoryData('의료', '50%', AppAssets.categoryMedical, 42, 42),
    _CategoryData('문화', '50%', AppAssets.categoryCulture, 40, 40),
    _CategoryData('기타', '50%', null, 26, 26),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.secondary,
      child: SizedBox(
        width: 749,
        height: 950,
        child: Stack(
          children: [
            const Positioned(
              left: 46,
              top: 37,
              child: Text(
                '카테고리별 비중',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),
            const Positioned(left: 46, top: 86, child: _CategoryBar()),
            for (var index = 0; index < _items.length; index++)
              Positioned(
                left: 0,
                top: 153 + (index * 132),
                child: _CategoryRow(data: _items[index]),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: const SizedBox(
        width: 657,
        height: 32,
        child: Row(
          children: [
            SizedBox(
              width: 204,
              height: 32,
              child: ColoredBox(color: Color(0xFFFA9441)),
            ),
            SizedBox(
              width: 144,
              height: 32,
              child: ColoredBox(color: Color(0xFFE53180)),
            ),
            SizedBox(
              width: 104,
              height: 32,
              child: ColoredBox(color: Color(0xFF3BBEFF)),
            ),
            SizedBox(
              width: 77,
              height: 32,
              child: ColoredBox(color: Color(0xFFE74646)),
            ),
            SizedBox(
              width: 52,
              height: 32,
              child: ColoredBox(color: Color(0xFFB5ABAB)),
            ),
            SizedBox(
              width: 76,
              height: 32,
              child: ColoredBox(color: Color(0xFF5E56FF)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.data});

  final _CategoryData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 749,
      height: 118,
      child: Stack(
        children: [
          Positioned(
            left: 34,
            top: 27,
            width: 64,
            height: 64,
            child: Center(
              child: data.asset == null
                  ? const DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.main,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(dimension: 26),
                    )
                  : SvgPicture.asset(
                      data.asset!,
                      width: data.iconWidth,
                      height: data.iconHeight,
                    ),
            ),
          ),
          Positioned(
            left: 111,
            top: 19,
            child: Text(
              data.name,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 30,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
          Positioned(
            left: 111,
            top: 69,
            child: Text(
              data.percent,
              style: const TextStyle(
                color: Color(0x80E2E2F9),
                fontSize: 23,
                height: 1,
              ),
            ),
          ),
          Positioned(
            right: 46,
            top: 35,
            child: _Amount(
              value: '150,000',
              fontSize: 40,
              iconWidth: 29,
              iconHeight: 31,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryData {
  const _CategoryData(
    this.name,
    this.percent,
    this.asset,
    this.iconWidth,
    this.iconHeight,
  );

  final String name;
  final String percent;
  final String? asset;
  final double iconWidth;
  final double iconHeight;
}

class _Amount extends StatelessWidget {
  const _Amount({
    required this.value,
    required this.fontSize,
    required this.iconWidth,
    required this.iconHeight,
    this.color = AppColors.text,
  });

  final String value;
  final double fontSize;
  final double iconWidth;
  final double iconHeight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontFamily: 'Amarante',
            fontSize: fontSize,
            height: 1,
          ),
        ),
        const SizedBox(width: 5),
        SvgPicture.asset(
          AppAssets.wonLight,
          width: iconWidth,
          height: iconHeight,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ],
    );
  }
}
