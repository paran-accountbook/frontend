import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../home/presentation/home_screen.dart';
import '../domain/signup_draft.dart';
import '../data/auth_service.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({
    super.key,
    this.signupDraft,
    this.onAgreed,
    this.authService,
  });

  final SignupDraft? signupDraft;
  final VoidCallback? onAgreed;
  final AuthService? authService;

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  static const _labels = [
    '서비스 이용약관 (필수)',
    '개인정보 수집·이용 동의 (필수)',
    '마케팅 수신 동의 (선택)',
  ];

  final _selected = List.filled(_labels.length, false);
  bool _showRequiredError = false;
  bool _isLoading = false;
  String? _apiError;

  bool get _allSelected => _selected.every((selected) => selected);
  bool get _requiredSelected => _selected[0] && _selected[1];

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
          marketingAgreed: _selected[2],
        );
      } on ApiException catch (error) {
        if (mounted) setState(() => _apiError = error.message);
        return;
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      if (!mounted) return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
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
                top: 470,
                child: Column(
                  children: List.generate(_labels.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _labels.length - 1 ? 0 : 20,
                      ),
                      child: _TermsRow(
                        label: _labels[index],
                        selected: _selected[index],
                        onPressed: () => _toggleItem(index),
                        onViewPressed: () {},
                      ),
                    );
                  }),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                top: 672,
                child: Column(
                  children: [
                    _TermsCheckbox(
                      selected: _allSelected,
                      onPressed: _toggleAll,
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _toggleAll,
                      child: Text(
                        '전체 동의하기',
                        style: TextStyle(color: AppColors.text80, fontSize: 12),
                      ),
                    ),
                    if (_showRequiredError) ...[
                      const SizedBox(height: 10),
                      const Text(
                        '필수 약관에 동의해 주세요',
                        style: TextStyle(
                          color: Color(0xFFFF6B7A),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (_apiError case final message?) ...[
                      const SizedBox(height: 10),
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
              AuthBottomAction(
                label: _isLoading ? '가입 중...' : '동의합니다',
                onPressed: _isLoading ? () {} : _agree,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({
    required this.label,
    required this.selected,
    required this.onPressed,
    required this.onViewPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final VoidCallback onViewPressed;

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
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.text80,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
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
        decoration: BoxDecoration(
          color: selected ? AppColors.main : AppColors.selected,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.text.withValues(alpha: 0.2)),
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}
