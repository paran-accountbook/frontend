import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/app_services.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../data/auth_service.dart';
import 'password_reset_complete_screen.dart';

class PasswordResetPasswordScreen extends StatefulWidget {
  const PasswordResetPasswordScreen({
    required this.email,
    this.verificationCode = '',
    this.authService,
    super.key,
  });

  final String email;
  final String verificationCode;
  final AuthService? authService;

  @override
  State<PasswordResetPasswordScreen> createState() =>
      _PasswordResetPasswordScreenState();
}

class _PasswordResetPasswordScreenState
    extends State<PasswordResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  bool _isStrongPassword(String value) {
    final categories = [
      RegExp('[A-Za-z]').hasMatch(value),
      RegExp('[0-9]').hasMatch(value),
      RegExp(r'[^A-Za-z0-9]').hasMatch(value),
    ].where((matched) => matched).length;
    return value.length >= 8 && categories >= 2;
  }

  Future<void> _changePassword() async {
    final password = _passwordController.text;
    if (!_isStrongPassword(password)) {
      setState(() => _errorMessage = '비밀번호 규칙을 확인해 주세요');
      return;
    }
    if (password != _confirmationController.text) {
      setState(() => _errorMessage = '비밀번호가 일치하지 않습니다');
      return;
    }
    if (widget.verificationCode.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        await (widget.authService ?? AppServices.auth).resetPassword(
          email: widget.email,
          code: widget.verificationCode,
          newPassword: password,
        );
      } on ApiException catch (error) {
        if (mounted) setState(() => _errorMessage = error.message);
        return;
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      if (!mounted) return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PasswordResetCompleteScreen(),
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
            top: 324,
            width: 354,
            child: Column(
              children: [
                const Text(
                  '새 비밀번호를 설정해 주세요',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  controller: _passwordController,
                  hintText: '새 비밀번호',
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() => _errorMessage = null),
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  controller: _confirmationController,
                  hintText: '새 비밀번호 확인',
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() => _errorMessage = null),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '•  8자 이상\n•  영문 / 숫자 / 특수문자 중 2종 이상 조합\n•  기존 비밀번호와 다른 값',
                    style: TextStyle(
                      color: Color(0xCCE2E2F9),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
                if (_errorMessage case final message?) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Color(0xFFFF6B7A),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          AuthBottomAction(
            label: _isLoading ? '변경 중...' : '비밀번호 변경',
            onPressed: _isLoading ? null : _changePassword,
          ),
        ],
      ),
    );
  }
}
