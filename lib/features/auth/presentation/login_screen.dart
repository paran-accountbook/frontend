import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../home/presentation/home_screen.dart';
import '../data/auth_service.dart';
import '../data/kakao_login_client.dart';
import 'email_login_screen.dart';
import 'email_signup_screen.dart';
import 'pending_deletion_screen.dart';
import 'terms_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onEmailPressed,
    this.onKakaoPressed,
    this.authService,
    this.kakaoLoginClient,
  });

  final VoidCallback? onEmailPressed;
  final VoidCallback? onKakaoPressed;
  final AuthService? authService;
  final KakaoLoginClient? kakaoLoginClient;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isKakaoLoading = false;
  String? _kakaoError;

  void _openVerification(BuildContext context) {
    if (widget.onEmailPressed case final callback?) {
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

  Future<void> _loginWithKakao() async {
    if (widget.onKakaoPressed case final callback?) {
      callback();
      return;
    }
    if (_isKakaoLoading) return;
    setState(() {
      _isKakaoLoading = true;
      _kakaoError = null;
    });
    try {
      final auth = widget.authService ?? AppServices.auth;
      final kakao = widget.kakaoLoginClient ?? AppServices.kakaoLogin;
      final kakaoToken = await kakao.login();
      final login = await auth.loginWithKakao(kakaoToken);
      if (!mounted) return;

      final pendingAt = DateTime.tryParse(
        login['pending_deletion_at'] as String? ?? '',
      );
      if (pendingAt != null) {
        _replaceAll(
          PendingDeletionScreen(scheduledAt: pendingAt, authService: auth),
        );
        return;
      }

      final status = await auth.termsStatus();
      if (!mounted) return;
      if (status['initial_agreement_required'] == true) {
        _replaceAll(TermsScreen(authService: auth, kakaoSignup: true));
      } else if (status['reconsent_required'] == true) {
        _replaceAll(TermsScreen(authService: auth, reconsent: true));
      } else {
        _replaceAll(HomeScreen(financeService: AppServices.finance));
      }
    } on ApiException catch (error) {
      if (mounted && error.code != 'KAKAO_LOGIN_CANCELED') {
        setState(() => _kakaoError = error.message);
      }
    } finally {
      if (mounted) setState(() => _isKakaoLoading = false);
    }
  }

  void _replaceAll(Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => screen),
      (_) => false,
    );
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
              const Positioned(
                left: 0,
                right: 0,
                top: 636,
                child: Text(
                  'Ver 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.text50,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1,
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
                  onPressed: _loginWithKakao,
                ),
              ),
              if (_isKakaoLoading)
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 714,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              if (_kakaoError case final message?)
                Positioned(
                  left: 24,
                  right: 24,
                  top: 718,
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFF6B7A),
                      fontSize: 11,
                    ),
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
