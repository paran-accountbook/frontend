import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/app_services.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../data/auth_service.dart';
import 'password_reset_password_screen.dart';
import 'verification_screen.dart';

class PasswordResetEmailScreen extends StatefulWidget {
  const PasswordResetEmailScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<PasswordResetEmailScreen> createState() =>
      _PasswordResetEmailScreenState();
}

class _PasswordResetEmailScreenState extends State<PasswordResetEmailScreen> {
  final _emailController = TextEditingController();
  bool _showError = false;
  bool _isLoading = false;
  String? _apiError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _showError = true);
      return;
    }
    final service = widget.authService ?? AppServices.auth;
    setState(() {
      _isLoading = true;
      _apiError = null;
    });
    try {
      await service.sendPasswordResetCode(email);
    } on ApiException catch (error) {
      if (mounted) setState(() => _apiError = error.message);
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VerificationScreen(
          email: email,
          authService: service,
          passwordResetFlow: true,
          onCodeVerified: (code) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PasswordResetPasswordScreen(
                  email: email,
                  verificationCode: code,
                  authService: service,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      child: Stack(
        children: [
          Positioned(
            left: 24,
            top: 323,
            width: 354,
            child: Column(
              children: [
                const Text(
                  '가입한 이메일을 입력하세요',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  controller: _emailController,
                  hintText: '이메일',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (_showError) setState(() => _showError = false);
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  _apiError ??
                      (_showError
                          ? '올바른 이메일 주소를 입력해 주세요'
                          : '가입된 이메일인 경우 인증코드가 전송됩니다'),
                  style: TextStyle(
                    color: _showError || _apiError != null
                        ? const Color(0xFFFF6B7A)
                        : AppColors.text80,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          AuthBottomAction(
            label: _isLoading ? '전송 중...' : '인증번호 받기',
            onPressed: _isLoading ? () {} : _requestCode,
          ),
        ],
      ),
    );
  }
}
