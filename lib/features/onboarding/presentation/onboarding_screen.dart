import 'package:flutter/material.dart';

import '../../../core/network/app_services.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../shared/widgets/p2_widgets.dart';
import '../../auth/presentation/login_screen.dart';

/// 진입_002-01 온보딩 튜토리얼 한 장.
class OnboardingPage {
  const OnboardingPage({
    required this.image,
    required this.imageTop,
    required this.imageHeight,
    required this.title,
    required this.body,
  });

  final String image;

  /// 402×874 디자인 기준 이미지(글로우 포함) 위치·높이.
  final double imageTop;
  final double imageHeight;
  final String title;
  final String body;

  bool get singleLineBody => !body.contains('\n');
}

const onboardingPages = [
  OnboardingPage(
    image: 'assets/images/onboarding/onboarding_1.png',
    imageTop: 151,
    imageHeight: 462,
    title: '영수증 한 장이면 기록 끝',
    body: '가게 이름부터 품목별 금액까지 채워져요',
  ),
  OnboardingPage(
    image: 'assets/images/onboarding/onboarding_2.png',
    imageTop: 207,
    imageHeight: 420,
    title: '저장하고 바로 더치페이해요',
    body: '저장 완료 화면에서 더치페이 하기를 누르거나\n가계부에서 내역을 눌러 언제든 정산해요',
  ),
  OnboardingPage(
    image: 'assets/images/onboarding/onboarding_3.png',
    imageTop: 194,
    imageHeight: 460,
    title: '나눌 사람만 체크하면 끝',
    body: '품목마다 해당되는 사람을 체크하면\n각자 낼 돈이 자동 계산돼요',
  ),
  OnboardingPage(
    image: 'assets/images/onboarding/onboarding_4.png',
    imageTop: 151,
    imageHeight: 462,
    title: '어디에 많이 썼는지 한눈에',
    body: '지난달보다 얼마나 썼는지도 함께 알려줘요',
  ),
  OnboardingPage(
    image: 'assets/images/onboarding/onboarding_5.png',
    imageTop: 151,
    imageHeight: 437,
    title: 'AI가 소비 습관까지 짚어줘요',
    body: '매달 1일 습관 진단과 할인 찾기가 열리고\n꾸준히 기록하면 더 많은 분석을 볼 수 있어요',
  ),
  OnboardingPage(
    image: 'assets/images/onboarding/onboarding_6.png',
    imageTop: 151,
    imageHeight: 441,
    title: '소비를 기록하면 자동으로 출석돼요',
    body: '마이페이지에서 출석 현황을 확인할 수 있어요\n기록 조건을 달성하면 AI 분석 기능도 열려요',
  ),
  OnboardingPage(
    image: 'assets/images/onboarding/onboarding_7.png',
    imageTop: 203,
    imageHeight: 420,
    title: '소비하지 않은 날도 기록할 수 있어요',
    body: "지출이 없는 날에는 '무지출 기록'을 눌러주세요\n출석이 인정되어 연속 기록을 이어갈 수 있어요",
  ),
];

/// 진입_002-01: 스플래시 다음, 기기에 '온보딩 완료' 기록이 없을 때 보여준다.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onFinished, this.preferences});

  final VoidCallback? onFinished;
  final AppPreferences? preferences;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == onboardingPages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await (widget.preferences ?? AppServices.preferences)
        .setOnboardingCompleted();
    if (!mounted) return;
    if (widget.onFinished case final callback?) {
      callback();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: DesignCanvas(
      paintBackground: false,
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Colors.black)),
          Positioned.fill(
            child: PageView.builder(
              key: const Key('onboarding-pages'),
              controller: _controller,
              itemCount: onboardingPages.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) =>
                  _OnboardingPageView(page: onboardingPages[index]),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            top: 99,
            child: GestureDetector(
              key: const Key('onboarding-skip'),
              behavior: HitTestBehavior.opaque,
              onTap: _finish,
              child: const Text(
                '건너뛰기',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 22 / 14,
                ),
              ),
            ),
          ),
          Positioned(
            left: 147,
            top: 722,
            width: 108,
            height: 6,
            child: Row(
              children: [
                for (var i = 0; i < onboardingPages.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _page ? 24 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? P2Colors.lavender : AppColors.outline,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 121,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 25, 24, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, .795],
                  colors: [Color(0x00121215), Color(0xE6121215)],
                ),
              ),
              child: P2Button(
                key: const Key('onboarding-next'),
                label: _isLast ? '시작하기' : '다음',
                onPressed: _next,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final titleTop = page.singleLineBody ? 633.0 : 612.0;
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: page.imageTop,
          width: 402,
          height: page.imageHeight,
          child: Image.asset(page.image, fit: BoxFit.fill),
        ),
        Positioned(
          left: 24,
          right: 24,
          top: titleTop,
          child: Column(
            children: [
              SizedBox(
                height: 24,
                child: Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                page.body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text80,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 21 / 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
