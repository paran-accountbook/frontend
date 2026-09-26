import 'package:flutter/material.dart';

import '../../../core/network/app_services.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../../home/presentation/home_screen.dart';
import '../data/auth_service.dart';

class KakaoSignupNameScreen extends StatefulWidget {
  const KakaoSignupNameScreen({
    super.key,
    this.authService,
    this.marketingAgreed = false,
  });

  final AuthService? authService;
  final bool marketingAgreed;

  @override
  State<KakaoSignupNameScreen> createState() => _KakaoSignupNameScreenState();
}

class _KakaoSignupNameScreenState extends State<KakaoSignupNameScreen> {
  final _controller = TextEditingController();
  bool _showError = false;
  bool _isLoading = false;
  String? _apiError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final nickname = _controller.text.trim();
    if (nickname.length < 2 || nickname.length > 10) {
      setState(() => _showError = true);
      return;
    }
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _apiError = null;
    });
    try {
      await (widget.authService ?? AppServices.auth).initialAgree(
        nickname: nickname,
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
  Widget build(BuildContext context) => AuthPage(
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
                controller: _controller,
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
                const SizedBox(height: 12),
                const Text(
                  '이름은 2~10자로 입력해 주세요',
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
          label: _isLoading ? '가입 중...' : '가입 완료',
          leadingIconAsset: AppAssets.signupComplete,
          onPressed: _isLoading ? () {} : _continue,
        ),
      ],
    ),
  );
}
