import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import 'dutch_request_screen.dart';

class DutchResultScreen extends StatelessWidget {
  const DutchResultScreen({super.key, this.onNext});

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
              '정산 결과 확인',
              style: TextStyle(
                color: AppColors.text,
                fontFamily: 'BujangnimNunchi',
                fontSize: 75,
              ),
            ),
          ),
          const Positioned(left: 0, top: 326, child: _ReceiptTotal()),
          const Positioned(
            left: 0,
            top: 583,
            child: _PersonResultCard(name: '나', expanded: true, self: true),
          ),
          const Positioned(
            left: 0,
            top: 981,
            child: _PersonResultCard(name: '철수'),
          ),
          const Positioned(
            left: 0,
            top: 1171,
            child: _PersonResultCard(name: '영희'),
          ),
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
                _ActionButton(
                  label: '다음',
                  gradient: true,
                  onTap:
                      onNext ??
                      () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DutchRequestScreen(),
                        ),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ReceiptTotal extends StatelessWidget {
  const _ReceiptTotal();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 749,
    height: 215,
    child: Stack(
      children: [
        Positioned(left: 46, top: 0, child: _AsteriskDivider()),
        Positioned(
          top: 50,
          width: 749,
          child: Text(
            '영수증 총액',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0x80E2E2F9), fontSize: 23),
          ),
        ),
        Positioned(top: 96, width: 749, child: Center(child: _TotalAmount())),
        Positioned(left: 46, bottom: 0, child: _AsteriskDivider()),
      ],
    ),
  );
}

class _AsteriskDivider extends StatelessWidget {
  const _AsteriskDivider();

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    AppAssets.asteriskDividerDark,
    width: 657,
    height: 15,
    colorFilter: const ColorFilter.mode(Color(0xFFE2E2F9), BlendMode.srcIn),
  );
}

class _TotalAmount extends StatelessWidget {
  const _TotalAmount();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text(
        '총',
        style: TextStyle(
          color: AppColors.text,
          fontSize: 25,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(width: 5),
      const Text(
        '150,000',
        style: TextStyle(
          color: AppColors.text,
          fontFamily: 'Amarante',
          fontSize: 55,
        ),
      ),
      const SizedBox(width: 5),
      SvgPicture.asset(AppAssets.wonLight, width: 37, height: 40),
    ],
  );
}

class _PersonResultCard extends StatelessWidget {
  const _PersonResultCard({
    required this.name,
    this.expanded = false,
    this.self = false,
  });

  final String name;
  final bool expanded;
  final bool self;

  @override
  Widget build(BuildContext context) => Container(
    width: 749,
    height: expanded ? 356 : 148,
    color: AppColors.secondary,
    child: Stack(
      children: [
        Positioned(
          left: 46,
          top: 42,
          child: RotatedBox(
            quarterTurns: expanded ? 2 : 0,
            child: SizedBox(
              width: 64,
              height: 64,
              child: Center(
                child: SvgPicture.asset(
                  AppAssets.arrowDown,
                  width: 34,
                  height: 20,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 132,
          top: 39,
          child: SvgPicture.asset(
            self ? AppAssets.avatarSelf : AppAssets.avatarSelected,
            width: 70,
            height: 70,
          ),
        ),
        Positioned(
          left: 224,
          top: 34,
          child: Text(
            name,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 30,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Positioned(
          left: 224,
          top: 83,
          child: Text(
            '배정 품목 2개',
            style: TextStyle(color: Color(0x80E2E2F9), fontSize: 23),
          ),
        ),
        const Positioned(
          right: 46,
          top: 48,
          child: _ResultAmount(value: '14,500'),
        ),
        if (expanded) ...const [
          Positioned(
            left: 0,
            top: 148,
            child: _ResultItem(name: '김치찌개', amount: '12,000'),
          ),
          Positioned(
            left: 0,
            top: 249,
            child: _ResultItem(name: '콜라', amount: '2,500'),
          ),
        ],
      ],
    ),
  );
}

class _ResultItem extends StatelessWidget {
  const _ResultItem({required this.name, required this.amount});

  final String name;
  final String amount;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 749,
    height: 87,
    child: Stack(
      children: [
        Positioned(
          left: 46,
          top: 10,
          child: Text(
            name,
            style: const TextStyle(
              color: AppColors.text,
              fontFamily: 'BujangnimNunchi',
              fontSize: 50,
            ),
          ),
        ),
        Positioned(
          right: 46,
          top: 19,
          child: Opacity(opacity: 0.5, child: _ResultAmount(value: amount)),
        ),
      ],
    ),
  );
}

class _ResultAmount extends StatelessWidget {
  const _ResultAmount({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        value,
        style: const TextStyle(
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
