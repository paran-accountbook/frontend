import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';

class DutchPeopleScreen extends StatelessWidget {
  const DutchPeopleScreen({super.key, this.onNext});
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DesignCanvas(
      child: Stack(
        children: [
          const Positioned(
            left: 46,
            top: 144,
            child: Text(
              '인원등록',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 50,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            left: 46,
            top: 250,
            child: Text(
              '무엇을 기록할까요?',
              style: TextStyle(color: AppColors.text80, fontSize: 29),
            ),
          ),
          Positioned(
            left: 57,
            top: 329,
            child: Container(
              width: 635,
              height: 102,
              padding: const EdgeInsets.symmetric(horizontal: 36),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(29),
              ),
              child: const Row(
                children: [
                  Text(
                    '현우',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.add, color: AppColors.main, size: 48),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 46,
            top: 492,
            child: SizedBox(
              width: 650,
              child: Wrap(
                spacing: 12,
                runSpacing: 16,
                children: [
                  _PersonChip('나 (본인)', true),
                  _PersonChip('철수', false),
                  _PersonChip('안녕하세요', false),
                  _PersonChip('민수', false),
                  _PersonChip('지은', false),
                ],
              ),
            ),
          ),
          Positioned(
            top: 1220,
            width: 749,
            child: Text(
              '최근 정산에 사용한 이름',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.text50, fontSize: 22),
            ),
          ),
          const Positioned(left: 0, top: 1288, child: _RecentPeople()),
          Positioned(
            left: 57,
            top: 1458,
            child: GestureDetector(
              onTap: onNext,
              child: Container(
                width: 635,
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF33298F), AppColors.main],
                  ),
                  borderRadius: BorderRadius.circular(29),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  '정산하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
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

class _PersonChip extends StatelessWidget {
  const _PersonChip(this.name, this.self);
  final String name;
  final bool self;
  @override
  Widget build(BuildContext context) => Container(
    height: 98,
    padding: const EdgeInsets.symmetric(horizontal: 25),
    decoration: BoxDecoration(
      color: self ? AppColors.main : const Color(0xFF3D3592),
      borderRadius: BorderRadius.circular(50),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!self)
          const CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.main,
            child: Icon(Icons.person, color: AppColors.text, size: 42),
          ),
        if (!self) const SizedBox(width: 13),
        Text(
          name,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 18),
        const Icon(Icons.close, color: Colors.white38, size: 34),
      ],
    ),
  );
}

class _RecentPeople extends StatelessWidget {
  const _RecentPeople();
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 749,
    height: 100,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: const [
        _RecentChip('철수'),
        _RecentChip('영희'),
        _RecentChip('지은'),
        _RecentChip('민수'),
        _RecentChip('현우'),
      ],
    ),
  );
}

class _RecentChip extends StatelessWidget {
  const _RecentChip(this.name);
  final String name;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 12),
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: BoxDecoration(
      color: AppColors.selected,
      borderRadius: BorderRadius.circular(50),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.background,
          child: Icon(Icons.person, color: Colors.white38),
        ),
        const SizedBox(width: 12),
        Text(
          name,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
