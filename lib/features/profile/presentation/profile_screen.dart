import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../analysis/presentation/analysis_overview_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../ledger/presentation/ledger_screen.dart';
import '../../register/presentation/register_type_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.onNavigationSelected});

  final ValueChanged<int>? onNavigationSelected;

  static const _menuItems = [
    _ProfileMenuData('출석 현황', AppAssets.profileAttendance),
    _ProfileMenuData('리워드 관리', AppAssets.profileRewards),
    _ProfileMenuData('알림 설정', AppAssets.profileNotifications),
    _ProfileMenuData('계정 설정', AppAssets.profileAccount),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        child: Stack(
          children: [
            const Positioned(
              left: 46,
              top: 214,
              child: Text(
                '마이 페이지',
                style: TextStyle(
                  color: AppColors.text,
                  fontFamily: 'BujangnimNunchi',
                  fontSize: 75,
                  height: 1,
                ),
              ),
            ),
            const Positioned(left: 0, top: 347, child: _ProfileSummary()),
            Positioned(
              left: 0,
              top: 550,
              child: Column(
                children: [
                  for (var index = 0; index < _menuItems.length; index++) ...[
                    _ProfileMenuRow(data: _menuItems[index]),
                    if (index != _menuItems.length - 1)
                      const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 1459,
              child: AppBottomNavigation(
                selectedIndex: 4,
                onSelected: (index) => _handleNavigation(context, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    if (onNavigationSelected case final callback?) {
      callback(index);
      return;
    }

    final Widget? destination = switch (index) {
      0 => const HomeScreen(),
      1 => const LedgerScreen(),
      2 => const RegisterTypeScreen(),
      3 => const AnalysisOverviewScreen(),
      _ => null,
    };
    if (destination == null) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.secondary,
      child: SizedBox(
        width: 749,
        height: 156,
        child: Stack(
          children: [
            Positioned(
              left: 41,
              top: 43,
              width: 70,
              height: 70,
              child: _ProfileAvatar(),
            ),
            Positioned(
              left: 135,
              top: 38,
              child: Text(
                '1111 님',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),
            Positioned(
              left: 135,
              top: 88,
              child: Text(
                '프로필 관리',
                style: TextStyle(
                  color: Color(0xCCE2E2F9),
                  fontSize: 23,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(AppAssets.profileAvatar);
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({required this.data});

  final _ProfileMenuData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 749,
      height: 87,
      child: Stack(
        children: [
          Positioned(
            left: 46,
            top: 8,
            width: 70,
            height: 70,
            child: SvgPicture.asset(data.asset),
          ),
          Positioned(
            left: 135,
            top: 28,
            child: Text(
              data.label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 30,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
          Positioned(
            left: 655.5,
            top: 12,
            width: 64,
            height: 64,
            child: SvgPicture.asset(AppAssets.profileArrow),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuData {
  const _ProfileMenuData(this.label, this.asset);

  final String label;
  final String asset;
}
