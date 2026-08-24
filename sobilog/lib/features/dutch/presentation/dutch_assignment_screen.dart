import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';

class DutchAssignmentScreen extends StatelessWidget {
  const DutchAssignmentScreen({super.key, this.onNext});

  final VoidCallback? onNext;

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
              '항목별 인원 배정',
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
              '배정 완료 -/- 품목',
              style: TextStyle(color: Color(0xCCE2E2F9), fontSize: 30),
            ),
          ),
          const Positioned(left: 0, top: 420, child: _AssignmentCard()),
          const Positioned(left: 0, top: 991, child: _AssignmentCard()),
          Positioned(
            left: 46,
            top: 1466,
            child: Row(
              children: [
                _ActionButton(
                  label: '이전',
                  gradient: false,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 20),
                _ActionButton(label: '다음', gradient: true, onTap: onNext),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard();

  @override
  Widget build(BuildContext context) => Container(
    width: 749,
    height: 529,
    color: AppColors.secondary,
    child: const Stack(
      children: [
        Positioned(left: 46, top: 17, child: _ItemName()),
        Positioned(right: 46, top: 48, child: _Amount(opacity: 1)),
        Positioned(left: 0, top: 148, child: _ParticipantRow(name: '나')),
        Positioned(left: 0, top: 249, child: _ParticipantRow(name: '철수')),
        Positioned(left: 0, top: 350, child: _ParticipantRow(name: '영희')),
        Positioned(left: 0, top: 437, child: _SplitSummary()),
      ],
    ),
  );
}

class _ItemName extends StatelessWidget {
  const _ItemName();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 240,
    height: 110,
    child: Stack(
      children: [
        Positioned(
          top: 0,
          child: Text(
            '커피',
            style: TextStyle(
              color: AppColors.text,
              fontFamily: 'BujangnimNunchi',
              fontSize: 50,
            ),
          ),
        ),
        Positioned(
          top: 72,
          child: Text(
            'X 34',
            style: TextStyle(color: Color(0x80E2E2F9), fontSize: 23),
          ),
        ),
      ],
    ),
  );
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 749,
    height: 87,
    child: Stack(
      children: [
        Positioned(
          left: 46,
          top: 21,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.main,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0x4DE2E2F9)),
            ),
            child: SvgPicture.asset(
              AppAssets.checkLight,
              width: 26.68,
              height: 18.21,
            ),
          ),
        ),
        Positioned(
          left: 112,
          top: 24,
          child: Text(
            name,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 30,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Positioned(right: 46, top: 19, child: _Amount(opacity: 0.5)),
      ],
    ),
  );
}

class _Amount extends StatelessWidget {
  const _Amount({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: opacity,
    child: Row(
      children: [
        const Text(
          '150,000',
          style: TextStyle(
            color: AppColors.text,
            fontFamily: 'Amarante',
            fontSize: 40,
          ),
        ),
        const SizedBox(width: 5),
        SvgPicture.asset(AppAssets.wonLight, width: 29, height: 31),
      ],
    ),
  );
}

class _SplitSummary extends StatelessWidget {
  const _SplitSummary();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 749,
    height: 92,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '3명 선택 · 1인당',
          style: TextStyle(color: Color(0x80E2E2F9), fontSize: 23),
        ),
        SizedBox(width: 43),
        Text('12,000원', style: TextStyle(color: Colors.white, fontSize: 23)),
      ],
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.gradient,
    this.onTap,
  });

  final String label;
  final bool gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 317.5,
      height: 102,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient
              ? const [Color(0xFF252552), AppColors.main]
              : const [AppColors.background, Color(0xFF4E5058)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x4DE2E2F9)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
