import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class FormSaveButton extends StatelessWidget {
  const FormSaveButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.keyboardVisible,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool keyboardVisible;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 56,
    child: keyboardVisible
        ? null
        : FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.main,
              disabledBackgroundColor: AppColors.selected,
              foregroundColor: Colors.white,
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
