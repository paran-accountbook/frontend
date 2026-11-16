import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/p2_widgets.dart';
import '../../finance/data/finance_service.dart';
import '../../ledger/presentation/ledger_detail_screen.dart';
import '../data/insight_service.dart';
import 'pattern_report_screen.dart' show analysisPeriodLabel;

const _chevronDown = 'assets/icons/p2_chevron_down.svg';
const _chevronUp = 'assets/icons/p2_chevron_up.svg';
const _chevronSmall = 'assets/icons/p2_chevron_small.svg';

/// 처음에 보여주는 자주 구매한 품목 수.
const repeatItemsPreviewCount = 4;

String _shortDate(String? date) {
  final value = DateTime.tryParse(date ?? '');
  return value == null ? '' : '${value.month}/${value.day}';
}

int _int(Object? value) => (value as num? ?? 0).round();

/// 분석_004-01 반복 지출 분석 (+ 분석_006-01 정기 지출 제외).
class RepeatExpenseScreen extends StatefulWidget {
  const RepeatExpenseScreen({
    required this.service,
    super.key,
    this.financeService,
  });

  final InsightService service;
  final FinanceService? financeService;

  @override
  State<RepeatExpenseScreen> createState() => _RepeatExpenseScreenState();
}

class _RepeatExpenseScreenState extends State<RepeatExpenseScreen> {
  Map<String, dynamic>? _repurchase;
  Map<String, dynamic>? _recurring;
  bool _failed = false;
  bool _showAll = false;
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final results = await Future.wait([
        widget.service.repurchase(),
        widget.service.recurringExpenses(),
      ]);
      if (!mounted) return;
      setState(() {
        _repurchase = results[0];
        _recurring = results[1];
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _failed = true);
      showTopToast(
        context,
        error is ApiException ? error.message : '분석을 불러오지 못했어요',
        error: true,
      );
    }
  }

  Future<void> _exclude(String storeName) async {
    final confirmed = await showCenterConfirm(
      context,
      title: "'$storeName'를 정기 지출에서 제외할까요?",
      description: '매달 나가는 돈에서 제외되고, 다음에도 자동으로 찾지 않아요',
      note: '제외한 내역은 되돌릴 수 없어요',
      confirmLabel: '제외하기',
      label: '정기 지출 제외',
    );
    if (!confirmed || !mounted) return;
    try {
      await widget.service.dismissRecurringExpense(storeName);
      final recurring = await widget.service.recurringExpenses();
      if (mounted) setState(() => _recurring = recurring);
    } catch (error) {
      if (!mounted) return;
      showTopToast(
        context,
        error is ApiException ? error.message : '제외하지 못했어요. 다시 시도해 주세요',
        error: true,
      );
    }
  }

  void _openExpense(String? expenseId) {
    if (expenseId == null || expenseId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LedgerDetailScreen(
          expenseId: expenseId,
          financeService: widget.financeService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repurchase = _repurchase;
    final recurring = _recurring;
    final loaded = repurchase != null && recurring != null;
    return P2Page(
      title: '반복 지출 분석',
      children: [
        if (!loaded && !_failed)
          const Padding(
            padding: EdgeInsets.only(top: 120),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.main),
            ),
          )
        else if (!loaded)
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Center(
              child: Column(
                children: [
                  Text(
                    '불러오지 못했어요',
                    style: p2Body.copyWith(color: AppColors.text50),
                  ),
                  const SizedBox(height: 16),
                  P2Button(label: '다시 시도', width: 167, onPressed: _load),
                ],
              ),
            ),
          )
        else ...[
          P2Badge(analysisPeriodLabel(repurchase)),
          const SizedBox(height: 26),
          if (repurchase['has_data'] != true && recurring['has_data'] != true)
            const _Empty('기록이 쌓이면 알려드릴게요', top: 100)
          else ...[
            ..._repurchaseSection(repurchase),
            const SizedBox(height: 26),
            ..._recurringSection(recurring),
          ],
        ],
      ],
    );
  }

  List<Widget> _repurchaseSection(Map<String, dynamic> data) {
    final items = (data['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final visible = _showAll
        ? items
        : items.take(repeatItemsPreviewCount).toList();
    return [
      const P2SectionHeader(title: '자주 구매한 품목'),
      const SizedBox(height: 26),
      if (items.isEmpty)
        const _Empty('반복 구매한 품목이 아직 없어요')
      else ...[
        _TotalCard(
          key: const Key('repeat-total'),
          label: '반복 구매에 한 달 약',
          amount: _int(data['monthly_repeat_total']),
        ),
        const SizedBox(height: 26),
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(height: 17),
          _ItemRow(
            index: i,
            item: visible[i],
            expanded: _expanded.contains(i),
            onToggle: () => setState(
              () => _expanded.contains(i)
                  ? _expanded.remove(i)
                  : _expanded.add(i),
            ),
            onOpenExpense: _openExpense,
          ),
          const SizedBox(height: 17),
          const _Divider(),
        ],
        if (!_showAll && items.length > repeatItemsPreviewCount) ...[
          const SizedBox(height: 26),
          Center(
            child: GestureDetector(
              key: const Key('repeat-show-all'),
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _showAll = true),
              child: Text(
                '전체 ${items.length}개 보기',
                style: p2Caption80.copyWith(color: P2Colors.lavender),
              ),
            ),
          ),
        ],
      ],
    ];
  }

  List<Widget> _recurringSection(Map<String, dynamic> data) {
    final items = (data['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final fixed = _int(data['monthly_fixed_total']);
    final monthTotal = _int(data['this_month_total_amount']);
    final ratio = monthTotal > 0 ? (fixed * 100 / monthTotal).round() : null;
    return [
      const P2SectionHeader(
        title: '매달 나가는 돈',
        subtitle: '매월·매주 같은 곳에서 결제된 내역을 자동으로 찾았어요',
      ),
      const SizedBox(height: 26),
      if (items.isEmpty)
        const _Empty('정기 지출이 아직 없어요')
      else ...[
        _TotalCard(
          key: const Key('recurring-total'),
          label: ratio == null ? '월 고정 지출' : '월 고정 지출 · 이번 달 지출의 $ratio%',
          amount: fixed,
        ),
        const SizedBox(height: 26),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 17),
          _RecurringRow(
            item: items[i],
            onExclude: () => _exclude(items[i]['store_name'] as String? ?? ''),
          ),
          const SizedBox(height: 17),
          const _Divider(),
        ],
      ],
    ];
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.message, {this.top = 0});

  final String message;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top),
    child: Container(
      width: 354,
      padding: const EdgeInsets.symmetric(vertical: 30),
      alignment: Alignment.center,
      child: Text(message, style: p2Body.copyWith(color: AppColors.text50)),
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.text10,
    child: SizedBox(width: 354, height: 1),
  );
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.label, required this.amount, super.key});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 105,
    child: P2Card(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(19, 19, 19, 19),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1C1C24), Color(0xFF666399)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: p2Body.copyWith(color: P2Colors.lavender)),
          const SizedBox(height: 6),
          P2Amount(amount, size: 31.2),
        ],
      ),
    ),
  );
}

class _SubLine extends StatelessWidget {
  const _SubLine({required this.lead, required this.parts});

  final String lead;
  final List<String> parts;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(lead, style: p2Caption80),
      const SizedBox(width: 12),
      Text(parts.join(' · '), style: p2Caption50),
    ],
  );
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.index,
    required this.item,
    required this.expanded,
    required this.onToggle,
    required this.onOpenExpense,
  });

  final int index;
  final Map<String, dynamic> item;
  final bool expanded;
  final VoidCallback onToggle;
  final void Function(String? expenseId) onOpenExpense;

  @override
  Widget build(BuildContext context) {
    final interval = item['average_interval_days'] as num?;
    final sameDay = interval == null;
    final perPurchase = _int(item['average_amount_per_purchase']);
    final purchases = (item['purchases'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return Column(
      children: [
        GestureDetector(
          key: Key('repeat-item-$index'),
          behavior: HitTestBehavior.opaque,
          onTap: onToggle,
          child: SizedBox(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['item_name'] as String? ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: p2Body,
                      ),
                      const SizedBox(height: 9),
                      _SubLine(
                        lead: '${_int(item['purchase_count'])}회',
                        parts: [
                          sameDay ? '같은 날 구매' : '평균 ${interval.round()}일마다',
                          '마지막 ${_shortDate(item['last_purchased_date'] as String?)}',
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(sameDay ? '회당' : '월', style: p2Body),
                        const SizedBox(width: 6),
                        P2Amount(
                          sameDay
                              ? perPurchase
                              : _int(item['monthly_equivalent_amount']),
                        ),
                      ],
                    ),
                    if (!sameDay) ...[
                      const SizedBox(height: 3),
                      Text('회당 ${formatWon(perPurchase)}원', style: p2Caption50),
                    ],
                  ],
                ),
                const SizedBox(width: 8),
                SvgPicture.asset(
                  expanded ? _chevronUp : _chevronDown,
                  width: 24,
                  height: 24,
                ),
              ],
            ),
          ),
        ),
        if (expanded && purchases.isNotEmpty) ...[
          const SizedBox(height: 17),
          Container(
            width: 354,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                for (final purchase in purchases)
                  GestureDetector(
                    key: Key('repeat-purchase-${purchase['expense_id']}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        onOpenExpense(purchase['expense_id'] as String?),
                    child: SizedBox(
                      height: 44,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 14, right: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                monthDayLabel(purchase['date'] as String?),
                                style: const TextStyle(
                                  color: AppColors.text80,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 18 / 15,
                                ),
                              ),
                            ),
                            Text(
                              '${formatWon(_int(purchase['amount']))}원',
                              style: p2Body.copyWith(color: AppColors.text80),
                            ),
                            const SizedBox(width: 4),
                            SvgPicture.asset(
                              _chevronSmall,
                              width: 24,
                              height: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RecurringRow extends StatelessWidget {
  const _RecurringRow({required this.item, required this.onExclude});

  final Map<String, dynamic> item;
  final VoidCallback onExclude;

  @override
  Widget build(BuildContext context) {
    final cycle = item['cycle'] as String? ?? '매월';
    final store = item['store_name'] as String? ?? '';
    final monthly = cycle == '매월';
    return SizedBox(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: p2Body,
                ),
                const SizedBox(height: 9),
                _SubLine(
                  lead: cycle,
                  parts: [
                    '다음 결제 예상',
                    _shortDate(item['next_expected_date'] as String?),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('정기 지출이 아닌가요?', style: p2Caption50),
                    const SizedBox(width: 9),
                    GestureDetector(
                      key: Key('recurring-exclude-$store'),
                      behavior: HitTestBehavior.opaque,
                      onTap: onExclude,
                      child: Container(
                        height: 23,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.selected,
                          borderRadius: BorderRadius.circular(21),
                        ),
                        child: Text(
                          '제외',
                          style: p2Caption80.copyWith(color: P2Colors.lavender),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              P2Amount(_int(item['amount'])),
              const SizedBox(height: 3),
              Text(
                monthly
                    ? '${_int(item['purchase_count'])}회 결제'
                    : '월 약 ${formatWon(_int(item['monthly_equivalent_amount']))}원',
                style: p2Caption50,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
