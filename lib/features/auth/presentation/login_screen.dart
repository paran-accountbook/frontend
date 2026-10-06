import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../home/presentation/home_screen.dart';
import '../data/apple_login_client.dart';
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
    this.onApplePressed,
    this.authService,
    this.kakaoLoginClient,
    this.appleLoginClient,
  });

  final VoidCallback? onEmailPressed;
  final VoidCallback? onKakaoPressed;
  final VoidCallback? onApplePressed;
  final AuthService? authService;
  final KakaoLoginClient? kakaoLoginClient;
  final AppleLoginClient? appleLoginClient;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isKakaoLoading = false;
  bool _isAppleLoading = false;
  String? _loginError;

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
      _loginError = null;
    });
    try {
      final auth = widget.authService ?? AppServices.auth;
      final kakao = widget.kakaoLoginClient ?? AppServices.kakaoLogin;
      final kakaoToken = await kakao.login();
      final login = await auth.loginWithKakao(kakaoToken);
      if (!mounted) return;
      await _finishSocialLogin(login, auth);
    } on ApiException catch (error) {
      if (mounted && error.code != 'KAKAO_LOGIN_CANCELED') {
        setState(() => _loginError = '카카오 로그인에 실패했어요. 다시 시도해 주세요');
      }
    } finally {
      if (mounted) setState(() => _isKakaoLoading = false);
    }
  }

  Future<void> _loginWithApple() async {
    if (widget.onApplePressed case final callback?) {
      callback();
      return;
    }
    if (_isAppleLoading) return;
    setState(() {
      _isAppleLoading = true;
      _loginError = null;
    });
    AppleLoginCredential? credential;
    try {
      final auth = widget.authService ?? AppServices.auth;
      final apple = widget.appleLoginClient ?? AppServices.appleLogin;
      credential = await apple.login();
      final login = await auth.loginWithApple(
        identityToken: credential.identityToken,
        authorizationCode: credential.authorizationCode,
        email: credential.email,
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
      if (!mounted) return;
      await _finishSocialLogin(login, auth);
    } on AppleLoginCanceledException {
      // 사용자가 시스템 로그인 화면을 닫은 것은 실패로 안내하지 않는다.
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.code == 'E221') {
        await _showExistingEmailDialog(credential?.email);
      } else {
        setState(() => _loginError = 'Apple 로그인에 실패했어요. 다시 시도해 주세요');
      }
    } on AppleLoginFailedException {
      if (mounted) {
        setState(() => _loginError = 'Apple 로그인에 실패했어요. 다시 시도해 주세요');
      }
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  Future<void> _finishSocialLogin(
    Map<String, dynamic> login,
    AuthService auth,
  ) async {
    final pendingAt = DateTime.tryParse(
      login['pending_deletion_at'] as String? ?? '',
    );
    if (pendingAt != null) {
      _replaceAll(
        PendingDeletionScreen(scheduledAt: pendingAt, authService: auth),
      );
      return;
    }

    final termsAgreed = login['terms_agreed'] as bool?;
    final profileComplete = login['profile_complete'] as bool? ?? false;
    if (termsAgreed == false) {
      _replaceAll(
        TermsScreen(
          authService: auth,
          socialSignup: true,
          requiresNickname: !profileComplete,
        ),
      );
      return;
    }

    final status = await auth.termsStatus();
    if (!mounted) return;
    if (status['initial_agreement_required'] == true) {
      _replaceAll(
        TermsScreen(
          authService: auth,
          socialSignup: true,
          requiresNickname: !profileComplete,
        ),
      );
    } else if (status['reconsent_required'] == true) {
      _replaceAll(TermsScreen(authService: auth, reconsent: true));
    } else {
      _replaceAll(HomeScreen(financeService: AppServices.finance));
    }
  }

  Future<void> _showExistingEmailDialog(String? email) => showDialog<void>(
    context: context,
    barrierColor: const Color(0x80121215),
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: AppColors.secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 354,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 33, 24, 33),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '이미 가입된 이메일이에요',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                email?.isNotEmpty == true ? email! : '등록된 이메일',
                style: const TextStyle(color: AppColors.text80, fontSize: 12),
              ),
              const SizedBox(height: 18),
              const Text(
                '이 이메일은 이메일 회원가입으로 등록되어 있어요.\n이메일로 로그인해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.text50, fontSize: 12),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: '닫기',
                      backgroundColor: AppColors.selected,
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _DialogButton(
                      label: '이메일로 로그인',
                      backgroundColor: AppColors.main,
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _openVerification(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

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
                height: 355,
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
                top: 544,
                child: Text(
                  'Ver 1.0',
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
                top: 585,
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
              Positioned(
                left: 24,
                top: 661,
                child: _LoginButton(
                  label: 'Apple로 시작하기',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1A1601),
                  asset: AppAssets.appleLogo,
                  iconWidth: 16,
                  iconHeight: 20,
                  onPressed: _loginWithApple,
                ),
              ),
              if (_loginError case final message?)
                Positioned(
                  left: 24,
                  right: 24,
                  top: 468,
                  child: _LoginErrorToast(message: message),
                ),
              Positioned(
                left: 24,
                top: 737,
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

class _LoginErrorToast extends StatelessWidget {
  const _LoginErrorToast({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: 354,
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: AppColors.outline,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        SvgPicture.asset(AppAssets.loginError, width: 20, height: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor,
        side: const BorderSide(color: AppColors.text20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
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
