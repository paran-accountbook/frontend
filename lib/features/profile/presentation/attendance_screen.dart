import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../finance/data/finance_service.dart';

/// 마이_002: 출석 및 기록 현황 화면.
///
/// Figma(#마이_002_출석현황, node-id 705-23216) 기준: 연속 기록 요약 + 달력
/// (기록한 날/무지출 기록/기록 없음 3단계 표시) + 이번 달 통계로 구성된다.
/// 백엔드 AttendanceResponse는 현재 `recorded_dates` 한 가지 목록만 제공하고
/// 지출 기록일과 무지출 기록일을 구분하지 않으므로, 달력에서는 우선 "기록한
/// 날/기록 없음" 2단계만 실제 데이터로 표시하고 "무지출 기록" 범례는 향후
/// 백엔드가 목록을 분리 제공하면 연결한다(최종 보고서의 백엔드 수정 제안 참고).
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key, this.financeService});
  final FinanceService? financeService;

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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    if (widget.financeService != null) {
      _isLoading = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final data = await widget.financeService!.attendance();
      if (mounted) setState(() => _data = data);
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
      await _load();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isMarking = false);
    }
  }

  Set<DateTime> get _recordedDays {
    final dates =
        (_data?['recorded_dates'] as List?)?.whereType<String>() ??
        const <String>[];
    return dates
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
  }

  bool get _todayRecorded {
    final today = DateTime.now();
    return _recordedDays.contains(DateTime(today.year, today.month, today.day));
  }

  void _shiftMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
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
                '출석 현황',
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
                top: 190,
                bottom: 30,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '현재 연속 기록',
                        style: TextStyle(color: AppColors.text50, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$currentStreak',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '일',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '최고 연속 기록  $maxStreak일',
                        style: const TextStyle(
                          color: AppColors.text50,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _AttendanceCalendar(
                        focusedMonth: _focusedMonth,
                        recordedDays: _recordedDays,
                        onPrev: () => _shiftMonth(-1),
                        onNext: () => _shiftMonth(1),
                      ),
                      const SizedBox(height: 16),
                      const _CalendarLegend(),
                      const SizedBox(height: 24),
                      _StatCard(label: '이번 달 기록일', value: '$recordedDays일 / $daysInMonth일'),
                      const SizedBox(height: 12),
                      _StatCard(
                        label: '이번 달 기록률',
                        value: '${recordingRate.toStringAsFixed(0)}%',
                      ),
                      const SizedBox(height: 12),
                      _StatCard(label: '이번 달 무지출', value: '$noSpendDays일'),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: (_isMarking || _todayRecorded)
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
                            _todayRecorded
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
          ],
        ),
      ),
    );
  }
}

class _AttendanceCalendar extends StatelessWidget {
  const _AttendanceCalendar({
    required this.focusedMonth,
    required this.recordedDays,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime focusedMonth;
  final Set<DateTime> recordedDays;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
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
      cells.add(
        _CalendarDayCell(day: day, isToday: isToday, isRecorded: isRecorded),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onPrev,
                child: const Icon(
                  Icons.chevron_left,
                  color: AppColors.text50,
                ),
              ),
              Text(
                '${focusedMonth.year}년 ${focusedMonth.month}월',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: onNext,
                child: const Icon(
                  Icons.chevron_right,
                  color: AppColors.text50,
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
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.isToday,
    required this.isRecorded,
  });

  final int day;
  final bool isToday;
  final bool isRecorded;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isToday
            ? AppColors.text
            : isRecorded
            ? AppColors.main
            : Colors.transparent,
      ),
      child: Text(
        '$day',
        style: TextStyle(
          color: isToday
              ? AppColors.background
              : isRecorded
              ? Colors.white
              : AppColors.text50,
          fontSize: 12,
          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
  );
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) => const Wrap(
    spacing: 16,
    runSpacing: 8,
    children: [
      _LegendItem(color: AppColors.main, label: '기록한 날', outlined: false),
      _LegendItem(color: AppColors.main, label: '무지출 기록', outlined: true),
      _LegendItem(color: AppColors.text50, label: '기록 없음', outlined: false),
    ],
  );
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
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: outlined ? Colors.transparent : color,
          border: outlined ? Border.all(color: color, width: 1.5) : null,
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: AppColors.text50, fontSize: 12)),
    ],
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.secondary,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.text50, fontSize: 13)),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
