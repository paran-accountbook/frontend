import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../auth/presentation/login_screen.dart';
import '../../home/presentation/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.autoAdvance = true,
    this.restoreSession = true,
  });

  final bool autoAdvance;
  final bool restoreSession;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.autoAdvance) {
      _timer = Timer(const Duration(milliseconds: 2500), _advance);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _advance() async {
    if (!mounted) return;
    final token = widget.restoreSession
        ? await AppServices.client.sessionStore.readAccessToken()
        : null;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            token == null ? const LoginScreen() : const HomeScreen(),
      ),
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
                left: -72,
                top: 161,
                width: 169,
                height: 158,
                child: Image.asset(AppAssets.splashBlobTopLeft),
              ),
              Positioned(
                left: 273,
                top: 119,
                width: 174,
                height: 167,
                child: Image.asset(AppAssets.splashBlobTopRight),
              ),
              Positioned(
                left: -120,
                top: 560,
                width: 249,
                height: 253,
                child: Image.asset(AppAssets.splashStarBottomLeft),
              ),
              Positioned(
                left: 308,
                top: 595,
                width: 160,
                height: 155,
                child: Image.asset(AppAssets.splashStarBottomRight),
              ),
              Positioned(
                left: 184,
                top: 477,
                width: 128,
                height: 125,
                child: Transform.rotate(
                  angle: 0.299,
                  child: Image.asset(AppAssets.splashStarCenter),
                ),
              ),
              Positioned(
                left: 162,
                top: 306,
                width: 78,
                height: 100,
                child: SvgPicture.asset(AppAssets.splashLogoSymbol),
              ),
              Positioned(
                left: 162,
                top: 418,
                width: 78,
                height: 19,
                child: SvgPicture.asset(AppAssets.splashLogoWordmark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
