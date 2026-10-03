import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/app_services.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../data/auth_service.dart';
import 'verification_screen.dart';

class EmailSignupScreen extends StatefulWidget {
  const EmailSignupScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<EmailSignupScreen> createState() => _EmailSignupScreenState();
}

class _EmailSignupScreenState extends State<EmailSignupScreen> {
  final _emailController = TextEditingController();
  bool _showEmailError = false;
  bool _isLoading = false;
  String? _apiError;

  bool get _isValidEmail => RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  ).hasMatch(_emailController.text.trim());

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_isValidEmail) {
      setState(() => _showEmailError = true);
      return;
    }
    setState(() {
      _isLoading = true;
      _apiError = null;
    });
    final email = _emailController.text.trim();
    final service = widget.authService ?? AppServices.auth;
    try {
      await service.checkEmail(email);
      await service.sendVerificationCode(email);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              VerificationScreen(email: email, authService: service),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _apiError = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  '이메일을 입력하세요',
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
                    if (_showEmailError) {
                      setState(() => _showEmailError = false);
                    }
                    if (_apiError != null) setState(() => _apiError = null);
                  },
                ),
                if (_showEmailError) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '올바른 이메일 주소를 입력해 주세요',
                    style: TextStyle(color: Color(0xFFFF6B7A), fontSize: 12),
                  ),
                ],
                if (_apiError case final message?) ...[
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFFFF6B7A),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          AuthBottomAction(
            label: _isLoading ? '전송 중...' : '인증번호 받기',
            onPressed: _isLoading ? null : _requestCode,
          ),
        ],
      ),
    );
  }
}
