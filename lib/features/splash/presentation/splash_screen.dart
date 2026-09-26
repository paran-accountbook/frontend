import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/app_services.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/presentation/terms_screen.dart';
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
    if (token == null) {
      _replace(const LoginScreen());
      return;
    }
    try {
      final status = await AppServices.auth.termsStatus();
      if (!mounted) return;
      if (status['initial_agreement_required'] == true) {
        _replace(TermsScreen(authService: AppServices.auth, kakaoSignup: true));
      } else if (status['reconsent_required'] == true) {
        _replace(TermsScreen(authService: AppServices.auth, reconsent: true));
      } else {
        _replace(HomeScreen(financeService: AppServices.finance));
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401) {
        await AppServices.auth.logout();
        if (mounted) _replace(const LoginScreen());
      } else {
        _replace(HomeScreen(financeService: AppServices.finance));
      }
    }
  }

  void _replace(Widget screen) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => screen));
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
