import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/p2_widgets.dart';
import '../../analysis/data/insight_service.dart';
import '../../analysis/presentation/analysis_overview_screen.dart';
import '../../analysis/presentation/pattern_report_screen.dart';
import '../../analysis/presentation/repeat_expense_screen.dart';
import '../../finance/data/finance_service.dart';
import '../../home/presentation/home_screen.dart';
import '../../ledger/presentation/ledger_screen.dart';
import '../../register/presentation/register_type_screen.dart';
import 'profile_screen.dart';

const _chevron = 'assets/icons/analysis_arrow_right.svg';

/// 마이_002-01 출석 현황 (+ 마이_002-02 무지출 기록, 마이_003 리워드 달성 팝업).
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({
    super.key,
    this.financeService,
    this.insightService,
    this.initialData,
    this.initialMonth,
    this.today,
  });
  final FinanceService? financeService;

  /// 리워드·분석 화면. 없으면 financeService 가 InsightService 를 구현할 때 그것을 쓴다.
  final InsightService? insightService;
  final Map<String, dynamic>? initialData;
  final DateTime? initialMonth;
  final DateTime? today;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _rewards;
  bool _loading = false;
  bool _failed = false;
  bool _busy = false;
  bool? _todayRecorded;
  late DateTime _month;
  late DateTime _today;

  InsightService? get _insight =>
      widget.insightService ??
      switch (widget.financeService) {
        final InsightService service => service,
        _ => null,
      };

  bool get _isCurrentMonth =>
      _month.year == _today.year && _month.month == _today.month;

  @override
  void initState() {
    super.initState();
    final now = widget.today ?? DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    final initial = widget.initialMonth ?? now;
    _month = DateTime(initial.year, initial.month);
    _data = widget.initialData;
    if (_data != null && _isCurrentMonth) {
      _todayRecorded = _statusOf(_today) != null;
    }
    if (widget.financeService != null) {
      _loading = _data == null;
      _load().then((_) => _showNewRewards());
    }
  }

  Future<void> _load() async {
    final service = widget.financeService;
    if (service == null) return;
    final insight = _insight;
    try {
      final results = await Future.wait([
        service.attendance(month: _month),
        if (insight != null) insight.rewards(),
      ]);
      if (!mounted) return;
      setState(() {
        _data = results[0];
        if (results.length > 1) _rewards = results[1];
        _failed = false;
        if (_isCurrentMonth) _todayRecorded = _statusOf(_today) != null;
      });
    } catch (_) {
      if (!mounted) return;
      if (_data == null) setState(() => _failed = true);
      showTopToast(context, '출석 현황을 불러오지 못했어요', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 'recorded' · 'no_spend' · null(기록 없음)
  String? _statusOf(DateTime date) {
    for (final day in (_data?['calendar'] as List? ?? const [])) {
      if (day is! Map) continue;
      final value = DateTime.tryParse(day['date'] as String? ?? '');
      if (value != null &&
          value.year == date.year &&
          value.month == date.month &&
          value.day == date.day) {
        return day['status'] as String?;
      }
    }
    return null;
  }

  Future<void> _shiftMonth(int delta) async {
    final target = DateTime(_month.year, _month.month + delta);
    if (target.isAfter(DateTime(_today.year, _today.month))) return;
    setState(() => _month = target);
    await _load();
  }

  // ------------------------------------------------------------- 리워드 팝업
  Future<void> _showNewRewards() async {
    final insight = _insight;
    if (!mounted || insight == null) return;
    var seen = false;
    Future<void> markSeen() async {
      if (seen) return;
      seen = true;
      try {
        await insight.markRewardsSeen();
      } catch (_) {
        // 다음에 다시 열 때 한 번 더 시도된다.
      }
    }

    var shown = false;
    for (final key in const ['streak_7', 'month_20']) {
      final reward = rewardByKey(_rewards, key);
      if (reward?['is_new'] != true || !mounted) continue;
      shown = true;
      final open = await _showRewardPopup(key);
      if (open && mounted) {
        await markSeen();
        if (mounted) await _openAnalysis(key);
      }
    }
    if (shown) await markSeen();
  }

  Future<bool> _showRewardPopup(String key) async {
    final streak = key == 'streak_7';
    final result = await showBlurOverlay<bool>(
      context,
      label: streak ? '연속 7일 달성' : '이번 달 20일 달성',
      builder: (dialogContext) => P2DesignFrame(
        child: Center(
          child: _RewardPopup(
            number: streak ? 7 : 20,
            title: streak ? '7일 연속 기록 달성!' : '이번 달 20일 기록 달성!',
            description: streak ? '소비 패턴 리포트 잠금이 풀렸어요' : '반복 지출 분석 잠금이 풀렸어요',
            onClose: () => Navigator.of(dialogContext).pop(false),
            onOpen: () => Navigator.of(dialogContext).pop(true),
          ),
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _openAnalysis(String key) async {
    final insight = _insight;
    if (insight == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => key == 'streak_7'
            ? PatternReportScreen(service: insight)
            : RepeatExpenseScreen(
                service: insight,
                financeService: widget.financeService,
              ),
      ),
    );
  }

  // --------------------------------------------------------------- 무지출
  Future<void> _markNoSpend() async {
    final service = widget.financeService;
    if (service == null || _busy) return;
    final confirmed = await showCenterConfirm(
      context,
      title: '오늘 지출이 없었나요?',
      description: '무지출로 기록해도 연속 기록과 이번 달 기록일에 포함돼요',
      note: '오늘 소비를 등록하면 무지출 기록은 자동으로 해제돼요',
      noteColor: P2Colors.lavender,
      noteSize: 12,
      confirmLabel: '무지출 기록',
      confirmColor: AppColors.main,
      label: '무지출 기록',
      compact: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await service.markNoSpendDay();
      if (_month.year != _today.year || _month.month != _today.month) {
        _month = DateTime(_today.year, _today.month);
      }
      await _load();
      if (mounted) showTopToast(context, '오늘을 무지출로 기록했어요', bottom: true);
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.code == 'E408') {
        await _load();
      } else {
        showTopToast(context, error.message, error: true);
      }
    } catch (_) {
      if (mounted) {
        showTopToast(context, '기록하지 못했어요. 다시 시도해 주세요', error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _navigate(int index) {
    final Widget page = switch (index) {
      0 => HomeScreen(financeService: widget.financeService),
      1 => LedgerScreen(financeService: widget.financeService),
      2 => RegisterTypeScreen(financeService: widget.financeService),
      3 => AnalysisOverviewScreen(financeService: widget.financeService),
      _ => ProfileScreen(financeService: widget.financeService),
    };
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return P2Page(
      title: '출석 현황',
      bottomHeight: 100,
      bottom: Center(
        child: AppBottomNavigation(selectedIndex: 4, onSelected: _navigate),
      ),
      children: [
        const SizedBox(height: 1),
        const P2AsteriskDivider(),
        if (_loading && data == null)
          const Padding(
            padding: EdgeInsets.only(top: 120),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.main),
            ),
          )
        else if (data == null && _failed)
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Center(
              child: P2Button(label: '다시 시도', width: 167, onPressed: _load),
            ),
          )
        else
          ..._content(data ?? const {}),
      ],
    );
  }

  List<Widget> _content(Map<String, dynamic> data) {
    final current = data['current_streak'] as int? ?? 0;
    final max = data['max_streak'] as int? ?? 0;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final monthLabel = _isCurrentMonth ? '이번 달' : '${_month.month}월';
    final rewards = [
      (key: 'streak_7', name: '소비 패턴 리포트', target: 7, streak: true),
      (key: 'month_20', name: '반복 지출 분석', target: 20, streak: false),
    ];
    final cards = <Widget>[];
    final lines = <String>[];
    for (final item in rewards) {
      final reward = rewardByKey(_rewards, item.key);
      final target = reward?['progress_target'] as int? ?? item.target;
      final progress = reward?['progress_current'] as int? ?? 0;
      if (reward?['unlocked'] == true) {
        cards.add(
          _UnlockedCard(
            key: Key('attendance-open-${item.key}'),
            label: '${item.name} 열림',
            onTap: () => _openAnalysis(item.key),
          ),
        );
      } else if (progress <= 0) {
        lines.add(
          '$target일 ${item.streak ? '연속 ' : ''}기록하면 ${item.name} 잠금이 풀려요',
        );
      } else {
        lines.add('${target - progress}일만 더 기록하면 ${item.name} 잠금이 풀려요');
      }
    }
    final showBanner = _todayRecorded == false;
    final first = max == 0 && current == 0;
    return [
      const SizedBox(height: 20),
      Text('현재 연속 기록', style: p2Body.copyWith(color: AppColors.text50)),
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$current',
            key: const Key('attendance-current-streak'),
            style: TextStyle(
              color: P2Colors.lavender,
              fontFamily: 'Amarante',
              fontSize: current == 0 ? 40 : 36,
              height: current == 0 ? 50 / 40 : 45 / 36,
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: EdgeInsets.only(bottom: current == 0 ? 14 : 11),
            child: Text('일째', style: p2Body.copyWith(color: P2Colors.lavender)),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Text('최고 연속 기록', style: p2Caption80.copyWith(color: AppColors.text)),
          const SizedBox(width: 12),
          Text('$max일', style: p2Caption80.copyWith(color: Colors.white)),
        ],
      ),
      for (final card in cards) ...[const SizedBox(height: 20), card],
      if (lines.isNotEmpty) ...[
        SizedBox(height: cards.isEmpty ? 10 : 20),
        Text(
          lines.join('\n'),
          key: const Key('attendance-reward-hint'),
          style: p2Caption80.copyWith(color: P2Colors.lavender),
        ),
      ],
      const SizedBox(height: 20),
      const P2AsteriskDivider(),
      if (showBanner) ...[
        const SizedBox(height: 20),
        Text(
          first ? '첫 기록을 남겨볼까요?' : '오늘 아직 기록이 없어요',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            height: 24 / 20,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '오늘 기록하면 ${first ? 1 : current + 1}일째 연속 기록이에요',
          style: p2Caption80,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            P2Button(
              key: const Key('attendance-no-spend'),
              label: '무지출 기록',
              tone: P2ButtonTone.grey,
              width: 167,
              onPressed: _busy ? null : _markNoSpend,
            ),
            const SizedBox(width: 20),
            P2Button(
              key: const Key('attendance-register'),
              label: '소비 등록',
              width: 167,
              onPressed: () => _navigate(2),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const P2AsteriskDivider(),
      ],
      const SizedBox(height: 20),
      _MonthHeader(
        month: _month,
        canMoveNext: _month.isBefore(DateTime(_today.year, _today.month)),
        onPrev: () => _shiftMonth(-1),
        onNext: () => _shiftMonth(1),
      ),
      const SizedBox(height: 19),
      _CalendarGrid(month: _month, today: _today, statusOf: _statusOf),
      const SizedBox(height: 20),
      const _Legend(),
      const SizedBox(height: 20),
      const ColoredBox(
        color: AppColors.text10,
        child: SizedBox(width: 354, height: 1),
      ),
      const SizedBox(height: 10),
      _StatRow(
        label: '$monthLabel 기록일',
        value: '${data['this_month_recorded_days'] ?? 0}일 / $daysInMonth일',
      ),
      _StatRow(
        label: '$monthLabel 무지출',
        value: '${data['this_month_no_spend_days'] ?? 0}일',
      ),
    ];
  }
}

class _UnlockedCard extends StatelessWidget {
  const _UnlockedCard({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      width: 354,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.text80,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 18 / 15,
              ),
            ),
          ),
          Text('보러가기', style: p2Body.copyWith(color: P2Colors.lavender)),
          const SizedBox(width: 4),
          SvgPicture.asset(
            _chevron,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              P2Colors.lavender,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.canMoveNext,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final bool canMoveNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  static const _number = TextStyle(
    color: AppColors.text,
    fontFamily: 'Amarante',
    fontSize: 24,
    height: 30 / 24,
  );

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 354,
    height: 38,
    child: Row(
      children: [
        GestureDetector(
          key: const Key('attendance-prev-month'),
          behavior: HitTestBehavior.opaque,
          onTap: onPrev,
          child: SizedBox(
            width: 30,
            height: 38,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Transform.rotate(
                angle: 3.141592653589793,
                child: SvgPicture.asset(
                  AppAssets.monthArrowActive,
                  width: 10,
                  height: 12,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${month.year}', style: _number),
              const SizedBox(width: 4),
              const Text('년', style: p2Body),
              const SizedBox(width: 20),
              Text('${month.month}', style: _number),
              const SizedBox(width: 4),
              const Text('월', style: p2Body),
            ],
          ),
        ),
        GestureDetector(
          key: const Key('attendance-next-month'),
          behavior: HitTestBehavior.opaque,
          onTap: canMoveNext ? onNext : null,
          child: SizedBox(
            width: 30,
            height: 38,
            child: Align(
              alignment: Alignment.centerRight,
              child: SvgPicture.asset(
                canMoveNext
                    ? AppAssets.monthArrowActive
                    : AppAssets.monthArrowDim,
                width: 10,
                height: 12,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.today,
    required this.statusOf,
  });

  final DateTime month;
  final DateTime today;
  final String? Function(DateTime date) statusOf;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final days = DateTime(month.year, month.month + 1, 0).day;
    // 일요일 시작. 첫 주의 빈칸은 지난달 날짜를 흐리게 보여준다.
    final leading = first.weekday % 7;
    final cells = <Widget>[
      for (var i = leading; i > 0; i--)
        _DayCell(day: first.subtract(Duration(days: i)).day, outside: true),
      for (var day = 1; day <= days; day++)
        _DayCell(
          day: day,
          status: statusOf(DateTime(month.year, month.month, day)),
          today:
              today.year == month.year &&
              today.month == month.month &&
              today.day == day,
        ),
    ];
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      final week = cells.sublist(
        i,
        i + 7 > cells.length ? cells.length : i + 7,
      );
      rows.add(
        SizedBox(
          width: 354,
          height: 46,
          child: Stack(
            children: [
              for (var j = 0; j < week.length; j++)
                Positioned(
                  left: j * (354 - 46) / 6,
                  top: 0,
                  width: 46,
                  height: 46,
                  child: week[j],
                ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          rows[i],
        ],
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    this.status,
    this.today = false,
    this.outside = false,
  });

  final int day;
  final String? status;
  final bool today;
  final bool outside;

  @override
  Widget build(BuildContext context) {
    final recorded = status == 'recorded';
    final noSpend = status == 'no_spend';
    final textColor = recorded
        ? P2Colors.black
        : (noSpend || today) && !outside
        ? AppColors.text
        : AppColors.text20;
    final cell = Container(
      key: outside
          ? null
          : Key(
              'attendance-day-$day-${noSpend
                  ? 'no-spend'
                  : recorded
                  ? 'recorded'
                  : 'none'}',
            ),
      width: 46,
      height: 46,
      decoration: recorded
          ? const BoxDecoration(
              color: P2Colors.lavender,
              shape: BoxShape.circle,
            )
          : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              color: textColor,
              fontFamily: 'Amarante',
              fontSize: 20,
              height: 25 / 20,
            ),
          ),
          if (today)
            Positioned(
              top: 39,
              child: Container(
                key: const Key('attendance-today-dot'),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: recorded ? P2Colors.black : AppColors.text,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
    if (!noSpend) return cell;
    return CustomPaint(
      foregroundPainter: const _DashedBorderPainter(radius: 10),
      child: cell,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.radius});

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.5),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..color = P2Colors.lavender
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), paint);
        distance += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.radius != radius;
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 354,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(
          const BoxDecoration(color: P2Colors.lavender, shape: BoxShape.circle),
          '기록한 날',
        ),
        const SizedBox(width: 27),
        CustomPaint(
          painter: const _DashedBorderPainter(radius: 6.5),
          child: const SizedBox(width: 13, height: 13),
        ),
        const SizedBox(width: 8),
        const Text('무지출 기록', style: p2Caption80),
        const SizedBox(width: 27),
        _legendItem(
          const BoxDecoration(color: AppColors.text20, shape: BoxShape.circle),
          '기록 없음',
        ),
      ],
    ),
  );

  Widget _legendItem(BoxDecoration decoration, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 13, height: 13, decoration: decoration),
      const SizedBox(width: 8),
      Text(label, style: p2Caption80),
    ],
  );
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 354,
    height: 54,
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: p2Body.copyWith(color: AppColors.text50)),
        ),
        Text(value, style: p2Body),
      ],
    ),
  );
}

class _RewardPopup extends StatelessWidget {
  const _RewardPopup({
    required this.number,
    required this.title,
    required this.description,
    required this.onClose,
    required this.onOpen,
  });

  final int number;
  final String title;
  final String description;
  final VoidCallback onClose;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 354,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 354,
          padding: const EdgeInsets.only(top: 32, bottom: 28),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: P2Colors.lavender,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: P2Colors.black,
                    fontFamily: 'Amarante',
                    fontSize: 40,
                    height: 50 / 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 23,
                  fontWeight: FontWeight.w500,
                  height: 27 / 23,
                ),
              ),
              const SizedBox(height: 8),
              Text(description, style: p2Caption80),
              const SizedBox(height: 16),
              const ColoredBox(
                color: AppColors.text10,
                child: SizedBox(width: 354, height: 1),
              ),
              const SizedBox(height: 15),
              const Text('AI 분석 탭에서 바로 볼 수 있어요', style: p2Caption50),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            P2Button(
              key: const Key('reward-popup-close'),
              label: '닫기',
              tone: P2ButtonTone.grey,
              width: 167,
              onPressed: onClose,
            ),
            const SizedBox(width: 20),
            P2Button(
              key: const Key('reward-popup-open'),
              label: '보러 가기',
              width: 167,
              onPressed: onOpen,
            ),
          ],
        ),
      ],
    ),
  );
}
