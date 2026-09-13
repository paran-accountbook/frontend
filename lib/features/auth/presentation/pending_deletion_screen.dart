import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../../home/presentation/home_screen.dart';
import '../data/auth_service.dart';
import 'login_screen.dart';

class PendingDeletionScreen extends StatefulWidget {
  const PendingDeletionScreen({
    required this.scheduledAt,
    this.authService,
    super.key,
  });

  final DateTime scheduledAt;
  final AuthService? authService;

  @override
  State<PendingDeletionScreen> createState() => _PendingDeletionScreenState();
}

class _PendingDeletionScreenState extends State<PendingDeletionScreen> {
  bool _isLoading = false;
  String? _error;

  int get _remainingDays {
    final hours = widget.scheduledAt.difference(DateTime.now()).inHours;
    return ((hours <= 0 ? 0 : hours) / 24).ceil();
  }

  Future<void> _cancelDeletion() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await (widget.authService ?? AppServices.auth).cancelDeletion();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
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

  Future<void> _logout() async {
    await (widget.authService ?? AppServices.auth).logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      showBackButton: false,
      child: Stack(
        children: [
          Positioned(
            left: 24,
            right: 24,
            top: 366,
            child: Column(
              children: [
                SvgPicture.asset(
                  AppAssets.pendingDeletion,
                  width: 36,
                  height: 36,
                ),
                const SizedBox(height: 20),
                const Text(
                  '탈퇴 신청된 계정입니다',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '로그인 후 탈퇴를 취소하거나 삭제 완료 후 다시 가입해주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.text80, fontSize: 12),
                ),
                const SizedBox(height: 20),
                Text(
                  '삭제까지 $_remainingDays일 남았습니다',
                  style: const TextStyle(
                    color: Color(0xFFA8A3FF),
                    fontSize: 12,
                  ),
                ),
                if (_error case final message?) ...[
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFF6B7A),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 207,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00121215), Color(0xE6121215)],
                  stops: [0, 0.8],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 25, 24, 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _PendingActionButton(
                      label: _isLoading ? '처리 중...' : '탈퇴 취소',
                      onPressed: _isLoading ? null : _cancelDeletion,
                      primary: true,
                    ),
                    const SizedBox(height: 20),
                    _PendingActionButton(
                      label: '로그아웃',
                      onPressed: _isLoading ? null : _logout,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingActionButton extends StatelessWidget {
  const _PendingActionButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 354,
    height: 56,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: primary ? AppColors.main : AppColors.selected,
        foregroundColor: AppColors.text,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.text20),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
