import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/p2_widgets.dart';
import '../data/insight_service.dart';

const _piggyIcon = 'assets/icons/p2_ai_piggy.svg';
const _trackColor = Color(0xE6272932);

/// 결제수단별 막대·범례 색.
const paymentShareColors = <String, Color>{
  '체크카드': Color(0xFF5E56FF),
  '간편결제': Color(0xFFA8A3FF),
  '신용카드': Color(0xFF4E4391),
  '현금': Color(0xFF9A9AA5),
  '계좌이체': Color(0xFF62626C),
  '기타': Color(0xFF41414A),
};

/// '최근 3개월 · 분석 기간 9~11월'
String analysisPeriodLabel(Map<String, dynamic> data) {
  final start = monthOf(data['start_month'] as String?);
  final end = monthOf(data['end_month'] as String?);
  if (start == null || end == null) return '최근 3개월';
  return '최근 3개월 · 분석 기간 $start~$end월';
}

String _percent(num? value) => '${(value ?? 0).round()}%';

/// 분석_003-01 소비 패턴 리포트.
class PatternReportScreen extends StatefulWidget {
  const PatternReportScreen({required this.service, super.key});

  final InsightService service;

  @override
  State<PatternReportScreen> createState() => _PatternReportScreenState();
}

class _PatternReportScreenState extends State<PatternReportScreen> {
  Map<String, dynamic>? _data;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final data = await widget.service.pattern();
      if (mounted) setState(() => _data = data);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _failed = true);
      showTopToast(context, error.message, error: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
      showTopToast(context, '리포트를 불러오지 못했어요', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return P2Page(
      title: '소비 패턴 리포트',
      children: [
        if (data == null && !_failed)
          const Padding(
            padding: EdgeInsets.only(top: 120),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.main),
            ),
          )
        else if (data == null)
          _Retry(onRetry: _load)
        else ...[
          P2Badge(analysisPeriodLabel(data)),
          const SizedBox(height: 26),
          if (data['has_data'] != true)
            const _EmptyMessage('최근 3개월 소비 기록이 없어요')
          else
            ..._sections(data),
        ],
      ],
    );
  }

  List<Widget> _sections(Map<String, dynamic> data) {
    List<Map<String, dynamic>> list(String key) =>
        (data[key] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();
    final summary = (data['summary'] as List? ?? const [])
        .whereType<String>()
        .toList();
    final weekdays = list('weekday_distribution');
    final slots = list('time_slot_distribution');
    final merchants = list('top_merchants').take(5).toList();
    final payments = list('payment_method_share');
    final sections = <Widget>[
      if (summary.isNotEmpty) _SummaryCard(lines: summary),
      if (weekdays.isNotEmpty) _WeekdayCard(rows: weekdays),
      if (slots.isNotEmpty) _TimeSlotCard(rows: slots),
      if (merchants.isNotEmpty) _MerchantCard(rows: merchants),
      if (payments.any((row) => (row['amount'] as num? ?? 0) > 0))
        _PaymentCard(rows: payments),
    ];
    return [
      for (var i = 0; i < sections.length; i++) ...[
        if (i > 0) const SizedBox(height: 26),
        sections[i],
      ],
    ];
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 80),
    child: Center(
      child: Column(
        children: [
          Text('불러오지 못했어요', style: p2Body.copyWith(color: AppColors.text50)),
          const SizedBox(height: 16),
          P2Button(label: '다시 시도', width: 167, onPressed: onRetry),
        ],
      ),
    ),
  );
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 100),
    child: SizedBox(
      width: 354,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: p2Body.copyWith(color: AppColors.text50),
      ),
    ),
  );
}

const _cardTitle = TextStyle(
  color: AppColors.text,
  fontSize: 15,
  fontWeight: FontWeight.w600,
  height: 18 / 15,
);

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) => P2Card(
    color: const Color(0x805E56FF),
    border: false,
    radius: 18,
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: Center(
                child: SvgPicture.asset(_piggyIcon, width: 24, height: 18),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '이런 패턴이 보여요',
              style: p2Body.copyWith(color: P2Colors.lavender),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          Text('· ${lines[i]}', style: p2Body),
        ],
      ],
    ),
  );
}

class _WeekdayCard extends StatelessWidget {
  const _WeekdayCard({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    num amountOf(Map<String, dynamic> row) => row['amount'] as num? ?? 0;
    var maxIndex = 0;
    for (var i = 1; i < rows.length; i++) {
      if (amountOf(rows[i]) > amountOf(rows[maxIndex])) maxIndex = i;
    }
    final maxAmount = amountOf(rows[maxIndex]);
    final top = rows[maxIndex];
    return P2Card(
      key: const Key('pattern-weekday'),
      padding: const EdgeInsets.fromLTRB(19, 19, 19, 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 22,
            child: Row(
              children: [
                const Expanded(child: Text('요일별 지출', style: _cardTitle)),
                if (maxAmount > 0)
                  Text(
                    '${top['weekday']}요일 ${_percent(top['percentage'] as num?)}',
                    style: p2Body.copyWith(color: P2Colors.lavender),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < rows.length; i++)
                  Container(
                    width: 37,
                    height: maxAmount <= 0
                        ? 24
                        : 24 + 72 * (amountOf(rows[i]) / maxAmount),
                    decoration: BoxDecoration(
                      color: i == maxIndex && maxAmount > 0
                          ? AppColors.main
                          : _trackColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < rows.length; i++)
                SizedBox(
                  width: 37,
                  child: Text(
                    rows[i]['weekday'] as String? ?? '',
                    textAlign: TextAlign.center,
                    style: p2Body.copyWith(
                      color: i == maxIndex && maxAmount > 0
                          ? P2Colors.lavender
                          : AppColors.text50,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeSlotCard extends StatelessWidget {
  const _TimeSlotCard({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    num pctOf(Map<String, dynamic> row) => row['percentage'] as num? ?? 0;
    var maxIndex = 0;
    for (var i = 1; i < rows.length; i++) {
      if (pctOf(rows[i]) > pctOf(rows[maxIndex])) maxIndex = i;
    }
    final hasMax = pctOf(rows[maxIndex]) > 0;
    return P2Card(
      key: const Key('pattern-time-slot'),
      padding: const EdgeInsets.fromLTRB(19, 19, 19, 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('시간대별 지출', style: _cardTitle),
          const SizedBox(height: 14),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _slotRow(rows[i], highlighted: hasMax && i == maxIndex),
          ],
        ],
      ),
    );
  }

  Widget _slotRow(Map<String, dynamic> row, {required bool highlighted}) {
    final label = (row['label'] as String? ?? '').replaceFirstMapped(
      RegExp(r'(\S)\('),
      (m) => '${m[1]} (',
    );
    final pct = ((row['percentage'] as num? ?? 0) / 100).clamp(0.0, 1.0);
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              maxLines: 1,
              style: p2Body.copyWith(
                height: 20 / 14,
                color: highlighted ? AppColors.text : AppColors.text80,
              ),
            ),
          ),
          Container(
            width: 136,
            height: 6,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: _trackColor,
              borderRadius: BorderRadius.circular(3),
            ),
            child: pct <= 0
                ? null
                : Container(
                    width: (136 * pct).clamp(5.0, 136.0),
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.main,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
          ),
          Expanded(
            child: Text(
              _percent(row['percentage'] as num?),
              textAlign: TextAlign.right,
              style: p2Caption80.copyWith(
                height: 20 / 12,
                color: highlighted ? P2Colors.lavender : AppColors.text80,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantCard extends StatelessWidget {
  const _MerchantCard({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) => P2Card(
    key: const Key('pattern-merchants'),
    padding: const EdgeInsets.fromLTRB(19, 19, 19, 19),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('자주 간 가게 TOP 5', style: _cardTitle),
        const SizedBox(height: 14),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          SizedBox(
            height: 22,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${i + 1}',
                    style: p2Body.copyWith(color: AppColors.text50),
                  ),
                ),
                Expanded(
                  child: Text(
                    rows[i]['store_name'] as String? ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: p2Body,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${rows[i]['visit_count'] ?? 0}회 · '
                  '${formatWon((rows[i]['total_amount'] as num? ?? 0).toInt())}원',
                  style: p2Caption80,
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final shown = rows.where((row) => (row['amount'] as num? ?? 0) > 0).toList()
      ..sort((a, b) => (b['amount'] as num).compareTo(a['amount'] as num));
    final total = shown.fold<num>(
      0,
      (sum, row) => sum + (row['amount'] as num),
    );
    Color colorOf(Map<String, dynamic> row) =>
        paymentShareColors[row['payment_method']] ?? const Color(0xFF41414A);
    const gap = 3.0;
    final available = 316 - gap * (shown.length - 1);
    return P2Card(
      key: const Key('pattern-payment'),
      padding: const EdgeInsets.fromLTRB(19, 19, 19, 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('결제수단 비중', style: _cardTitle),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Container(
                  width: (available * (shown[i]['amount'] as num) / total)
                      .clamp(3.0, 316.0),
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorOf(shown[i]),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 13),
          Wrap(
            runSpacing: 5,
            children: [
              for (final row in shown)
                SizedBox(
                  width: 108,
                  height: 21,
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: colorOf(row),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${row['payment_method']} ${_percent(row['percentage'] as num?)}',
                        style: p2Caption80,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
