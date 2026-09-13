import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/app_services.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/presentation/login_screen.dart';

class AccountDeleteScreen extends StatefulWidget {
  const AccountDeleteScreen({
    super.key,
    this.authService,
    this.provider = 'email',
  });
  final AuthService? authService;
  final String provider;
  @override
  State<AccountDeleteScreen> createState() => _AccountDeleteScreenState();
}

class _AccountDeleteScreenState extends State<AccountDeleteScreen> {
  final _password = TextEditingController();
  bool _understood = false;
  bool _isLoading = false;
  String? _error;
  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await (widget.authService ?? AppServices.auth).deleteAccount(
        password: widget.provider == 'email' ? _password.text : null,
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => AuthPage(
    child: Stack(
      children: [
        const Positioned(
          left: 24,
          top: 128,
          child: Text(
            '회원 탈퇴',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 27,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Positioned(
          left: 24,
          top: 190,
          width: 354,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '탈퇴 신청 후 14일이 지나면 모든 데이터가 영구 삭제되며 복구할 수 없습니다.',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '계정 정보, 소비·수입 내역, 영수증 및 첨부 사진, 더치페이 정산 기록, 계좌번호, 리워드가 삭제됩니다.',
                style: TextStyle(
                  color: AppColors.text50,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              AuthTextField(
                controller: _password,
                hintText: widget.provider == 'email' ? '비밀번호 재입력' : '탈퇴 입력',
                obscureText: widget.provider == 'email',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _understood,
                onChanged: (value) =>
                    setState(() => _understood = value ?? false),
                title: const Text(
                  '안내 내용을 확인했습니다',
                  style: TextStyle(color: AppColors.text, fontSize: 14),
                ),
              ),
              if (_error case final message?)
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFFF6B7A),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        AuthBottomAction(
          label: _isLoading ? '신청 중...' : '탈퇴 신청',
          onPressed:
              _understood &&
                  (widget.provider == 'email'
                      ? _password.text.isNotEmpty
                      : _password.text.trim() == '탈퇴') &&
                  !_isLoading
              ? _submit
              : null,
        ),
      ],
    ),
  );
}
