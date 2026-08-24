import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import 'terms_screen.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key, this.onVerified});

  final VoidCallback? onVerified;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '123456');
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _complete() {
    if (widget.onVerified case final callback?) {
      callback();
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const TermsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final digits = _controller.text.padRight(6).substring(0, 6).split('');
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: DesignCanvas(
        child: ColoredBox(
          color: AppColors.background,
          child: Stack(
            children: [
              Positioned(
                left: -200,
                top: -100,
                width: 100,
                height: 50,
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    maxLength: 6,
                    keyboardType: TextInputType.text,
                    keyboardAppearance: Brightness.light,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration.collapsed(hintText: ''),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _complete(),
                  ),
                ),
              ),
              Positioned(
                left: 7,
                top: 559,
                width: 735,
                height: 494,
                child: SvgPicture.asset(
                  AppAssets.verificationReceipt,
                  fit: BoxFit.fill,
                ),
              ),
              Positioned(
                left: 86,
                top: 642,
                width: 577,
                height: 13,
                child: SvgPicture.asset(AppAssets.asteriskDividerDark),
              ),
              const Positioned(
                top: 727,
                width: 749,
                child: Text(
                  '인증번호를 입력하세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF1B1B1B),
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Positioned(
                left: 131,
                top: 811,
                child: GestureDetector(
                  onTap: _complete,
                  child: Row(
                    children: List.generate(6, (index) {
                      return Padding(
                        padding: EdgeInsets.only(right: index == 5 ? 0 : 16),
                        child: Container(
                          width: 68,
                          height: 68,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B1B1B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            digits[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Amarante',
                              fontSize: 40,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              Positioned(
                left: 86,
                top: 949,
                width: 577,
                height: 13,
                child: SvgPicture.asset(AppAssets.asteriskDividerDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
