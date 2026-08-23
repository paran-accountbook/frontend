import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/design_canvas.dart';

class LedgerDetailScreen extends StatelessWidget {
  const LedgerDetailScreen({super.key, this.onEdit, this.onDutchPay});

  final VoidCallback? onEdit;
  final VoidCallback? onDutchPay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScrollableDesignCanvas(
        child: Stack(
          children: [
            Positioned(
              left: 55,
              top: 147,
              child: GestureDetector(
                onTap: onEdit,
                child: const Icon(Icons.edit, color: AppColors.text, size: 45),
              ),
            ),
            const Positioned(
              top: 151,
              width: 749,
              child: Text(
                '상세 내역',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Positioned(
              right: 56,
              top: 143,
              child: Icon(Icons.delete, color: Color(0xFFE74262), size: 47),
            ),
            const Positioned(left: 57, top: 221, child: _Asterisks()),
            Positioned(
              left: 54,
              top: 282,
              child: Row(
                children: [
                  const Text(
                    '총',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    '150,000',
                    style: TextStyle(
                      color: AppColors.text,
                      fontFamily: 'Amarante',
                      fontSize: 52,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 7),
                  SvgPicture.asset(AppAssets.wonLight, width: 36, height: 39),
                ],
              ),
            ),
            const Positioned(
              left: 56,
              top: 362,
              child: Text(
                '아주대학교 카페',
                style: TextStyle(
                  color: AppColors.text,
                  fontFamily: 'BujangnimNunchi',
                  fontSize: 47,
                  height: 1,
                ),
              ),
            ),
            Positioned(
              left: 58,
              top: 420,
              child: Text(
                '2026년 8월 19일 오전 10:30',
                style: TextStyle(color: AppColors.text50, fontSize: 23),
              ),
            ),
            const Positioned(left: 57, top: 482, child: _Asterisks()),
            Positioned(
              left: 57,
              top: 554,
              child: GestureDetector(
                onTap: onDutchPay,
                child: Container(
                  width: 635,
                  height: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF342A94), AppColors.main],
                    ),
                    borderRadius: BorderRadius.circular(29),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    '더치페이 하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(left: 57, top: 700, child: _PhotoCards()),
            const Positioned(left: 47, top: 1128, child: _ItemSection()),
            const Positioned(left: 57, top: 1502, child: _Asterisks()),
            const Positioned(top: 1575, width: 749, child: _TotalSection()),
            const Positioned(left: 0, top: 1834, child: _MemoSection()),
            const Positioned(
              left: 0,
              top: 2235,
              child: AppBottomNavigation(selectedIndex: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _Asterisks extends StatelessWidget {
  const _Asterisks();

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

class _PhotoCards extends StatelessWidget {
  const _PhotoCards();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _PhotoCard(label: '영수증'),
        SizedBox(width: 49),
        _PhotoCard(label: '소비사진'),
      ],
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 293,
      height: 350,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.background, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(29),
        border: Border.all(color: AppColors.outline, width: 2),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 27,
            bottom: 27,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Positioned(
            right: 25,
            bottom: 24,
            child: Icon(Icons.edit, color: AppColors.text, size: 34),
          ),
        ],
      ),
    );
  }
}

class _ItemSection extends StatelessWidget {
  const _ItemSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 655,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('품목', style: TextStyle(color: AppColors.text80, fontSize: 22)),
          const SizedBox(height: 16),
          const _ItemRow(count: 'X 1'),
          const _ItemRow(count: 'X 34'),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.count});

  final String count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 38,
            child: Text(
              '커피',
              style: TextStyle(
                color: AppColors.text,
                fontFamily: 'BujangnimNunchi',
                fontSize: 40,
                height: 1,
              ),
            ),
          ),
          Positioned(
            top: 90,
            child: Text(
              count,
              style: TextStyle(color: AppColors.text50, fontSize: 22),
            ),
          ),
          Positioned(
            right: 0,
            top: 50,
            child: Row(
              children: [
                const Text(
                  '150,000',
                  style: TextStyle(
                    color: AppColors.text,
                    fontFamily: 'Amarante',
                    fontSize: 39,
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

class _TotalSection extends StatelessWidget {
  const _TotalSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          '총액',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '150,000',
              style: TextStyle(
                color: AppColors.text,
                fontFamily: 'Amarante',
                fontSize: 50,
                height: 1,
              ),
            ),
            const SizedBox(width: 5),
            SvgPicture.asset(AppAssets.wonLight, width: 33, height: 36),
          ],
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: 637,
          height: 70,
          child: Row(
            children: List.generate(3, (index) {
              const labels = ['현금', '카드', '미지정'];
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index == 0 ? AppColors.text : AppColors.selected,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: index == 0
                          ? AppColors.background
                          : AppColors.text80,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _MemoSection extends StatelessWidget {
  const _MemoSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 749,
      height: 401,
      color: AppColors.secondary,
      padding: const EdgeInsets.only(left: 59, top: 51),
      child: const Text(
        '메모 남기기',
        style: TextStyle(
          color: AppColors.text,
          fontSize: 23,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
