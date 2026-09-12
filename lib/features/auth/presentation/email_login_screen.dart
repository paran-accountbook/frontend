import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../data/auth_service.dart';
import '../../home/presentation/home_screen.dart';
import 'password_reset_email_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key, this.onForgotPassword, this.authService});

  final VoidCallback? onForgotPassword;
  final AuthService? authService;

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showValidationError = false;
  bool _isLoading = false;
  String? _apiError;

  bool get _canSubmit =>
      _emailController.text.trim().contains('@') &&
      _passwordController.text.isNotEmpty;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_canSubmit) {
      setState(() => _showValidationError = true);
      return;
    }
    setState(() {
      _isLoading = true;
      _apiError = null;
    });
    try {
      await (widget.authService ?? AppServices.auth).login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _apiError = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openPasswordReset() {
    if (widget.onForgotPassword case final callback?) {
      callback();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PasswordResetEmailScreen()),
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
                SvgPicture.asset(AppAssets.mail, width: 32, height: 34),
                const SizedBox(height: 20),
                AuthTextField(
                  controller: _emailController,
                  hintText: '이메일',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (_showValidationError) {
                      setState(() => _showValidationError = false);
                    }
                    if (_apiError != null) setState(() => _apiError = null);
                  },
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  controller: _passwordController,
                  hintText: '비밀번호',
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (_showValidationError) {
                      setState(() => _showValidationError = false);
                    }
                    if (_apiError != null) setState(() => _apiError = null);
                  },
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: _openPasswordReset,
                  child: Text(
                    '비밀번호를 잊으셨나요?',
                    style: TextStyle(color: AppColors.text80, fontSize: 12),
                  ),
                ),
                if (_showValidationError) ...[
                  const SizedBox(height: 12),
                  const Text(
                    '이메일과 비밀번호를 입력해 주세요',
                    style: TextStyle(color: Color(0xFFFF6B7A), fontSize: 12),
                  ),
                ],
                if (_apiError case final message?) ...[
                  const SizedBox(height: 12),
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
            label: _isLoading ? '로그인 중...' : '로그인',
            onPressed: _isLoading ? () {} : _login,
          ),
        ],
      ),
    );
  }
}
