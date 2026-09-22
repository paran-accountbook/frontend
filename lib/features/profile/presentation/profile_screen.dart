import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/app_chevron.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../analysis/presentation/analysis_overview_screen.dart';
import '../../finance/data/finance_service.dart';
import '../../home/presentation/home_screen.dart';
import '../../ledger/presentation/ledger_screen.dart';
import '../../register/presentation/register_type_screen.dart';
import 'account_settings_screen.dart';
import 'attendance_screen.dart';
import 'notification_settings_screen.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.onNavigationSelected,
    this.financeService,
    this.onOpenCustomerSupport,
  });
  final ValueChanged<int>? onNavigationSelected;
  final FinanceService? financeService;
  final Future<void> Function(Uri uri)? onOpenCustomerSupport;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  late bool _isLoading;

  static const _menuItems = [
    _ProfileMenuData('출석 현황', AppAssets.profileAttendance),
    _ProfileMenuData('리워드 관리', AppAssets.profileRewards),
    _ProfileMenuData('알림 설정', AppAssets.profileNotifications),
    _ProfileMenuData('계정 설정', AppAssets.profileAccount),
    _ProfileMenuData(
      '고객 센터',
      AppAssets.profileSupport,
      iconWidth: 22,
      iconHeight: 20,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _isLoading = widget.financeService != null;
    _load();
  }

  Future<void> _load() async {
    final service = widget.financeService;
    if (service == null) return;
    try {
      final profile = await service.profile();
      if (mounted) setState(() => _profile = profile);
    } catch (_) {
      // Preserve the last rendered profile while offline.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                    builder: (_) => ProfileEditScreen(
                      initialData: _profile,
                      financeService: widget.financeService,
                    ),
                  ),
                ),
                child: _isLoading
                    ? const _ProfileSummarySkeleton()
                    : _ProfileSummary(name: _profile?['nickname'] as String?),
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
                    onTap: switch (index) {
                      0 => () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AttendanceScreen(
                            financeService: widget.financeService,
                          ),
                        ),
                      ),
                      2 => () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => NotificationSettingsScreen(
                            financeService: widget.financeService,
                          ),
                        ),
                      ),
                      3 => () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AccountSettingsScreen(
                            provider:
                                _profile?['provider'] as String? ?? 'email',
                          ),
                        ),
                      ),
                      4 => _openCustomerSupport,
                      _ => null,
                    },
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

  Future<void> _openCustomerSupport() async {
    final uri = Uri.parse('http://pf.kakao.com/_xbVZaX');
    if (widget.onOpenCustomerSupport case final callback?) {
      await callback(uri);
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('고객센터를 열 수 없습니다.')));
    }
  }

  void _handleNavigation(BuildContext context, int index) {
    if (widget.onNavigationSelected case final callback?) {
      callback(index);
      return;
    }
    final Widget? destination = switch (index) {
      0 => HomeScreen(financeService: widget.financeService),
      1 => LedgerScreen(financeService: widget.financeService),
      2 => RegisterTypeScreen(financeService: widget.financeService),
      3 => AnalysisOverviewScreen(financeService: widget.financeService),
      _ => null,
    };
    if (destination == null) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
  }
}

class _ProfileSummarySkeleton extends StatelessWidget {
  const _ProfileSummarySkeleton();

  @override
  Widget build(BuildContext context) => Container(
    width: 354,
    height: 80,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.secondary,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const AppSkeleton(
      child: Row(
        children: [
          AppSkeletonBox(width: 34, height: 34, shape: BoxShape.circle),
          SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeletonBox(width: 92, height: 14),
              SizedBox(height: 8),
              AppSkeletonBox(width: 58, height: 12),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({this.name});
  final String? name;
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
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${name?.isNotEmpty == true ? name : '소비로그'} 님',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '프로필 관리',
                  style: TextStyle(color: AppColors.text50, fontSize: 12),
                ),
              ],
            ),
          ),
          const AppChevron(),
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
            SizedBox(
              width: 34,
              height: 34,
              child: Center(
                child: SvgPicture.asset(
                  data.asset,
                  width: data.iconWidth,
                  height: data.iconHeight,
                ),
              ),
            ),
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
            const AppChevron(),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuData {
  const _ProfileMenuData(
    this.label,
    this.asset, {
    this.iconWidth = 34,
    this.iconHeight = 34,
  });
  final String label;
  final String asset;
  final double iconWidth;
  final double iconHeight;
}
