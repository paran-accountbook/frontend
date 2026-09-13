import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import 'dutch_assignment_screen.dart';

class DutchPeopleScreen extends StatelessWidget {
  const DutchPeopleScreen({super.key, this.onNext});

  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final next =
        onNext ??
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const DutchAssignmentScreen(),
          ),
        );

    return Scaffold(
      body: DesignCanvas(
        width: 749,
        height: 1628,
        child: Stack(
          children: [
            Positioned(
              left: 32,
              top: 133,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: SvgPicture.asset(
                  AppAssets.arrowBackLight,
                  width: 70,
                  height: 70,
                ),
              ),
            ),
            const Positioned(
              left: 46,
              top: 214,
              child: Text(
                '인원 등록',
                style: TextStyle(
                  color: AppColors.text,
                  fontFamily: 'BujangnimNunchi',
                  fontSize: 75,
                ),
              ),
            ),
            const Positioned(
              left: 46,
              top: 330,
              child: Text(
                '인원을 추가하세요',
                style: TextStyle(color: Color(0xCCE2E2F9), fontSize: 30),
              ),
            ),
            const Positioned(left: 58, top: 419, child: _NameInput()),
            const Positioned(
              left: 46,
              top: 582,
              child: _PersonChip(name: '나 (본인)', width: 227, self: true),
            ),
            const Positioned(
              left: 285,
              top: 582,
              child: _PersonChip(name: '철수', width: 235),
            ),
            const Positioned(
              left: 46,
              top: 698,
              child: _PersonChip(name: '안녕하세요', width: 306),
            ),
            const Positioned(
              left: 372,
              top: 698,
              child: _PersonChip(name: '민수', width: 235),
            ),
            const Positioned(
              left: 49,
              top: 814,
              child: _PersonChip(name: '지은', width: 235),
            ),
            const Positioned(
              top: 1217,
              width: 749,
              child: Text(
                '최근 정산에 사용한 이름',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0x80E2E2F9), fontSize: 23),
              ),
            ),
            const Positioned(left: -119, top: 1288, child: _RecentPeople()),
            Positioned(
              left: 46,
              top: 1466,
              child: GestureDetector(
                onTap: next,
                child: Container(
                  width: 655,
                  height: 102,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF252552), AppColors.main],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0x4DE2E2F9)),
                  ),
                  child: const Text(
                    '정산하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameInput extends StatelessWidget {
  const _NameInput();

  @override
  Widget build(BuildContext context) => Container(
    width: 633,
    height: 102,
    padding: const EdgeInsets.only(left: 36, right: 21),
    decoration: BoxDecoration(
      color: AppColors.secondary,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      children: [
        const Text(
          '현우',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Container(
          width: 68,
          height: 68,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B1B),
            borderRadius: BorderRadius.circular(20),
          ),
          child: SvgPicture.asset(AppAssets.addPurple, width: 28, height: 28),
        ),
      ],
    ),
  );
}

class _PersonChip extends StatelessWidget {
  const _PersonChip({
    required this.name,
    required this.width,
    this.self = false,
  });

  final String name;
  final double width;
  final bool self;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 102,
    padding: EdgeInsets.only(left: self ? 36 : 14, right: 22),
    decoration: BoxDecoration(
      color: self ? const Color(0xFF6456FF) : const Color(0x803D3592),
      borderRadius: BorderRadius.circular(60),
    ),
    child: Stack(
      children: [
        if (!self)
          Positioned(
            left: 0,
            top: 16,
            child: SvgPicture.asset(
              AppAssets.avatarSelected,
              width: 70,
              height: 70,
            ),
          ),
        Positioned(
          left: self ? 0 : 86,
          top: 29,
          child: Text(
            name,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 30,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 28,
          child: SvgPicture.asset(AppAssets.closeLight, width: 46, height: 46),
        ),
      ],
    ),
  );
}

class _RecentPeople extends StatelessWidget {
  const _RecentPeople();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      _RecentChip('철수'),
      SizedBox(width: 12),
      _RecentChip('영희'),
      SizedBox(width: 12),
      _RecentChip('지은'),
      SizedBox(width: 12),
      _RecentChip('민수'),
      SizedBox(width: 12),
      _RecentChip('민수'),
    ],
  );
}

class _RecentChip extends StatelessWidget {
  const _RecentChip(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => Container(
    height: 98,
    padding: const EdgeInsets.fromLTRB(14, 14, 30, 14),
    decoration: BoxDecoration(
      color: AppColors.selected,
      borderRadius: BorderRadius.circular(60),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(AppAssets.avatarRecent, width: 70, height: 70),
        const SizedBox(width: 16),
        Text(
          name,
          style: const TextStyle(
            color: Color(0xCCE2E2F9),
            fontSize: 30,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
