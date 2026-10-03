import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../auth/data/auth_service.dart';

class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({super.key, this.authService});
  final AuthService? authService;
  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _isLoading = false;
  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final categories = [
      RegExp('[A-Za-z]').hasMatch(_next.text),
      RegExp('[0-9]').hasMatch(_next.text),
      RegExp(r'[^A-Za-z0-9]').hasMatch(_next.text),
    ].where((e) => e).length;
    if (_current.text.isEmpty ||
        _next.text.length < 8 ||
        categories < 2 ||
        _next.text == _current.text ||
        _next.text != _confirm.text) {
      setState(() => _error = '비밀번호 입력 내용을 확인해 주세요');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await (widget.authService ?? AppServices.auth).changePassword(
        currentPassword: _current.text,
        newPassword: _next.text,
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
              '비밀번호 변경',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 27,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Positioned(
            left: 25,
            top: 292,
            child: Column(
              children: [
                AuthTextField(
                  controller: _current,
                  hintText: '현재 비밀번호',
                  obscureText: true,
                  onChanged: (_) => setState(() => _error = null),
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  controller: _next,
                  hintText: '새 비밀번호',
                  obscureText: true,
                  onChanged: (_) => setState(() => _error = null),
                ),
                const SizedBox(height: 18),
                const SizedBox(
                  width: 352,
                  child: Text(
                    '•  8자 이상\n•  영문 / 숫자 / 특수문자 중 2종 이상 조합\n•  기존 비밀번호와 다른 값',
                    style: TextStyle(
                      color: AppColors.text80,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  controller: _confirm,
                  hintText: '새 비밀번호 확인',
                  obscureText: true,
                  onChanged: (_) => setState(() => _error = null),
                ),
                if (_error case final message?)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Color(0xFFFF6B7A),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          AuthBottomAction(
            label: _isLoading ? '변경 중...' : '비밀번호 변경',
            onPressed: _isLoading ? null : _submit,
          ),
        ],
      ),
    ),
  );
}
