import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/home/presentation/home_screen.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/design_canvas.dart';

class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key, this.onEntrySelected});

  final VoidCallback? onEntrySelected;

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
                '가계부',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 50,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Positioned(left: 57, top: 320, child: _MonthSelector()),
            const Positioned(left: 57, top: 409, child: _AsteriskDivider()),
            const Positioned(left: 57, top: 481, child: _CategoryFilters()),
            const Positioned(left: 56, top: 586, child: _TypeTabs()),
            Positioned(
              left: 46,
              top: 711,
              child: _DateGroup(
                date: '8/19 (월)',
                entries: const [
                  _EntryData(amount: '-150,000'),
                  _EntryData(amount: '-150,000'),
                ],
                onTap: onEntrySelected,
              ),
            ),
            Positioned(
              left: 46,
              top: 1103,
              child: _DateGroup(
                date: '8/18 (일)',
                entries: const [
                  _EntryData(amount: '150,000'),
                  _EntryData(amount: '150,000'),
                ],
                onTap: onEntrySelected,
              ),
            ),
            Positioned(
              left: 0,
              top: 1459,
              child: AppBottomNavigation(
                selectedIndex: 1,
                onSelected: (index) {
                  if (index == 0) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const HomeScreen(),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 635,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '◀',
            style: TextStyle(color: AppColors.text, fontSize: 25),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                '2026',
                style: TextStyle(
                  color: AppColors.text,
                  fontFamily: 'Amarante',
                  fontSize: 51,
                  height: 1,
                ),
              ),
              SizedBox(width: 13),
              Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  '년',
                  style: TextStyle(color: AppColors.text, fontSize: 21),
                ),
              ),
              SizedBox(width: 35),
              Text(
                '8',
                style: TextStyle(
                  color: AppColors.text,
                  fontFamily: 'Amarante',
                  fontSize: 51,
                  height: 1,
                ),
              ),
              SizedBox(width: 13),
              Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  '월',
                  style: TextStyle(color: AppColors.text, fontSize: 21),
                ),
              ),
            ],
          ),
          Text('▶', style: TextStyle(color: AppColors.text30, fontSize: 25)),
        ],
      ),
    );
  }
}

class _AsteriskDivider extends StatelessWidget {
  const _AsteriskDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 635,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          18,
          (_) => Text(
            '*',
            style: TextStyle(color: AppColors.text30, fontSize: 22),
          ),
        ),
      ),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters();

  @override
  Widget build(BuildContext context) {
    const labels = ['전체', '식비', '교통', '의료', '문화', '○○', '기타'];
    return SizedBox(
      width: 692,
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (_, index) => Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 27),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: index == 0 ? AppColors.text : Colors.transparent,
            borderRadius: BorderRadius.circular(31),
            border: index == 0 ? null : Border.all(color: AppColors.text),
          ),
          child: Text(
            labels[index],
            style: TextStyle(
              color: index == 0 ? AppColors.background : AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeTabs extends StatelessWidget {
  const _TypeTabs();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 637,
      height: 71,
      child: Row(
        children: List.generate(3, (index) {
          const labels = ['전체', '지출', '수입'];
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index == 2 ? 0 : 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: index == 0 ? AppColors.text : AppColors.selected,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                labels[index],
                style: TextStyle(
                  color: index == 0 ? AppColors.background : AppColors.text80,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DateGroup extends StatelessWidget {
  const _DateGroup({required this.date, required this.entries, this.onTap});

  final String date;
  final List<_EntryData> entries;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 647,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: TextStyle(
              color: AppColors.text80,
              fontFamily: 'Amarante',
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 20),
          ...entries.map((entry) => _LedgerEntry(data: entry, onTap: onTap)),
        ],
      ),
    );
  }
}

class _EntryData {
  const _EntryData({required this.amount});

  final String amount;
}

class _LedgerEntry extends StatelessWidget {
  const _LedgerEntry({required this.data, this.onTap});

  final _EntryData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 647,
        height: 148,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.outline)),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 39,
              child: Text(
                '아주대학교 카페',
                style: TextStyle(
                  color: AppColors.text,
                  fontFamily: 'BujangnimNunchi',
                  fontSize: 44,
                  height: 1,
                ),
              ),
            ),
            Positioned(
              top: 92,
              child: Text(
                '식비',
                style: TextStyle(color: AppColors.text80, fontSize: 22),
              ),
            ),
            Positioned(
              left: 59,
              top: 92,
              child: Text(
                '오전 10:30',
                style: TextStyle(color: AppColors.text50, fontSize: 22),
              ),
            ),
            Positioned(
              right: 55,
              top: 49,
              child: Row(
                children: [
                  Text(
                    data.amount,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontFamily: 'Amarante',
                      fontSize: 40,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SvgPicture.asset(AppAssets.wonLight, width: 30, height: 31),
                ],
              ),
            ),
            Positioned(
              right: 3,
              top: 55,
              child: Text(
                '〉',
                style: TextStyle(
                  color: AppColors.text50,
                  fontSize: 43,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
