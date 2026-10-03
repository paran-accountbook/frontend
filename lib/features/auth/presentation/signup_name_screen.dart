import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../../home/presentation/home_screen.dart';
import '../data/auth_service.dart';

class SignupNameScreen extends StatefulWidget {
  const SignupNameScreen({
    required this.email,
    required this.password,
    super.key,
    this.marketingAgreed = false,
    this.authService,
  });

  final String email;
  final String password;
  final bool marketingAgreed;
  final AuthService? authService;

  @override
  State<SignupNameScreen> createState() => _SignupNameScreenState();
}

class _SignupNameScreenState extends State<SignupNameScreen> {
  final _nameController = TextEditingController();
  bool _showError = false;
  bool _isLoading = false;
  String? _apiError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _nameController.text.trim();
    if (name.length < 2 || name.length > 10) {
      setState(() => _showError = true);
      return;
    }
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _apiError = null;
    });
    try {
      await (widget.authService ?? AppServices.auth).signup(
        email: widget.email,
        password: widget.password,
        nickname: name,
        marketingAgreed: widget.marketingAgreed,
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _apiError = error.message);
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => HomeScreen(financeService: AppServices.finance),
      ),
      (_) => false,
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
                  '이름을 설정해 주세요',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  controller: _nameController,
                  hintText: '이름',
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (_showError) setState(() => _showError = false);
                    if (_apiError != null) setState(() => _apiError = null);
                  },
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '•  더치페이에서 사용됩니다\n•  2~10자 이내',
                    style: TextStyle(
                      color: Color(0xCCE2E2F9),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
                if (_showError) ...[
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '이름은 2~10자로 입력해 주세요',
                      style: TextStyle(color: Color(0xFFFF6B7A), fontSize: 12),
                    ),
                  ),
                ],
                if (_apiError case final message?) ...[
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
            label: _isLoading ? '가입 중...' : '가입 완료',
            leadingIconAsset: AppAssets.signupComplete,
            onPressed: _isLoading ? null : _continue,
          ),
        ],
      ),
    );
  }
}
