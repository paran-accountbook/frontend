import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/app_services.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../../../shared/widgets/design_canvas.dart';
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
  bool _confirmationStep = false;
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
  Widget build(BuildContext context) => Scaffold(
    body: DesignCanvas(
      width: 402,
      height: 874,
      child: Stack(
        children: [
          const ColoredBox(color: AppColors.background),
          Positioned(
            left: 24,
            top: 50,
            width: 34,
            height: 34,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                if (_confirmationStep) {
                  setState(() => _confirmationStep = false);
                } else {
                  Navigator.of(context).maybePop();
                }
              },
              icon: SvgPicture.asset(AppAssets.arrowBackLight),
            ),
          ),
          const Positioned(
            left: 24,
            top: 125,
            child: Text(
              '회원 탈퇴',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 27,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Positioned(
            left: 24,
            top: 177,
            child: Text(
              '탈퇴하면 아래 데이터가 모두 삭제돼요',
              style: TextStyle(
                color: AppColors.text80,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_confirmationStep) _buildConfirmation() else _buildSummary(),
          AuthBottomAction(
            label: _confirmationStep ? (_isLoading ? '처리 중...' : '확인') : '다음',
            onPressed: _confirmationStep
                ? (_canSubmit && !_isLoading ? _submit : null)
                : () => setState(() => _confirmationStep = true),
          ),
        ],
      ),
    ),
  );

  bool get _canSubmit => widget.provider == 'email'
      ? _password.text.isNotEmpty
      : _password.text.trim() == '탈퇴';

  Widget _buildSummary() => const Positioned(
    left: 24,
    right: 24,
    top: 310,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DeleteItem('계정 정보'),
        _DeleteItem('소비 · 수입 내역'),
        _DeleteItem('영수증 이미지'),
        _DeleteItem('첨부 사진'),
        _DeleteItem('더치페이 정산 기록'),
        _DeleteItem('계좌번호'),
        _DeleteItem('리워드'),
        SizedBox(height: 16),
        Text(
          '• 14일 안에 다시 로그인하시면 탈퇴를 취소할 수 있습니다\n'
          '• 삭제된 데이터는 복구할 수 없습니다',
          style: TextStyle(color: AppColors.text80, fontSize: 12, height: 1.35),
        ),
      ],
    ),
  );

  Widget _buildConfirmation() => Positioned(
    left: 24,
    right: 24,
    top: 376,
    child: Column(
      children: [
        Text(
          widget.provider == 'email' ? '비밀번호를 입력하세요' : '탈퇴를 입력하세요',
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        AuthTextField(
          controller: _password,
          hintText: widget.provider == 'email' ? '비밀번호' : '탈퇴 입력',
          obscureText: widget.provider == 'email',
          onChanged: (_) => setState(() {}),
        ),
        if (_error case final message?) ...[
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Color(0xFFFF6B7A), fontSize: 12),
          ),
        ],
      ],
    ),
  );
}

class _DeleteItem extends StatelessWidget {
  const _DeleteItem(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      children: [
        SvgPicture.asset(AppAssets.deleteDot, width: 34, height: 34),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
