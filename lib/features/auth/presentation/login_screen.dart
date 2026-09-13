import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import 'email_login_screen.dart';
import 'email_signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, this.onEmailPressed, this.onKakaoPressed});

  final VoidCallback? onEmailPressed;
  final VoidCallback? onKakaoPressed;

  void _openVerification(BuildContext context) {
    if (onEmailPressed case final callback?) {
      callback();
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const EmailLoginScreen()));
  }

  void _openSignup(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const EmailSignupScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        width: 402,
        height: 874,
        child: ColoredBox(
          color: AppColors.background,
          child: Stack(
            children: [
              Positioned(
                left: -110,
                top: 0,
                width: 623,
                height: 874,
                child: Image.asset(AppAssets.authBackground, fit: BoxFit.cover),
              ),
              Positioned(
                left: 162,
                top: 306,
                width: 78,
                height: 100,
                child: SvgPicture.asset(AppAssets.splashLogoSymbol),
              ),
              Positioned(
                left: 162,
                top: 418,
                width: 78,
                height: 19,
                child: SvgPicture.asset(AppAssets.splashLogoWordmark),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 231,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00121215), Color(0xE6121215)],
                      stops: [0, 0.8],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                top: 668,
                child: _LoginButton(
                  label: '카카오로 시작하기',
                  backgroundColor: const Color(0xFFFEE601),
                  foregroundColor: const Color(0xFF1A1601),
                  asset: AppAssets.kakao,
                  iconWidth: 20,
                  iconHeight: 18,
                  onPressed: onKakaoPressed ?? () {},
                ),
              ),
              Positioned(
                left: 24,
                top: 744,
                child: _LoginButton(
                  label: '이메일로 로그인',
                  backgroundColor: AppColors.selected,
                  foregroundColor: AppColors.text,
                  asset: AppAssets.mail,
                  iconWidth: 18,
                  iconHeight: 19,
                  borderColor: AppColors.text30,
                  onPressed: () => _openVerification(context),
                ),
              ),
              Positioned(
                left: 0,
                top: 820,
                width: 402,
                child: GestureDetector(
                  onTap: () => _openSignup(context),
                  child: Text(
                    '이메일로 회원가입',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.text80, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.asset,
    required this.iconWidth,
    required this.iconHeight,
    required this.onPressed,
    this.borderColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final String asset;
  final double iconWidth;
  final double iconHeight;
  final Color? borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 354,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: borderColor == null ? null : Border.all(color: borderColor!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(asset, width: iconWidth, height: iconHeight),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
