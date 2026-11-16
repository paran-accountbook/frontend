import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../home/presentation/home_screen.dart';
import '../data/auth_service.dart';
import '../domain/signup_draft.dart';
import 'kakao_signup_name_screen.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({
    super.key,
    this.signupDraft,
    this.onAgreed,
    this.onAgeConfirmed,
    this.authService,
    this.socialSignup = false,
    this.requiresNickname = false,
    this.reconsent = false,
    this.documentLauncher,
  });

  final SignupDraft? signupDraft;
  final VoidCallback? onAgreed;
  final ValueChanged<bool>? onAgeConfirmed;
  final AuthService? authService;
  final bool socialSignup;
  final bool requiresNickname;
  final bool reconsent;
  final Future<bool> Function(Uri uri)? documentLauncher;

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  static const _labels = ['[필수] 만 18세 이상입니다', '[필수] 서비스 이용약관 동의'];

  final _selected = List.filled(_labels.length, false);
  bool _showRequiredError = false;
  bool _isLoading = false;
  String? _apiError;

  bool get _allSelected => _selected.every((selected) => selected);
  bool get _requiredSelected => _allSelected;

  /// 인증_003-02: 약관 전문 보기 — 서버가 알려주는 노션 페이지 링크를 연다.
  /// 비로그인: GET /auth/terms/document → document_url
  /// 로그인 후(소셜 신규·재동의): GET /auth/terms/status → latest_document_url
  Future<Uri> _termsUri() async {
    final auth = widget.authService ?? AppServices.auth;
    try {
      final loggedIn = widget.socialSignup || widget.reconsent;
      final data = loggedIn
          ? await auth.termsStatus()
          : await auth.termsDocument();
      final url =
          (loggedIn ? data['latest_document_url'] : data['document_url'])
              as String?;
      if (url != null && url.isNotEmpty) return Uri.parse(url);
    } catch (_) {
      // 링크를 받지 못하면 앱에 설정된 기본 링크를 쓴다.
    }
    return Uri.parse(AppConfig.privacyPolicyUrl);
  }

  Future<void> _openTerms() async {
    final uri = await _termsUri();
    if (!mounted) return;
    final opened = widget.documentLauncher != null
        ? await widget.documentLauncher!(uri)
        : await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (opened || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('약관을 열지 못했습니다. 잠시 후 다시 시도해 주세요')),
    );
  }

  void _toggleItem(int index) {
    setState(() {
      _selected[index] = !_selected[index];
      if (_requiredSelected) _showRequiredError = false;
    });
  }

  void _toggleAll() {
    final next = !_allSelected;
    setState(() {
      for (var index = 0; index < _selected.length; index++) {
        _selected[index] = next;
      }
      _showRequiredError = false;
    });
  }

  Future<void> _agree() async {
    if (!_requiredSelected) {
      setState(() => _showRequiredError = true);
      return;
    }
    final ageConfirmed = _selected[0];
    if (widget.onAgeConfirmed case final callback?) {
      callback(ageConfirmed);
      return;
    }
    if (widget.onAgreed case final callback?) {
      callback();
      return;
    }
    if (widget.signupDraft case final draft?) {
      setState(() {
        _isLoading = true;
        _apiError = null;
      });
      try {
        await (widget.authService ?? AppServices.auth).signup(
          email: draft.email,
          password: draft.password,
          nickname: draft.name,
          ageConfirmed: ageConfirmed,
          marketingAgreed: false,
        );
      } on ApiException catch (error) {
        if (mounted) setState(() => _apiError = error.message);
        return;
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      if (!mounted) return;
    } else if (widget.socialSignup) {
      if (widget.requiresNickname) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => KakaoSignupNameScreen(
              authService: widget.authService ?? AppServices.auth,
              ageConfirmed: ageConfirmed,
              marketingAgreed: false,
            ),
          ),
        );
        return;
      }
      setState(() {
        _isLoading = true;
        _apiError = null;
      });
      try {
        await (widget.authService ?? AppServices.auth).initialAgree(
          ageConfirmed: ageConfirmed,
          marketingAgreed: false,
        );
      } on ApiException catch (error) {
        if (mounted) setState(() => _apiError = error.message);
        return;
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      if (!mounted) return;
    } else if (widget.reconsent) {
      setState(() {
        _isLoading = true;
        _apiError = null;
      });
      try {
        await (widget.authService ?? AppServices.auth).agreeToLatestTerms();
      } on ApiException catch (error) {
        if (mounted) setState(() => _apiError = error.message);
        return;
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      if (!mounted) return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) =>
            widget.authService == null &&
                widget.signupDraft == null &&
                !widget.socialSignup &&
                !widget.reconsent
            ? const HomeScreen()
            : HomeScreen(financeService: AppServices.finance),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        width: 402,
        height: 874,
        child: ColoredBox(
          color: AppColors.background,
          child: Stack(
            children: [
              Positioned(
                left: 24,
                top: 50,
                width: 34,
                height: 34,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: '뒤로가기',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: SvgPicture.asset(AppAssets.arrowBackLight),
                ),
              ),
              const Positioned(
                left: 24,
                top: 129,
                child: Text(
                  '약관동의',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                left: 24,
                top: 177,
                child: Text(
                  '소비로그를 사용하기 위해서\n아래 약관의 동의가 필요합니다',
                  style: TextStyle(
                    color: AppColors.text80,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                top: 534,
                child: Column(
                  children: [
                    _TermsAgreementRow(
                      label: '전체 동의하기',
                      selected: _allSelected,
                      onPressed: _toggleAll,
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: AppColors.text10),
                    const SizedBox(height: 20),
                    ...List.generate(_labels.length, (index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == _labels.length - 1 ? 0 : 20,
                        ),
                        child: _TermsRow(
                          index: index,
                          label: _labels[index],
                          selected: _selected[index],
                          onPressed: () => _toggleItem(index),
                          onViewPressed: index == 0 ? null : _openTerms,
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    _PrivacyNoticeRow(onPressed: _openTerms),
                  ],
                ),
              ),
              if (_showRequiredError || _apiError != null)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 88,
                  child: Text(
                    _apiError ?? '필수 약관에 동의해 주세요',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFF6B7A),
                      fontSize: 12,
                    ),
                  ),
                ),
              AuthBottomAction(
                label: _isLoading ? '가입 중...' : '동의합니다',
                onPressed: _isLoading ? null : _agree,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsAgreementRow extends StatelessWidget {
  const _TermsAgreementRow({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onPressed,
    child: SizedBox(
      height: 30,
      child: Row(
        children: [
          _TermsCheckbox(selected: selected, onPressed: onPressed),
          const SizedBox(width: 20),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({
    required this.index,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.onViewPressed,
  });

  final int index;
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final VoidCallback? onViewPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          _TermsCheckbox(selected: selected, onPressed: onPressed),
          const SizedBox(width: 20),
          Expanded(
            child: GestureDetector(
              onTap: onPressed,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: label.substring(0, 4),
                      style: const TextStyle(color: AppColors.main),
                    ),
                    TextSpan(
                      text: label.substring(4),
                      style: const TextStyle(color: AppColors.text80),
                    ),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (onViewPressed != null)
            IconButton(
              key: ValueKey('terms-view-$index'),
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints.tightFor(width: 30, height: 30),
              tooltip: '$label 보기',
              onPressed: onViewPressed,
              icon: SvgPicture.asset(
                AppAssets.termsArrowRight,
                width: 24,
                height: 24,
              ),
            ),
        ],
      ),
    );
  }
}

/// 체크박스 없는 '개인정보 수집·이용 안내' 행 (약관 전문과 같은 노션 페이지).
class _PrivacyNoticeRow extends StatelessWidget {
  const _PrivacyNoticeRow({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const Key('terms-privacy-notice'),
    behavior: HitTestBehavior.opaque,
    onTap: onPressed,
    child: SizedBox(
      height: 24,
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '개인정보 수집 · 이용 안내',
              style: TextStyle(
                color: AppColors.text80,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: SvgPicture.asset(
              AppAssets.termsArrowRight,
              width: 24,
              height: 24,
            ),
          ),
        ],
      ),
    ),
  );
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.selected, required this.onPressed});

  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.main : AppColors.selected,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.text.withValues(alpha: 0.2)),
        ),
        child: selected
            ? SizedBox(
                width: 20,
                height: 14,
                child: SvgPicture.asset(AppAssets.termsCheckboxCheck),
              )
            : null,
      ),
    );
  }
}
