import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/design_canvas.dart';

class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        child: Stack(
          children: [
            const ColoredBox(color: AppColors.background),
            Positioned(
              left: 24,
              top: 50,
              width: 34,
              height: 34,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: SvgPicture.asset(AppAssets.arrowBackLight),
              ),
            ),
            const Positioned(
              left: 24,
              top: 128,
              child: Text(
                '프로필 수정',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Positioned(
              left: 24,
              top: 190,
              width: 354,
              child: Column(
                children: [
                  _ProfileAsterisks(),
                  SizedBox(height: 20),
                  _ProfileRow(label: '이름', value: '소비로그', arrow: true),
                  SizedBox(height: 16),
                  _ProfileRow(
                    label: '가입 이메일',
                    value: 'welcome@sobilog.com',
                    arrow: false,
                  ),
                  SizedBox(height: 16),
                  _ProfileRow(
                    label: '가입일',
                    value: '2026년 9월 1일 오후 3:20',
                    arrow: false,
                  ),
                  SizedBox(height: 20),
                  _ProfileAsterisks(),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '더치페이 계좌',
                      style: TextStyle(color: AppColors.text50, fontSize: 14),
                    ),
                  ),
                  SizedBox(height: 20),
                  _AccountCard(),
                ],
              ),
            ),
            const Positioned(
              left: 0,
              bottom: 0,
              child: AppBottomNavigation(selectedIndex: 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.value,
    required this.arrow,
  });
  final String label;
  final String value;
  final bool arrow;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 28,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.text50, fontSize: 14),
        ),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (arrow)
              const Text(
                '  〉',
                style: TextStyle(color: AppColors.text, fontSize: 20),
              ),
          ],
        ),
      ],
    ),
  );
}

class _ProfileAsterisks extends StatelessWidget {
  const _ProfileAsterisks();

  @override
  Widget build(BuildContext context) => Text(
    List.filled(18, '*').join('   '),
    maxLines: 1,
    style: const TextStyle(color: AppColors.text20, fontSize: 10),
  );
}

class _AccountCard extends StatelessWidget {
  const _AccountCard();
  @override
  Widget build(BuildContext context) => Container(
    width: 354,
    height: 81,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.main,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '소비은행',
                style: TextStyle(color: AppColors.text, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '000-0000-0000',
                style: TextStyle(color: AppColors.text80, fontSize: 12),
              ),
            ],
          ),
        ),
        SvgPicture.asset(AppAssets.editLight, width: 24, height: 24),
      ],
    ),
  );
}
