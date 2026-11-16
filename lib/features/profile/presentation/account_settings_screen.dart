import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/app_chevron.dart';
import '../../../shared/widgets/p2_widgets.dart';
import '../../analysis/data/insight_service.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../analysis/presentation/analysis_overview_screen.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/data/auth_service.dart';
import '../../finance/data/finance_service.dart';
import '../../home/presentation/home_screen.dart';
import '../../ledger/presentation/ledger_screen.dart';
import '../../register/presentation/register_type_screen.dart';
import 'account_delete_screen.dart';
import 'password_change_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({
    super.key,
    this.provider = 'email',
    this.authService,
    this.financeService,
    this.insightService,
  });
  final String provider;
  final AuthService? authService;
  final FinanceService? financeService;

  /// 할인 찾기 동의 조회·철회. 없으면 financeService 를 쓴다.
  final InsightService? insightService;

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _consentAgreed = false;

  String get provider => widget.provider;
  AuthService? get authService => widget.authService;
  FinanceService? get financeService => widget.financeService;

  InsightService? get _insight =>
      widget.insightService ??
      switch (widget.financeService) {
        final InsightService service => service,
        _ => null,
      };

  @override
  void initState() {
    super.initState();
    _loadConsent();
  }

  /// 마이_005-01: 할인 찾기에 동의한 사용자에게만 철회 메뉴를 보여준다. 실패하면 숨김.
  Future<void> _loadConsent() async {
    final insight = _insight;
    if (insight == null) return;
    try {
      final status = await insight.savingHintStatus();
      final consent = status['consent'] as Map<String, dynamic>?;
      if (mounted) setState(() => _consentAgreed = consent?['agreed'] == true);
    } catch (_) {
      if (mounted) setState(() => _consentAgreed = false);
    }
  }

  /// 분석_007-04 동의 철회 팝업.
  Future<void> _withdrawConsent() async {
    final insight = _insight;
    if (insight == null) return;
    final confirmed = await showCenterConfirm(
      context,
      title: '할인 찾기 정보 제공 동의를 철회할까요?',
      description: '철회하면 할인 찾기를 쓸 때 다시 동의해야 해요',
      note: '이미 보낸 정보는 Google에서 최대 55일 보관 후 삭제돼요',
      noteColor: AppColors.text50,
      noteSize: 12,
      confirmLabel: '철회하기',
      label: '동의 철회',
    );
    if (!confirmed || !mounted) return;
    try {
      await insight.withdrawSavingHintConsent();
      if (mounted) setState(() => _consentAgreed = false);
    } on ApiException catch (error) {
      if (mounted) showTopToast(context, error.message, error: true);
    } catch (_) {
      if (mounted) {
        showTopToast(context, '철회하지 못했어요. 다시 시도해 주세요', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = authService ?? AppServices.auth;
    final rows = <Widget>[
      if (provider == 'email')
        _SettingRow(
          label: '비밀번호 변경',
          value: '*********',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PasswordChangeScreen(authService: service),
            ),
          ),
        ),
      if (provider != 'email')
        _SettingRow(
          label: '로그인 수단',
          value: switch (provider) {
            'apple' => 'Apple',
            'kakao' => '카카오',
            _ => '-',
          },
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
      if (_consentAgreed)
        _SettingRow(
          key: const Key('account-consent-withdraw'),
          label: '할인 찾기 정보 제공 동의 철회',
          value: '',
          onTap: _withdrawConsent,
        ),
      const _SettingRow(label: '앱버전', value: '1.0'),
    ];
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
              top: 125,
              child: Text(
                '계정 설정',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  height: 32 / 27,
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 192,
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const SizedBox(height: 20),
                    rows[i],
                  ],
                  const SizedBox(height: 20),
                  _ActionButton(
                    label: '로그아웃',
                    onTap: () => _logout(context, service),
                  ),
                  const SizedBox(height: 20),
                  _ActionButton(
                    label: '회원 탈퇴',
                    danger: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AccountDeleteScreen(
                          authService: service,
                          provider: provider,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: AppBottomNavigation(
                selectedIndex: 4,
                onSelected: (index) => _handleNavigation(context, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context, AuthService service) {
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
              await service.logout();
              try {
                await AppServices.notifications.cancelDailyReminder();
                await AppServices.notifications.cancelMonthlyAiAlert();
              } catch (_) {
                // 알림을 쓸 수 없는 환경이면 무시한다.
              }
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
    String? documentUrl;
    if (authService != null) {
      try {
        final agreement = await authService!.myAgreement();
        documentUrl = agreement['document_url'] as String?;
      } catch (_) {
        // 환경설정 URL로 한 번 더 시도한다.
      }
    }
    final url = Uri.tryParse(
      (documentUrl ?? AppConfig.termsDocumentUrl).trim(),
    );
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

  void _handleNavigation(BuildContext context, int index) {
    if (index == 4) {
      Navigator.of(context).maybePop();
      return;
    }
    final Widget destination = switch (index) {
      0 => HomeScreen(financeService: financeService),
      1 => LedgerScreen(financeService: financeService),
      2 => RegisterTypeScreen(financeService: financeService),
      3 => AnalysisOverviewScreen(financeService: financeService),
      _ => HomeScreen(financeService: financeService),
    };
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.value,
    super.key,
    this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final showChevron = onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 354,
        height: showChevron ? 36 : 34,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.text50,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 22 / 14,
                ),
              ),
            ),
            if (value.isNotEmpty)
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 22 / 14,
                ),
              ),
            if (showChevron) ...[const SizedBox(width: 6), const AppChevron()],
          ],
        ),
      ),
    );
  }
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
