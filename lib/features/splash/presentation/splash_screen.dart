import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.autoAdvance = true});

  final bool autoAdvance;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.autoAdvance) {
      _timer = Timer(const Duration(milliseconds: 2500), _showOnboarding);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showOnboarding() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        child: ColoredBox(
          color: AppColors.background,
          child: Stack(
            children: [
              Positioned(
                left: 209,
                top: 781,
                width: 331,
                height: 67,
                child: Stack(
                  children: [
                    Positioned(
                      left: 69.54,
                      top: 2.56,
                      width: 261.46,
                      height: 63.49,
                      child: SvgPicture.asset(
                        AppAssets.logoWordmark,
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned(
                      width: 66.73,
                      height: 67,
                      child: SvgPicture.asset(
                        AppAssets.logoSymbol,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
