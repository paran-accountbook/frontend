import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';

class DutchRequestScreen extends StatelessWidget {
  const DutchRequestScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DesignCanvas(
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
              '정산 요청',
              style: TextStyle(
                color: AppColors.text,
                fontFamily: 'BujangnimNunchi',
                fontSize: 75,
              ),
            ),
          ),
          const Positioned(left: 0, top: 337, child: _AccountCard()),
          const Positioned(left: 40, top: 579, child: _SaveAccountChoice()),
          const Positioned(
            left: 46,
            top: 701,
            child: Text(
              '요청할 인원 2명',
              style: TextStyle(color: Color(0x80E2E2F9), fontSize: 23),
            ),
          ),
          const Positioned(left: 0, top: 770, child: _RequestPeople()),
          Positioned(
            left: 46,
            top: 1466,
            child: GestureDetector(
              onTap: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
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
                  '완료',
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

class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) => Container(
    width: 749,
    height: 195,
    color: AppColors.secondary,
    child: Stack(
      children: [
        const Positioned(
          left: 46,
          top: 39,
          child: Text(
            '내 계좌',
            style: TextStyle(color: AppColors.text, fontSize: 23),
          ),
        ),
        const Positioned(
          left: 38,
          top: 96,
          child: Text(
            'ㅁㅁ은행 000-0000-0000',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 40,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Positioned(
          left: 499,
          top: 92,
          child: SvgPicture.asset(AppAssets.editLight, width: 64, height: 64),
        ),
      ],
    ),
  );
}

class _SaveAccountChoice extends StatelessWidget {
  const _SaveAccountChoice();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.selected,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0x4DE2E2F9)),
        ),
      ),
      const SizedBox(width: 15),
      const Text(
        '저장하고 다음에도 사용',
        style: TextStyle(color: Color(0x80E2E2F9), fontSize: 23),
      ),
    ],
  );
}

class _RequestPeople extends StatelessWidget {
  const _RequestPeople();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 749,
    height: 563,
    child: Stack(
      children: [
        Positioned(left: 0, top: 0, child: _RequestPerson(name: '철수')),
        Positioned(left: 0, top: 148, child: _RequestPerson(name: '영희')),
        Positioned(left: 0, top: 338, child: _MessagePreview()),
      ],
    ),
  );
}

class _RequestPerson extends StatelessWidget {
  const _RequestPerson({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Container(
    width: 749,
    height: 148,
    color: AppColors.secondary,
    child: Stack(
      children: [
        Positioned(
          left: 46,
          top: 39,
          child: SvgPicture.asset(
            AppAssets.avatarSelected,
            width: 70,
            height: 70,
          ),
        ),
        Positioned(
          left: 138,
          top: 53,
          child: Text(
            name,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 30,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Positioned(right: 119, top: 48, child: _RequestAmount()),
        const Positioned(
          right: 46,
          top: 59,
          child: Text(
            '복사',
            style: TextStyle(color: Color(0xCCE2E2F9), fontSize: 23),
          ),
        ),
      ],
    ),
  );
}

class _RequestAmount extends StatelessWidget {
  const _RequestAmount();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Text(
        '14,500',
        style: TextStyle(
          color: AppColors.text,
          fontFamily: 'Amarante',
          fontSize: 40,
        ),
      ),
      const SizedBox(width: 5),
      SvgPicture.asset(AppAssets.wonLight, width: 29, height: 31),
    ],
  );
}

class _MessagePreview extends StatelessWidget {
  const _MessagePreview();

  @override
  Widget build(BuildContext context) => Container(
    width: 749,
    height: 225,
    color: AppColors.secondary,
    child: const Stack(
      children: [
        Positioned(
          left: 60,
          top: 42,
          child: Text(
            '복사되는 메시지',
            style: TextStyle(color: Color(0x80E2E2F9), fontSize: 23),
          ),
        ),
        Positioned(
          left: 60,
          top: 105,
          child: Text(
            '철수 님  14,500원\nㅁㅁ은행 000-0000-0000',
            style: TextStyle(color: AppColors.text, fontSize: 30),
          ),
        ),
      ],
    ),
  );
}
