import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../analysis/presentation/analysis_overview_screen.dart';
import '../../ledger/presentation/ledger_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../register/presentation/register_type_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onNavigationSelected});

  final ValueChanged<int>? onNavigationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        child: Stack(
          children: [
            const ColoredBox(color: AppColors.background),
            Positioned(
              left: -110,
              top: 0,
              width: 623,
              height: 874,
              child: Image.asset(AppAssets.homeBackground, fit: BoxFit.cover),
            ),
            Positioned(
              left: 24,
              top: 66,
              width: 132,
              height: 25,
              child: Row(
                children: [
                  SvgPicture.asset(AppAssets.splashLogoSymbol, width: 20),
                  const SizedBox(width: 4),
                  Expanded(
                    child: SvgPicture.asset(AppAssets.splashLogoWordmark),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              top: 108,
              width: 354,
              height: 318,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AnalysisOverviewScreen(),
                  ),
                ),
                child: const _SummaryReceipt(),
              ),
            ),
            const Positioned(
              left: 24,
              top: 452,
              width: 354,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('최근 등록 내역', style: _smallText),
                  Text('전체 보기  〉', style: _smallText),
                ],
              ),
            ),
            const Positioned(
              left: 24,
              top: 489,
              child: Column(
                children: [_RecentRow(), _RecentRow(), _RecentRow()],
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: AppBottomNavigation(
                selectedIndex: 0,
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
    final Widget? page = switch (index) {
      1 => const LedgerScreen(),
      2 => const RegisterTypeScreen(),
      3 => const AnalysisOverviewScreen(),
      4 => const ProfileScreen(),
      _ => null,
    };
    if (page == null) return;
    final route = MaterialPageRoute<void>(builder: (_) => page);
    if (index == 2) {
      Navigator.of(context).push(route);
    } else {
      Navigator.of(context).pushReplacement(route);
    }
  }
}

const _smallText = TextStyle(
  color: AppColors.text,
  fontSize: 14,
  fontWeight: FontWeight.w500,
);

class _SummaryReceipt extends StatelessWidget {
  const _SummaryReceipt();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: SvgPicture.asset(
            AppAssets.homeReceiptCompact,
            fit: BoxFit.fill,
          ),
        ),
        const Positioned(
          top: 27,
          width: 354,
          child: Text(
            '소비요약',
            textAlign: TextAlign.center,
            style: _receiptLabel,
          ),
        ),
        const Positioned(
          top: 66,
          width: 354,
          child: Text(
            '이번 달 총 지출액',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1B1B1B),
              fontFamily: 'BujangnimNunchi',
              fontSize: 24,
            ),
          ),
        ),
        ...[54.0, 154.0, 254.0].map(
          (top) => Positioned(
            left: 17,
            top: top,
            width: 320,
            height: 7,
            child: SvgPicture.asset(AppAssets.receiptAsteriskDivider),
          ),
        ),
        const Positioned(
          top: 105,
          width: 354,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('총 ', style: _receiptLabel),
              Text('150,000', style: _receiptAmountLarge),
              SizedBox(width: 4),
              Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: _WonIcon(dark: true, width: 19, height: 20),
              ),
            ],
          ),
        ),
        const Positioned(
          left: 17,
          right: 17,
          top: 188,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '전월 동일 시점 대비 +12%',
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: _receiptBody,
                ),
              ),
              _ReceiptPrice(amount: '+2,500', color: Color(0xFFCF376A)),
            ],
          ),
        ),
        const Positioned(
          left: 17,
          right: 17,
          top: 229,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('8월 목표', style: _receiptBody),
              _ReceiptPrice(amount: '40,000'),
            ],
          ),
        ),
        const Positioned(
          left: 17,
          right: 17,
          top: 281,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('수입 30,000원', style: _receiptLabel),
              Text('잔액 10,000원', style: _receiptLabel),
            ],
          ),
        ),
      ],
    );
  }
}

const _receiptLabel = TextStyle(
  color: Color(0xFF1B1B1B),
  fontSize: 14,
  fontWeight: FontWeight.w500,
);
const _receiptBody = TextStyle(color: Color(0xFF1B1B1B), fontSize: 12);
const _receiptAmountLarge = TextStyle(
  color: Color(0xFF1B1B1B),
  fontFamily: 'Amarante',
  fontSize: 30,
  height: 1,
);

class _RecentRow extends StatelessWidget {
  const _RecentRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 354,
      height: 72,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x0DE2E2F9))),
      ),
      child: Row(
        children: [
          const Text(
            '8/19',
            style: TextStyle(
              color: AppColors.text50,
              fontFamily: 'Amarante',
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 13),
          SvgPicture.asset(AppAssets.categoryFood, width: 26, height: 26),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '아주대학교 카페',
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: _smallText,
                ),
                SizedBox(height: 7),
                Text(
                  '오전 10:30',
                  style: TextStyle(color: AppColors.text50, fontSize: 12),
                ),
              ],
            ),
          ),
          const _LightPrice(amount: '150,000'),
        ],
      ),
    );
  }
}

class _WonIcon extends StatelessWidget {
  const _WonIcon({
    required this.dark,
    this.width = 14,
    this.height = 15,
    this.color,
  });

  final bool dark;
  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      dark ? AppAssets.wonDark : AppAssets.wonLight,
      width: width,
      height: height,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}

class _ReceiptPrice extends StatelessWidget {
  const _ReceiptPrice({
    required this.amount,
    this.color = const Color(0xFF1B1B1B),
  });

  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          amount,
          style: TextStyle(color: color, fontFamily: 'Amarante', fontSize: 20),
        ),
        const SizedBox(width: 4),
        _WonIcon(dark: true, color: color),
      ],
    );
  }
}

class _LightPrice extends StatelessWidget {
  const _LightPrice({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          amount,
          style: const TextStyle(
            color: AppColors.text,
            fontFamily: 'Amarante',
            fontSize: 20,
          ),
        ),
        const SizedBox(width: 4),
        const _WonIcon(dark: false),
      ],
    );
  }
}
