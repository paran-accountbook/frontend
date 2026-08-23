import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../shared/widgets/gradient_action_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        child: ColoredBox(
          color: AppColors.background,
          child: Stack(
            children: [
              Positioned(
                left: 331,
                top: 159,
                child: GestureDetector(
                  onTap: onFinished,
                  child: const Text(
                    '건너뛰기',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 58,
                top: 293,
                width: 633,
                height: 679,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(21),
                  ),
                ),
              ),
              const Positioned(
                left: 58,
                top: 1137,
                width: 633,
                child: Text(
                  '소비 습관',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                left: 58,
                top: 1211,
                width: 633,
                child: Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                  'Vivamus id auctor dolor. Praesent sed quam est. Ut at feugiat '
                  'enim, vel vulputate diam. Sed mattis semper sodales. Fusce '
                  'consequat fringilla felis',
                  style: TextStyle(
                    color: AppColors.text80,
                    fontSize: 30,
                    height: 1.3,
                  ),
                ),
              ),
              Positioned(
                left: 58,
                top: 1466,
                child: GradientActionButton(
                  label: '다음',
                  onPressed: onFinished ?? () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
