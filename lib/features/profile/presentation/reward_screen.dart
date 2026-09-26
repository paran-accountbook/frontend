import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../shared/widgets/p1_design_components.dart';

/// 마이_003: Figma #보상함(705:23821) 화면.
class RewardScreen extends StatelessWidget {
  const RewardScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DesignCanvas(
      child: Stack(
        children: [
          const ColoredBox(color: AppColors.background),
          const P1ScreenHeader(title: '보상함'),
          const Positioned(
            left: 24,
            right: 24,
            top: 192,
            child: _RewardSummary(),
          ),
          const Positioned(
            left: 24,
            right: 24,
            top: 269,
            child: _RewardProgressList(),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: AppBottomNavigation(selectedIndex: 2, onSelected: (_) {}),
          ),
        ],
      ),
    ),
  );
}

class _RewardSummary extends StatelessWidget {
  const _RewardSummary();

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: AppColors.main,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.text20),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '획득한 리워드',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '0 / 0',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _RewardProgressList extends StatelessWidget {
  const _RewardProgressList();

  static const _items = [
    ('소비 패턴 분석 해제', '0/7 일 기록 중', AppAssets.rewardPattern, 18.0),
    ('AI 소비 의견 추가 1회', '0/14 일 기록 중', AppAssets.analysisAi, 20.0),
    ('재구매 분석 해제', '0/20 일 기록 중', AppAssets.analysisRepurchase, 20.0),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '진행 중',
        style: TextStyle(color: AppColors.text50, fontSize: 14),
      ),
      const SizedBox(height: 20),
      for (var index = 0; index < _items.length; index++) ...[
        SizedBox(
          height: 40,
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: SvgPicture.asset(
                  _items[index].$3,
                  width: _items[index].$4,
                  height: _items[index].$4,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 17,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _items[index].$1,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    height: 14,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _items[index].$2,
                        style: const TextStyle(
                          color: AppColors.text80,
                          fontSize: 12,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (index < _items.length - 1) ...[
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.text10),
          const SizedBox(height: 20),
        ],
      ],
    ],
  );
}
