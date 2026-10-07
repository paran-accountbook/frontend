import 'dart:ui';

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
  bool _emailConfirmationStep = false;
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
      if (!mounted) return;
      setState(() => _error = error.message);
      if (!_isEmailProvider) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
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
                if (_emailConfirmationStep) {
                  setState(() => _emailConfirmationStep = false);
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
          if (_emailConfirmationStep)
            _buildEmailConfirmation()
          else
            _buildSummary(),
          AuthBottomAction(
            label: _emailConfirmationStep
                ? (_isLoading ? '처리 중...' : '확인')
                : '다음',
            onPressed: _emailConfirmationStep
                ? (_canSubmit && !_isLoading ? _submit : null)
                : _isLoading
                ? null
                : _onNext,
          ),
        ],
      ),
    ),
  );

  bool get _isEmailProvider => widget.provider == 'email';

  bool get _canSubmit => _password.text.isNotEmpty;

  void _onNext() {
    if (_isEmailProvider) {
      setState(() => _emailConfirmationStep = true);
      return;
    }
    _showSocialDeleteConfirmation();
  }

  Future<void> _showSocialDeleteConfirmation() => showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    barrierLabel: '회원 탈퇴 재확인',
    transitionDuration: const Duration(milliseconds: 150),
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
    pageBuilder: (dialogContext, animation, secondaryAnimation) => Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: const ColoredBox(color: Color(0x80121215)),
              ),
            ),
          ),
          Center(
            child: _SocialDeleteConfirmationDialog(
              onCancel: () => Navigator.of(dialogContext).pop(),
              onConfirm: () {
                Navigator.of(dialogContext).pop();
                _submit();
              },
            ),
          ),
        ],
      ),
    ),
  );

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

  Widget _buildEmailConfirmation() => Positioned(
    left: 24,
    right: 24,
    top: 376,
    child: Column(
      children: [
        const Text(
          '비밀번호를 입력하세요',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        AuthTextField(
          controller: _password,
          hintText: '비밀번호',
          obscureText: true,
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

class _SocialDeleteConfirmationDialog extends StatelessWidget {
  const _SocialDeleteConfirmationDialog({
    required this.onCancel,
    required this.onConfirm,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => Container(
    width: 354,
    padding: const EdgeInsets.symmetric(vertical: 33),
    decoration: BoxDecoration(
      color: AppColors.secondary,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '정말 탈퇴할까요?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 17 / 14,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '14일 안에 다시 로그인하면 탈퇴를 취소할 수 있어요',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.text80,
            fontSize: 12,
            height: 14 / 12,
          ),
        ),
        const SizedBox(height: 18),
        const Divider(height: 1, thickness: 1, color: AppColors.text20),
        const SizedBox(height: 18),
        const Text(
          '14일이 지나면 모든 데이터가 삭제돼요',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFFF7373),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 17 / 14,
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: _DialogActionButton(label: '취소', onPressed: onCancel),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DialogActionButton(
                  label: '탈퇴하기',
                  color: const Color(0xFFCF376A),
                  textColor: Colors.white,
                  onPressed: onConfirm,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DialogActionButton extends StatelessWidget {
  const _DialogActionButton({
    required this.label,
    required this.onPressed,
    this.color = AppColors.selected,
    this.textColor = AppColors.text,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: color,
        foregroundColor: textColor,
        side: const BorderSide(color: AppColors.text20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 18 / 15,
        ),
      ),
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
