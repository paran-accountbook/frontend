import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class GradientActionButton extends StatelessWidget {
  const GradientActionButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.width = 633,
  });

  final String label;
  final VoidCallback onPressed;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: width,
          height: 102,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.text30),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.main.withValues(alpha: 0.4), AppColors.main],
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.resource,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
