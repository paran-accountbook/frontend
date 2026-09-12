import 'package:flutter/material.dart';

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
      child: Stack(
        children: [
          Positioned(
            left: 24,
            right: 24,
            top: 280,
            child: Column(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.main,
                  size: 52,
                ),
                const SizedBox(height: 24),
                const Text(
                  '탈퇴 신청된 계정입니다',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '계정 삭제까지 $_remainingDays일 남았습니다',
                  style: const TextStyle(color: AppColors.text80, fontSize: 15),
                ),
                if (_error case final message?) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFF6B7A),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 36),
                TextButton(
                  onPressed: _isLoading ? null : _logout,
                  child: const Text(
                    '로그아웃',
                    style: TextStyle(color: AppColors.text80),
                  ),
                ),
              ],
            ),
          ),
          AuthBottomAction(
            label: _isLoading ? '처리 중...' : '탈퇴 취소',
            onPressed: _isLoading ? () {} : _cancelDeletion,
          ),
        ],
      ),
    );
  }
}
