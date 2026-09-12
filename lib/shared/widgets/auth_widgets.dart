import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import 'design_canvas.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({required this.child, super.key, this.showBackButton = true});

  final Widget child;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: DesignCanvas(
        width: 402,
        height: 874,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.background),
            Positioned(
              left: -110,
              top: 0,
              width: 623,
              height: 874,
              child: Image.asset(AppAssets.authBackground, fit: BoxFit.cover),
            ),
            child,
            if (showBackButton)
              Positioned(
                left: 24,
                top: 50,
                width: 34,
                height: 34,
                child: Semantics(
                  button: true,
                  label: '뒤로가기',
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: SvgPicture.asset(AppAssets.arrowBackLight),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.controller,
    required this.hintText,
    super.key,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 352,
      height: 56,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        onChanged: onChanged,
        textInputAction: textInputAction,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          filled: true,
          fillColor: AppColors.selected.withValues(alpha: 0.9),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: AppColors.text.withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.main),
          ),
        ),
      ),
    );
  }
}

class AuthBottomAction extends StatelessWidget {
  const AuthBottomAction({
    required this.label,
    required this.onPressed,
    super.key,
    this.bottom = 40,
  });

  final String label;
  final VoidCallback? onPressed;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      right: 24,
      bottom: bottom,
      height: 106,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00121215), Color(0xE6121215)],
            stops: [0, 0.8],
          ),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 354,
            height: 56,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.main,
                disabledBackgroundColor: AppColors.selected,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: AppColors.text.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
