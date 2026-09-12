import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../analysis/presentation/analysis_overview_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../register/presentation/register_type_screen.dart';
import 'ledger_detail_screen.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key, this.onEntrySelected});

  final VoidCallback? onEntrySelected;

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  int _period = 0;
  int _type = 0;

  @override
  Widget build(BuildContext context) {
    final openDetail =
        widget.onEntrySelected ??
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const LedgerDetailScreen()),
        );
    return Scaffold(
      body: DesignCanvas(
        child: Stack(
          children: [
            const ColoredBox(color: AppColors.background),
            const Positioned(
              left: 24,
              top: 128,
              child: Text(
                '가계부',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 192,
              child: Row(
                children: List.generate(3, (index) {
                  return Padding(
                    padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
                    child: _Chip(
                      label: const ['월', '주', '일'][index],
                      selected: _period == index,
                      onTap: () => setState(() => _period = index),
                    ),
                  );
                }),
              ),
            ),
            const Positioned(
              left: 24,
              top: 272,
              width: 354,
              child: _MonthSelector(),
            ),
            const Positioned(
              left: 24,
              top: 321,
              width: 354,
              child: _AsteriskDivider(),
            ),
            const Positioned(left: 24, top: 353, width: 354, child: _Totals()),
            const Positioned(
              left: 24,
              top: 483,
              width: 354,
              child: _AsteriskDivider(),
            ),
            Positioned(
              left: 24,
              top: 517,
              child: Row(
                children: [
                  ...List.generate(3, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _Chip(
                        label: const ['전체', '지출', '수입'][index],
                        selected: _type == index,
                        onTap: () => setState(() => _type = index),
                      ),
                    );
                  }),
                  const _Chip(label: '▽ 필터'),
                ],
              ),
            ),
            Positioned(
              left: 24,
              top: 588,
              child: _Entries(onTap: openDetail, type: _type),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: AppBottomNavigation(
                selectedIndex: 1,
                onSelected: (index) => _navigate(context, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    final Widget? page = switch (index) {
      0 => const HomeScreen(),
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.selected = false, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        constraints: const BoxConstraints(minWidth: 66),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFA8A3FF) : AppColors.selected,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.outline, width: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF1B1B1B) : AppColors.text50,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SvgPicture.asset(AppAssets.monthArrowActive, width: 10, height: 12),
        const Row(
          children: [
            Text(
              '2026',
              style: TextStyle(
                color: AppColors.text,
                fontFamily: 'Amarante',
                fontSize: 24,
              ),
            ),
            SizedBox(width: 4),
            Text('년', style: TextStyle(color: AppColors.text, fontSize: 14)),
            SizedBox(width: 20),
            Text(
              '8',
              style: TextStyle(
                color: AppColors.text,
                fontFamily: 'Amarante',
                fontSize: 24,
              ),
            ),
            SizedBox(width: 4),
            Text('월', style: TextStyle(color: AppColors.text, fontSize: 14)),
          ],
        ),
        SvgPicture.asset(AppAssets.monthArrowDim, width: 10, height: 12),
      ],
    );
  }
}

class _AsteriskDivider extends StatelessWidget {
  const _AsteriskDivider();

  @override
  Widget build(BuildContext context) {
    return Text(
      List.filled(18, '*').join('   '),
      maxLines: 1,
      style: const TextStyle(color: AppColors.text20, fontSize: 11),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _TotalRow(label: '총 지출', amount: '-150,000 ₩'),
        SizedBox(height: 18),
        _TotalRow(label: '총 수입', amount: '+150,000 ₩'),
        SizedBox(height: 18),
        _TotalRow(label: '잔액', amount: '+150,000 ₩', accent: true),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.amount,
    this.accent = false,
  });

  final String label;
  final String amount;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.text50, fontSize: 14),
        ),
        _Price(amount: amount.replaceAll(' ₩', ''), accent: accent),
      ],
    );
  }
}

class _Entries extends StatelessWidget {
  const _Entries({required this.onTap, required this.type});

  final VoidCallback onTap;
  final int type;

  @override
  Widget build(BuildContext context) {
    final amounts = type == 2
        ? const ['+150,000', '+150,000', '+150,000', '+150,000']
        : const ['-4,500', '-4,500', '-4,500', '-4,500'];
    return SizedBox(
      width: 354,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '8월 19일 (월)',
            style: TextStyle(color: AppColors.text50, fontSize: 14),
          ),
          const SizedBox(height: 14),
          ...List.generate(
            4,
            (index) => _Entry(amount: amounts[index], onTap: onTap),
          ),
        ],
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.amount, required this.onTap});

  final String amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x0DE2E2F9))),
        ),
        child: Row(
          children: [
            SvgPicture.asset(AppAssets.categoryFood, width: 26, height: 26),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '아주대학교 카페',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    '카페  ·  카드  ·  오전 10:30',
                    style: TextStyle(color: AppColors.text50, fontSize: 12),
                  ),
                ],
              ),
            ),
            _Price(amount: amount),
            const SizedBox(width: 8),
            const Text(
              '〉',
              style: TextStyle(color: AppColors.text, fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _Price extends StatelessWidget {
  const _Price({required this.amount, this.accent = false});

  final String amount;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ? const Color(0xFFA8A3FF) : AppColors.text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          amount,
          style: TextStyle(color: color, fontFamily: 'Amarante', fontSize: 20),
        ),
        const SizedBox(width: 4),
        SvgPicture.asset(
          AppAssets.wonLight,
          width: 14,
          height: 15,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ],
    );
  }
}
