import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_widgets.dart';
import 'email_login_screen.dart';

class PasswordResetCompleteScreen extends StatelessWidget {
  const PasswordResetCompleteScreen({super.key});

  void _openLogin(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const EmailLoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      showBackButton: false,
      child: Stack(
        children: [
          Positioned(
            top: 401,
            width: 402,
            child: Column(
              children: [
                SvgPicture.asset(
                  AppAssets.passwordChanged,
                  width: 36,
                  height: 36,
                ),
                const SizedBox(height: 20),
                const Text(
                  '비밀번호가 변경되었습니다',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          AuthBottomAction(
            label: '로그인 하기',
            onPressed: () => _openLogin(context),
          ),
        ],
      ),
    );
  }
}
