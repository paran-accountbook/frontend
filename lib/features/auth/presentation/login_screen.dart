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
        child: ColoredBox(
          color: AppColors.background,
          child: Stack(
            children: [
              Positioned(
                left: 58,
                top: 656,
                child: _LoginButton(
                  label: '카카오로 로그인',
                  backgroundColor: const Color(0xFFFEE500),
                  foregroundColor: const Color(0xFF1A1601),
                  asset: AppAssets.kakao,
                  iconWidth: 36,
                  iconHeight: 33,
                  onPressed: onKakaoPressed ?? () {},
                ),
              ),
              Positioned(
                left: 58,
                top: 798,
                child: _LoginButton(
                  label: '이메일로 로그인',
                  backgroundColor: AppColors.selected,
                  foregroundColor: AppColors.text,
                  asset: AppAssets.mail,
                  iconWidth: 32,
                  iconHeight: 35,
                  borderColor: AppColors.text30,
                  onPressed: () => _openVerification(context),
                ),
              ),
              Positioned(
                left: 0,
                top: 940,
                width: 749,
                child: GestureDetector(
                  onTap: () => _openSignup(context),
                  child: Text(
                    '이메일로 회원가입',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.text80, fontSize: 25),
                  ),
                ),
              ),
              Positioned(
                left: 303,
                top: 1469,
                child: Text(
                  '팀 로고',
                  style: TextStyle(
                    color: AppColors.text50,
                    fontSize: 50,
                    fontWeight: FontWeight.w600,
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
        width: 633,
        height: 102,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(30),
          border: borderColor == null ? null : Border.all(color: borderColor!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(asset, width: iconWidth, height: iconHeight),
            const SizedBox(width: 18),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
