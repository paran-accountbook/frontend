import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';

/// P1 화면에서 반복되는 402×874 Figma 규격의 상단 내비게이션이다.
class P1ScreenHeader extends StatelessWidget {
  const P1ScreenHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.onBack,
    this.showBack = true,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 24,
    right: 24,
    top: 50,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34,
          height: 34,
          child: showBack
              ? IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  icon: SvgPicture.asset(AppAssets.arrowBackLight),
                )
              : null,
        ),
        const SizedBox(height: 41),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 27,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 18),
          Text(
            subtitle!,
            style: const TextStyle(
              color: AppColors.text80,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    ),
  );
}

/// Figma의 하단 흐림 배경과 56px 기본 버튼을 함께 제공한다.
class P1BottomAction extends StatelessWidget {
  const P1BottomAction({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    height: 120,
    child: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xE6121215)],
              stops: [0, .8],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: onTap == null ? AppColors.selected : AppColors.main,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.text20),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class P1AsteriskDivider extends StatelessWidget {
  const P1AsteriskDivider({super.key});

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    AppAssets.asteriskDividerDark,
    width: 354,
    height: 7,
    fit: BoxFit.fill,
  );
}

class P1Amount extends StatelessWidget {
  const P1Amount({
    required this.value,
    super.key,
    this.color = AppColors.text,
    this.fontSize = 20,
  });

  final int value;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        formatP1Amount(value),
        style: TextStyle(
          color: color,
          fontFamily: 'Amarante',
          fontSize: fontSize,
          height: 1,
        ),
      ),
      const SizedBox(width: 4),
      SvgPicture.asset(
        AppAssets.wonLight,
        width: fontSize * .7,
        height: fontSize * .75,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    ],
  );
}

String formatP1Amount(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return '${amount < 0 ? '-' : ''}$buffer';
}
