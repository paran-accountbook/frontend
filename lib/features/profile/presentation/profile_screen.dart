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
import 'account_settings_screen.dart';
import 'profile_edit_screen.dart';

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
            const ColoredBox(color: AppColors.background),
            const Positioned(
              left: 24,
              top: 128,
              child: Text(
                '마이페이지',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 192,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProfileEditScreen(),
                  ),
                ),
                child: const _ProfileSummary(),
              ),
            ),
            Positioned(
              left: 24,
              top: 294,
              child: Column(
                children: List.generate(
                  _menuItems.length,
                  (index) => _ProfileMenuRow(
                    data: _menuItems[index],
                    onTap: index == 3
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AccountSettingsScreen(),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
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
    return Container(
      width: 354,
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF191A1F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SvgPicture.asset(AppAssets.profileAvatar, width: 34, height: 34),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '소비로그 님',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '프로필 관리',
                  style: TextStyle(color: AppColors.text50, fontSize: 12),
                ),
              ],
            ),
          ),
          const Text(
            '〉',
            style: TextStyle(color: AppColors.text, fontSize: 22),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({required this.data, this.onTap});
  final _ProfileMenuData data;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 354,
        height: 54,
        child: Row(
          children: [
            SvgPicture.asset(data.asset, width: 34, height: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                data.label,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SvgPicture.asset(AppAssets.profileArrow, width: 24, height: 24),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuData {
  const _ProfileMenuData(this.label, this.asset);
  final String label;
  final String asset;
}
