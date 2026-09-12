import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../home/presentation/home_screen.dart';
import '../../ledger/presentation/ledger_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../register/presentation/register_type_screen.dart';

class AnalysisOverviewScreen extends StatefulWidget {
  const AnalysisOverviewScreen({super.key, this.onNavigationSelected});
  final ValueChanged<int>? onNavigationSelected;
  @override
  State<AnalysisOverviewScreen> createState() => _AnalysisOverviewScreenState();
}

class _AnalysisOverviewScreenState extends State<AnalysisOverviewScreen> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        child: Stack(
          children: [
            const ColoredBox(color: AppColors.background),
            const Positioned(
              left: 24,
              top: 87,
              child: Text(
                '소비분석',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 132,
              child: Row(
                children: List.generate(
                  4,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _TabChip(
                      label: const ['요약', '패턴', '반복지출', 'AI'][index],
                      selected: _tab == index,
                      onTap: () => setState(() => _tab = index),
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 24,
              top: 194,
              width: 354,
              child: _MonthSelector(),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: 225,
              bottom: 84,
              child: _content(),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: AppBottomNavigation(
                selectedIndex: 3,
                onSelected: (index) => _navigate(context, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() => switch (_tab) {
    0 => const _Report(),
    1 => const _LockedList(items: [('소비 패턴 분석', '연속 7일 기록하면 열려요 0/7 일')]),
    2 => const _LockedList(
      items: [
        ('재구매 분석', '연속 20일 기록하면 열려요 0/20 일'),
        ('정기 지출 감지', '충분한 내역이 쌓이면 알려드려요'),
      ],
    ),
    _ => const _LockedList(
      items: [
        ('AI 소비 의견', '연속 14일 기록하면 열려요 0/14 일'),
        ('절약 대안 힌트', '소비 패턴을 바탕으로 제안해 드려요'),
      ],
    ),
  };

  void _navigate(BuildContext context, int index) {
    if (widget.onNavigationSelected case final callback?) {
      callback(index);
      return;
    }
    final Widget? page = switch (index) {
      0 => const HomeScreen(),
      1 => const LedgerScreen(),
      2 => const RegisterTypeScreen(),
      4 => const ProfileScreen(),
      _ => null,
    };
    if (page == null) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFA8A3FF) : AppColors.selected,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline, width: .5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xFF1B1B1B) : AppColors.text50,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      SvgPicture.asset(AppAssets.monthArrowActive, width: 10, height: 12),
      const Row(
        children: [
          Text(
            '2026',
            style: TextStyle(
              color: AppColors.text,
              fontFamily: 'Amarante',
              fontSize: 20,
            ),
          ),
          SizedBox(width: 4),
          Text('년', style: TextStyle(color: AppColors.text, fontSize: 12)),
          SizedBox(width: 18),
          Text(
            '8',
            style: TextStyle(
              color: AppColors.text,
              fontFamily: 'Amarante',
              fontSize: 20,
            ),
          ),
          SizedBox(width: 4),
          Text('월', style: TextStyle(color: AppColors.text, fontSize: 12)),
        ],
      ),
      SvgPicture.asset(AppAssets.monthArrowDim, width: 10, height: 12),
    ],
  );
}

class _Report extends StatelessWidget {
  const _Report();
  static const categories = [
    ('식비', '53%', '4,500', AppAssets.categoryFood),
    ('쇼핑', '30%', '4,500', AppAssets.categoryShopping),
    ('카페', '8%', '4,500', AppAssets.categoryCulture),
    ('의료', '4%', '4,500', AppAssets.categoryMedical),
    ('교통', '3%', '4,500', AppAssets.categoryTransport),
    ('문화', '2%', '4,500', AppAssets.categoryCulture),
  ];
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Asterisks(),
        const SizedBox(height: 14),
        const Text(
          '총 지출',
          style: TextStyle(color: AppColors.text50, fontSize: 12),
        ),
        const SizedBox(height: 5),
        const _PriceText(value: '150,000', size: 26),
        const SizedBox(height: 4),
        const Row(
          children: [
            Text(
              '▲ 2,500',
              style: TextStyle(
                color: Color(0xFFCF376A),
                fontSize: 16,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '전월 대비 12%',
              style: TextStyle(color: AppColors.text50, fontSize: 9),
            ),
          ],
        ),
        const SizedBox(height: 15),
        const _Metric(label: '일 평균 지출액', value: '40,000'),
        const _Metric(label: '총 수입', value: '150,000'),
        const _Metric(label: '잔액', value: '+150,000', accent: true),
        const SizedBox(height: 12),
        const _Asterisks(),
        const SizedBox(height: 14),
        const Text(
          '카테고리별 비중',
          style: TextStyle(color: AppColors.text50, fontSize: 12),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: const Row(
            children: [
              Expanded(
                flex: 53,
                child: ColoredBox(
                  color: Color(0xFFFF9345),
                  child: SizedBox(height: 12),
                ),
              ),
              Expanded(
                flex: 30,
                child: ColoredBox(
                  color: Color(0xFFD92B80),
                  child: SizedBox(height: 12),
                ),
              ),
              Expanded(
                flex: 17,
                child: ColoredBox(
                  color: AppColors.main,
                  child: SizedBox(height: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...categories.map(
          (item) => SizedBox(
            height: 45,
            child: Row(
              children: [
            SvgPicture.asset(item.$4, width: 26, height: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        item.$2,
                        style: const TextStyle(
                          color: AppColors.text50,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                _PriceText(value: item.$3, size: 16),
              ],
            ),
          ),
        ),
        const _Asterisks(),
        const SizedBox(height: 14),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '8월 지출 목표',
              style: TextStyle(color: AppColors.text50, fontSize: 12),
            ),
            Text(
              '00원 중 00원 사용',
              style: TextStyle(color: AppColors.text, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Text(
              '20%',
              style: TextStyle(
                color: AppColors.text,
                fontFamily: 'Amarante',
                fontSize: 18,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: LinearProgressIndicator(
                value: .2,
                minHeight: 10,
                color: AppColors.main,
                backgroundColor: AppColors.selected,
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.accent = false,
  });
  final String label;
  final String value;
  final bool accent;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 34,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.text50, fontSize: 12),
        ),
        _PriceText(value: value, size: 16, accent: accent),
      ],
    ),
  );
}

class _PriceText extends StatelessWidget {
  const _PriceText({
    required this.value,
    required this.size,
    this.accent = false,
  });
  final String value;
  final double size;
  final bool accent;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        style: TextStyle(
          color: accent ? const Color(0xFFA8A3FF) : AppColors.text,
          fontFamily: 'Amarante',
          fontSize: size,
        ),
      ),
      const SizedBox(width: 4),
      SvgPicture.asset(AppAssets.wonLight, width: 12, height: 13),
    ],
  );
}

class _Asterisks extends StatelessWidget {
  const _Asterisks();
  @override
  Widget build(BuildContext context) => Text(
    List.filled(18, '*').join('   '),
    maxLines: 1,
    style: const TextStyle(color: AppColors.text20, fontSize: 10),
  );
}

class _LockedList extends StatelessWidget {
  const _LockedList({required this.items});
  final List<(String, String)> items;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const _Asterisks(),
      const SizedBox(height: 12),
      ...items.map(
        (item) => Container(
          height: 80,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x0DE2E2F9))),
          ),
          child: Row(
            children: [
              SvgPicture.asset(AppAssets.analysisLocked, width: 28, height: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.$2,
                      style: const TextStyle(
                        color: AppColors.text50,
                        fontSize: 12,
                      ),
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
        ),
      ),
    ],
  );
}
