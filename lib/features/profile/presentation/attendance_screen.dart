import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../shared/widgets/p1_design_components.dart';
import '../../finance/data/finance_service.dart';
import '../../ledger/presentation/ledger_screen.dart';

/// 마이_002: 출석 및 기록 현황 화면.
///
/// Figma(#마이_002_출석현황, node-id 705-23216) 기준: 연속 기록 요약 + 달력
/// (기록한 날/무지출 기록/기록 없음 3단계 표시) + 이번 달 통계로 구성된다.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({
    super.key,
    this.financeService,
    this.initialData,
    this.initialMonth,
    this.today,
  });
  final FinanceService? financeService;
  final Map<String, dynamic>? initialData;
  final DateTime? initialMonth;
  final DateTime? today;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = false;
  bool _isMarking = false;
  String? _error;
  String? _message;
  late DateTime _focusedMonth;
  late DateTime _today;

  @override
  void initState() {
    super.initState();
    final now = widget.today ?? DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    final initialMonth = widget.initialMonth ?? now;
    _focusedMonth = DateTime(initialMonth.year, initialMonth.month);
    _data = widget.initialData;
    if (widget.financeService != null) {
      _isLoading = true;
      _load(showLoading: false);
    }
  }

  Future<void> _load({bool showLoading = true}) async {
    final service = widget.financeService;
    if (service == null) return;
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final data = await service.attendance(month: _focusedMonth);
      if (mounted) {
        setState(() {
          _data = data;
          _error = null;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markNoSpendDay() async {
    final service = widget.financeService;
    if (service == null) return;
    setState(() {
      _isMarking = true;
      _error = null;
      _message = null;
    });
    try {
      await service.markNoSpendDay();
      setState(() => _message = '오늘을 무지출 날로 기록했어요');
      await _load(showLoading: false);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isMarking = false);
    }
  }

  Set<DateTime> get _recordedDays {
    final calendar = (_data?['calendar'] as List?)
        ?.whereType<Map<String, dynamic>>();
    if (calendar != null) {
      return _calendarDates(calendar, const {'recorded', 'no_spend'});
    }
    return _dateSet(_data?['recorded_dates']);
  }

  Set<DateTime> get _noSpendDays {
    final calendar = (_data?['calendar'] as List?)
        ?.whereType<Map<String, dynamic>>();
    if (calendar != null) {
      return _calendarDates(calendar, const {'no_spend'});
    }
    return _dateSet(_data?['no_spend_dates']);
  }

  bool get _todayRecorded {
    return _recordedDays.contains(_today);
  }

  Future<void> _shiftMonth(int delta) async {
    final target = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    final currentMonth = DateTime(_today.year, _today.month);
    if (target.isAfter(currentMonth)) return;
    setState(() {
      _focusedMonth = target;
      _message = null;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final currentStreak = _data?['current_streak'] as int? ?? 0;
    final maxStreak = _data?['max_streak'] as int? ?? 0;
    final recordedDays = _data?['this_month_recorded_days'] as int? ?? 0;
    final recordingRate =
        (_data?['this_month_recording_rate'] as num?)?.toDouble() ?? 0;
    final noSpendDays = _data?['this_month_no_spend_days'] as int? ?? 0;
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final isCurrentMonth =
        _focusedMonth.year == _today.year &&
        _focusedMonth.month == _today.month;
    final monthLabel = isCurrentMonth ? '이번 달' : '${_focusedMonth.month}월';

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
              top: 125,
              child: Text(
                '출석 및 기록 현황',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_isLoading)
              const Positioned(
                top: 300,
                left: 0,
                right: 0,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.main),
                ),
              )
            else
              Positioned(
                left: 24,
                right: 24,
                top: 191,
                bottom: 100,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const P1AsteriskDivider(),
                      const SizedBox(height: 20),
                      const Text(
                        '현재 연속 기록',
                        style: TextStyle(color: AppColors.text50, fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$currentStreak',
                            style: const TextStyle(
                              color: Color(0xFFA8A3FF),
                              fontFamily: 'Amarante',
                              fontSize: 36,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '일째',
                            style: TextStyle(
                              color: Color(0xFFA8A3FF),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '최고 연속 기록',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$maxStreak일',
                            style: const TextStyle(
                              color: Color(0xFFA8A3FF),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const P1AsteriskDivider(),
                      const SizedBox(height: 20),
                      _AttendanceCalendar(
                        focusedMonth: _focusedMonth,
                        recordedDays: _recordedDays,
                        noSpendDays: _noSpendDays,
                        today: _today,
                        onPrev: () => _shiftMonth(-1),
                        onNext: () => _shiftMonth(1),
                        onDateSelected: (date) => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => LedgerScreen(
                              financeService: widget.financeService,
                              initialAnchor: date,
                              initialPeriod: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _CalendarLegend(),
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: AppColors.text10),
                      const SizedBox(height: 14),
                      _StatCard(
                        label: '$monthLabel 기록일',
                        value: '$recordedDays일 / $daysInMonth일',
                      ),
                      const SizedBox(height: 4),
                      _StatCard(
                        label: '기록률',
                        value: '${recordingRate.toStringAsFixed(0)}%',
                      ),
                      const SizedBox(height: 4),
                      _StatCard(
                        label: '$monthLabel 무지출',
                        value: '$noSpendDays일',
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed:
                              (!isCurrentMonth || _isMarking || _todayRecorded)
                              ? null
                              : _markNoSpendDay,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.main,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            !isCurrentMonth
                                ? '이번 달에서 기록할 수 있어요'
                                : _todayRecorded
                                ? '오늘은 이미 기록했어요'
                                : _isMarking
                                ? '기록 중...'
                                : '오늘 무지출 기록하기',
                          ),
                        ),
                      ),
                      if (_message case final message?) ...[
                        const SizedBox(height: 12),
                        Text(
                          message,
                          style: const TextStyle(
                            color: AppColors.main,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (_error case final message?) ...[
                        const SizedBox(height: 12),
                        Text(
                          message,
                          style: const TextStyle(
                            color: Color(0xFFFF6B7A),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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
}

Set<DateTime> _calendarDates(
  Iterable<Map<String, dynamic>> calendar,
  Set<String> statuses,
) => calendar
    .where((day) => statuses.contains(day['status']))
    .map((day) => DateTime.tryParse(day['date'] as String? ?? ''))
    .whereType<DateTime>()
    .map((date) => DateTime(date.year, date.month, date.day))
    .toSet();

class _AttendanceCalendar extends StatelessWidget {
  const _AttendanceCalendar({
    required this.focusedMonth,
    required this.recordedDays,
    required this.noSpendDays,
    required this.today,
    required this.onPrev,
    required this.onNext,
    required this.onDateSelected,
  });

  final DateTime focusedMonth;
  final Set<DateTime> recordedDays;
  final Set<DateTime> noSpendDays;
  final DateTime today;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      0,
    ).day;
    // weekday: 월=1 ... 일=7. 달력은 일요일 시작으로 구성한다.
    final leadingBlanks = firstOfMonth.weekday % 7;

    final cells = <Widget>[];
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(focusedMonth.year, focusedMonth.month, day);
      final isToday =
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final isRecorded = recordedDays.contains(date);
      final isNoSpend = noSpendDays.contains(date);
      cells.add(
        _CalendarDayCell(
          day: day,
          isToday: isToday,
          isRecorded: isRecorded,
          isNoSpend: isNoSpend,
          onTap: () => onDateSelected(date),
        ),
      );
    }

    final currentMonth = DateTime(today.year, today.month);
    final canMoveNext = focusedMonth.isBefore(currentMonth);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              key: const Key('attendance-prev-month'),
              onTap: onPrev,
              child: Transform.rotate(
                angle: 3.141592653589793,
                child: SvgPicture.asset(
                  AppAssets.monthArrowActive,
                  width: 10,
                  height: 12,
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  '${focusedMonth.year}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontFamily: 'Amarante',
                    fontSize: 24,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '년',
                  style: TextStyle(color: AppColors.text, fontSize: 14),
                ),
                const SizedBox(width: 20),
                Text(
                  '${focusedMonth.month}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontFamily: 'Amarante',
                    fontSize: 24,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '월',
                  style: TextStyle(color: AppColors.text, fontSize: 14),
                ),
              ],
            ),
            GestureDetector(
              key: const Key('attendance-next-month'),
              onTap: canMoveNext ? onNext : null,
              child: SvgPicture.asset(
                canMoveNext
                    ? AppAssets.monthArrowActive
                    : AppAssets.monthArrowDim,
                width: 10,
                height: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: cells,
        ),
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.isToday,
    required this.isRecorded,
    required this.isNoSpend,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isRecorded;
  final bool isNoSpend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = isNoSpend
        ? 'no-spend'
        : isRecorded
        ? 'recorded'
        : 'none';
    return GestureDetector(
      key: Key('attendance-day-$day-$state'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: CustomPaint(
          foregroundPainter: !isToday && isNoSpend
              ? const _DashedRoundedBorderPainter()
              : null,
          child: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                isToday || isNoSpend ? 10 : 30,
              ),
              color: isToday
                  ? AppColors.text
                  : isRecorded && !isNoSpend
                  ? const Color(0xFFA8A3FF)
                  : Colors.transparent,
            ),
            child: Text(
              '$day',
              style: TextStyle(
                color: isToday
                    ? AppColors.background
                    : isNoSpend
                    ? AppColors.text
                    : isRecorded
                    ? const Color(0xFF1B1B1B)
                    : AppColors.text20,
                fontFamily: 'Amarante',
                fontSize: 20,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      );
    final paint = Paint()
      ..color = const Color(0xFFA8A3FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), paint);
        distance += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) => const Wrap(
    spacing: 27,
    runSpacing: 8,
    children: [
      _LegendItem(color: Color(0xFFA8A3FF), label: '기록한 날', outlined: false),
      _LegendItem(color: AppColors.main, label: '무지출 기록', outlined: true),
      _LegendItem(color: AppColors.selected, label: '기록 없음', outlined: false),
    ],
  );
}

Set<DateTime> _dateSet(Object? value) {
  final dates = value is List ? value : const <Object?>[];
  return dates
      .map(
        (value) => value is DateTime
            ? value
            : value is String
            ? DateTime.tryParse(value)
            : null,
      )
      .whereType<DateTime>()
      .map((date) => DateTime(date.year, date.month, date.day))
      .toSet();
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.outlined,
  });

  final Color color;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: outlined ? Colors.transparent : color,
          border: outlined ? Border.all(color: color, width: 1.5) : null,
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(color: AppColors.text80, fontSize: 12),
      ),
    ],
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.text50, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
