import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../analysis/presentation/analysis_overview_screen.dart';
import '../../finance/data/finance_service.dart';
import '../../ledger/presentation/ledger_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../register/presentation/register_type_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onNavigationSelected, this.financeService});

  final ValueChanged<int>? onNavigationSelected;
  final FinanceService? financeService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = widget.financeService;
    if (service == null) return;
    try {
      final data = await service.home();
      if (mounted) setState(() => _data = data);
    } catch (_) {
      // The static preview remains visible; authenticated retry is available on refresh/re-entry.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        child: Stack(
          children: [
            const ColoredBox(color: AppColors.background),
            Positioned(
              left: -110,
              top: 0,
              width: 623,
              height: 874,
              child: Image.asset(AppAssets.homeBackground, fit: BoxFit.cover),
            ),
            Positioned(
              left: 24,
              top: 66,
              width: 132,
              height: 25,
              child: Row(
                children: [
                  SvgPicture.asset(AppAssets.splashLogoSymbol, width: 20),
                  const SizedBox(width: 4),
                  Expanded(
                    child: SvgPicture.asset(AppAssets.splashLogoWordmark),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              top: 108,
              width: 354,
              height: 318,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AnalysisOverviewScreen(
                      financeService: widget.financeService,
                    ),
                  ),
                ),
                child: _SummaryReceipt(
                  summary: _data?['summary'] as Map<String, dynamic>?,
                ),
              ),
            ),
            const Positioned(
              left: 24,
              top: 452,
              width: 354,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('최근 등록 내역', style: _smallText),
                  Text('전체 보기  〉', style: _smallText),
                ],
              ),
            ),
            Positioned(
              left: 24,
              top: 489,
              child: _RecentList(
                data: _data?['recent'] as Map<String, dynamic>?,
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: AppBottomNavigation(
                selectedIndex: 0,
                onSelected: (index) => _navigate(context, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    if (widget.onNavigationSelected case final callback?) {
      callback(index);
      return;
    }
    final Widget? page = switch (index) {
      1 => LedgerScreen(financeService: widget.financeService),
      2 => RegisterTypeScreen(financeService: widget.financeService),
      3 => AnalysisOverviewScreen(financeService: widget.financeService),
      4 => ProfileScreen(financeService: widget.financeService),
      _ => null,
    };
    if (page == null) return;
    final route = MaterialPageRoute<void>(builder: (_) => page);
    if (index == 2) {
      Navigator.of(context).push(route);
    } else {
      Navigator.of(context).pushReplacement(route);
    }
  }
}

const _smallText = TextStyle(
  color: AppColors.text,
  fontSize: 14,
  fontWeight: FontWeight.w500,
);

class _SummaryReceipt extends StatelessWidget {
  const _SummaryReceipt({this.summary});
  final Map<String, dynamic>? summary;

  @override
  Widget build(BuildContext context) {
    final total = summary?['total_expense_amount'] as int? ?? 150000;
    final changeAmount = summary?['change_amount'] as int? ?? 2500;
    final changeRate = summary?['change_rate'] as num? ?? 12;
    final goal = summary?['goal'] as Map<String, dynamic>?;
    final month = summary?['month'] as int? ?? 8;
    final income = summary?['total_income_amount'] as int? ?? 30000;
    final balance = summary?['balance'] as int? ?? 10000;
    final changeColor = changeAmount > 0
        ? const Color(0xFFCF376A)
        : const Color(0xFF4777D9);
    final sign = changeAmount > 0 ? '+' : '';
    return Stack(
      children: [
        Positioned.fill(
          child: SvgPicture.asset(
            AppAssets.homeReceiptCompact,
            fit: BoxFit.fill,
          ),
        ),
        Positioned(
          top: 27,
          width: 354,
          child: Text(
            '소비요약',
            textAlign: TextAlign.center,
            style: _receiptLabel,
          ),
        ),
        Positioned(
          top: 66,
          width: 354,
          child: Text(
            '이번 달 총 지출액',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1B1B1B),
              fontFamily: 'BujangnimNunchi',
              fontSize: 24,
            ),
          ),
        ),
        ...[54.0, 154.0, 254.0].map(
          (top) => Positioned(
            left: 17,
            top: top,
            width: 320,
            height: 7,
            child: SvgPicture.asset(AppAssets.receiptAsteriskDivider),
          ),
        ),
        Positioned(
          top: 105,
          width: 354,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('총 ', style: _receiptLabel),
              Text(_formatAmount(total), style: _receiptAmountLarge),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: _WonIcon(dark: true, width: 19, height: 20),
              ),
            ],
          ),
        ),
        Positioned(
          left: 17,
          right: 17,
          top: 188,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '전월 동일 시점 대비 $sign${changeRate.toStringAsFixed(changeRate is int ? 0 : 1)}%',
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: _receiptBody,
                ),
              ),
              _ReceiptPrice(
                amount: '$sign${_formatAmount(changeAmount)}',
                color: changeColor,
              ),
            ],
          ),
        ),
        if (summary == null || goal != null)
          Positioned(
            left: 17,
            right: 17,
            top: 229,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$month월 목표', style: _receiptBody),
                _ReceiptPrice(
                  amount: _formatAmount(goal?['amount'] as int? ?? 40000),
                ),
              ],
            ),
          ),
        if (summary == null || summary?['total_income_amount'] != null)
          Positioned(
            left: 17,
            right: 17,
            top: 281,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('수입 ${_formatAmount(income)}원', style: _receiptLabel),
                Text('잔액 ${_formatAmount(balance)}원', style: _receiptLabel),
              ],
            ),
          ),
      ],
    );
  }
}

const _receiptLabel = TextStyle(
  color: Color(0xFF1B1B1B),
  fontSize: 14,
  fontWeight: FontWeight.w500,
);
const _receiptBody = TextStyle(color: Color(0xFF1B1B1B), fontSize: 12);
const _receiptAmountLarge = TextStyle(
  color: Color(0xFF1B1B1B),
  fontFamily: 'Amarante',
  fontSize: 30,
  height: 1,
);

class _RecentList extends StatelessWidget {
  const _RecentList({this.data});
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    final entries = (data?['entries'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    if (data != null && (entries == null || entries.isEmpty)) {
      return Container(
        width: 354,
        height: 72,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x0DE2E2F9))),
        ),
        child: const Text('첫 소비를 등록해보세요', style: _smallText),
      );
    }
    final visible =
        entries ?? List.generate(3, (_) => const <String, dynamic>{});
    return Column(
      children: visible
          .take(3)
          .map((entry) => _RecentRow(entry: entry))
          .toList(),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.entry});
  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final rawDate = entry['date'] as String?;
    final date = rawDate == null ? null : DateTime.tryParse(rawDate);
    final isIncome = entry['type'] == 'income';
    final amount = entry['amount'] as int? ?? 150000;
    return Container(
      width: 354,
      height: 72,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x0DE2E2F9))),
      ),
      child: Row(
        children: [
          Text(
            date == null ? '8/19' : '${date.month}/${date.day}',
            style: TextStyle(
              color: AppColors.text50,
              fontFamily: 'Amarante',
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 13),
          SvgPicture.asset(AppAssets.categoryFood, width: 26, height: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['label'] as String? ?? '아주대학교 카페',
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: _smallText,
                ),
                const SizedBox(height: 7),
                const Text(
                  '오전 10:30',
                  style: TextStyle(color: AppColors.text50, fontSize: 12),
                ),
              ],
            ),
          ),
          _LightPrice(
            amount: '${isIncome ? '+' : ''}${_formatAmount(amount)}',
            color: isIncome ? const Color(0xFF6E9CFF) : AppColors.text,
          ),
        ],
      ),
    );
  }
}

class _WonIcon extends StatelessWidget {
  const _WonIcon({
    required this.dark,
    this.width = 14,
    this.height = 15,
    this.color,
  });

  final bool dark;
  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      dark ? AppAssets.wonDark : AppAssets.wonLight,
      width: width,
      height: height,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}

class _ReceiptPrice extends StatelessWidget {
  const _ReceiptPrice({
    required this.amount,
    this.color = const Color(0xFF1B1B1B),
  });

  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          amount,
          style: TextStyle(color: color, fontFamily: 'Amarante', fontSize: 20),
        ),
        const SizedBox(width: 4),
        _WonIcon(dark: true, color: color),
      ],
    );
  }
}

class _LightPrice extends StatelessWidget {
  const _LightPrice({required this.amount, this.color = AppColors.text});

  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          amount,
          style: TextStyle(color: color, fontFamily: 'Amarante', fontSize: 20),
        ),
        const SizedBox(width: 4),
        _WonIcon(dark: false, color: color),
      ],
    );
  }
}

String _formatAmount(int amount) {
  final negative = amount < 0;
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return '${negative ? '-' : ''}$buffer';
}
