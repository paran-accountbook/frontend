import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../data/auth_service.dart';
import 'signup_password_screen.dart';
import 'terms_screen.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    super.key,
    this.email,
    this.onVerified,
    this.onCodeVerified,
    this.authService,
    this.passwordResetFlow = false,
  });

  final String? email;
  final VoidCallback? onVerified;
  final ValueChanged<String>? onCodeVerified;
  final AuthService? authService;
  final bool passwordResetFlow;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  static const _verificationDuration = Duration(minutes: 3);
  static const _resendCooldown = Duration(seconds: 30);

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _timer;
  int _remainingSeconds = _verificationDuration.inSeconds;
  int _resendSeconds = _resendCooldown.inSeconds;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds == 0 && _resendSeconds == 0) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) _remainingSeconds--;
        if (_resendSeconds > 0) _resendSeconds--;
      });
    });
  }

  Future<void> _resend() async {
    final email = widget.email;
    if (email != null) {
      try {
        final service = widget.authService ?? AppServices.auth;
        if (widget.passwordResetFlow) {
          await service.sendPasswordResetCode(email);
        } else {
          await service.sendVerificationCode(email);
        }
      } on ApiException catch (error) {
        if (mounted) setState(() => _errorMessage = error.message);
        return;
      }
    }
    setState(() {
      _controller.clear();
      _remainingSeconds = _verificationDuration.inSeconds;
      _resendSeconds = _resendCooldown.inSeconds;
      _errorMessage = null;
    });
    _focusNode.requestFocus();
    _startTimer();
  }

  void _showResendCooldown() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$_resendSeconds초 후 다시 요청할 수 있어요.')),
      );
  }

  Future<void> _complete() async {
    if (_controller.text.length != 6 || _remainingSeconds == 0) return;
    if (_isLoading) return;
    final code = _controller.text;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final email = widget.email;
      if (!widget.passwordResetFlow && email != null) {
        await (widget.authService ?? AppServices.auth).verifyCode(
          email: email,
          code: code,
        );
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (!mounted) return;
    if (widget.onCodeVerified case final callback?) {
      callback(code);
      return;
    }
    if (widget.onVerified case final callback?) {
      callback();
      return;
    }
    final email = widget.email ?? '';
    final service = widget.authService ?? AppServices.auth;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TermsScreen(
          onAgeConfirmed: (ageConfirmed) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SignupPasswordScreen(
                  email: email,
                  ageConfirmed: ageConfirmed,
                  authService: service,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String get _timerLabel {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '남은 시간 $minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final digits = _controller.text.padRight(6).substring(0, 6).split('');
    return AuthPage(
      child: Stack(
        children: [
          Positioned(
            left: -100,
            top: -100,
            width: 1,
            height: 1,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLength: 6,
              keyboardType: TextInputType.number,
              keyboardAppearance: Brightness.light,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration.collapsed(hintText: ''),
              onChanged: (value) {
                setState(() {});
                if (value.length == 6) _complete();
              },
              onSubmitted: (_) => _complete(),
            ),
          ),
          const Positioned(
            top: 147,
            width: 402,
            child: Text(
              '인증번호를 입력하세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Positioned(
            top: 181,
            width: 402,
            child: Text(
              _timerLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFA8A3FF), fontSize: 12),
            ),
          ),
          Positioned(
            left: 24,
            top: 215,
            width: 354,
            height: 230,
            child: GestureDetector(
              onTap: _focusNode.requestFocus,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -26,
                    top: -22,
                    width: 406,
                    height: 282,
                    child: SvgPicture.asset(
                      AppAssets.verificationCodeReceipt,
                      fit: BoxFit.fill,
                    ),
                  ),
                  Positioned(
                    left: 17,
                    top: 27,
                    width: 320,
                    height: 7,
                    child: SvgPicture.asset(AppAssets.receiptAsteriskDivider),
                  ),
                  Positioned(
                    left: 17,
                    bottom: 28,
                    width: 320,
                    height: 7,
                    child: SvgPicture.asset(AppAssets.receiptAsteriskDivider),
                  ),
                  Positioned(
                    left: 19,
                    top: 92,
                    width: 316,
                    height: 46,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        return Row(
                          children: [
                            SizedBox(
                              width: 46,
                              child: Text(
                                digits[index],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF1B1B1B),
                                  fontFamily: 'Amarante',
                                  fontSize: 30,
                                ),
                              ),
                            ),
                            if (index != 5)
                              SizedBox(
                                width: 2,
                                height: 20,
                                child: SvgPicture.asset(
                                  AppAssets.verificationDigitDivider,
                                  fit: BoxFit.fill,
                                ),
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AuthBottomAction(
            label: '인증번호 재발송',
            bottom: 339,
            onPressed: _resendSeconds == 0 ? _resend : _showResendCooldown,
          ),
          if (_errorMessage case final message?)
            Positioned(
              left: 24,
              right: 24,
              top: 460,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFF6B7A), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
