import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../shared/widgets/app_chevron.dart';
import '../../auth/presentation/login_screen.dart';
import 'account_delete_screen.dart';
import 'password_change_screen.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key, this.provider = 'email'});
  final String provider;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
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
                onPressed: () => Navigator.of(context).maybePop(),
                icon: SvgPicture.asset(AppAssets.arrowBackLight),
              ),
            ),
            const Positioned(
              left: 24,
              top: 128,
              child: Text(
                '계정 설정',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 186,
              child: Column(
                children: [
                  if (provider == 'email')
                    _SettingRow(
                      label: '비밀번호 변경',
                      value: '*********',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PasswordChangeScreen(
                            authService: AppServices.auth,
                          ),
                        ),
                      ),
                    ),
                  _SettingRow(
                    label: '서비스 이용약관',
                    value: '보기',
                    onTap: () => _openTerms(context),
                  ),
                  _SettingRow(
                    label: '개인정보 처리방침',
                    value: '보기',
                    onTap: () => _openTerms(context),
                  ),
                  const _SettingRow(label: '앱버전', value: '1.0'),
                  const SizedBox(height: 20),
                  _ActionButton(label: '로그아웃', onTap: () => _logout(context)),
                  const SizedBox(height: 20),
                  _ActionButton(
                    label: '회원 탈퇴',
                    danger: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AccountDeleteScreen(
                          authService: AppServices.auth,
                          provider: provider,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              await AppServices.auth.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  Future<void> _openTerms(BuildContext context) async {
    final url = Uri.tryParse(AppConfig.termsDocumentUrl.trim());
    if (url != null &&
        url.hasScheme &&
        await launchUrl(url, mode: LaunchMode.inAppBrowserView)) {
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('약관을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요')),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.value, this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: SizedBox(
      width: 354,
      height: 54,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.text50, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: AppColors.text, fontSize: 14),
          ),
          const SizedBox(width: 8),
          const AppChevron(size: 20),
        ],
      ),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.danger = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool danger;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 354,
    height: 56,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.selected,
        side: const BorderSide(color: AppColors.text20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: danger ? const Color(0xFFCF376A) : AppColors.text,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
