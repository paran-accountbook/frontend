import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../shared/widgets/p2_widgets.dart';
import '../../finance/data/finance_service.dart';
import 'register_direct_screen.dart';

/// 등록_005-03: 병원·약국 영수증(400 E508) 직접 입력 안내 (전체 화면).
class DirectInputGuideScreen extends StatelessWidget {
  const DirectInputGuideScreen({super.key, this.financeService});

  final FinanceService? financeService;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: DesignCanvas(
      paintBackground: false,
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Colors.black)),
          Positioned(
            left: 24,
            right: 24,
            top: 367.5,
            child: Column(
              children: [
                SvgPicture.asset(
                  AppAssets.ledgerEmptyFilter,
                  width: 36,
                  height: 36,
                ),
                const SizedBox(height: 20),
                const Text(
                  '직접 입력이 필요한 영수증이에요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 22 / 14,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '병원·약국 영수증은 개인정보 보호를 위해 자동 입력을 지원하지 않아요.\n'
                  '지출 내역을 직접 입력해 주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.text80,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 21 / 12,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 197,
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
              child: Column(
                children: [
                  P2Button(
                    key: const Key('direct-guide-cancel'),
                    label: '취소',
                    tone: P2ButtonTone.grey,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 20),
                  P2Button(
                    key: const Key('direct-guide-input'),
                    label: '직접 입력하기',
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => RegisterDirectScreen(
                          financeService: financeService,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
