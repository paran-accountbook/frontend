import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/p2_widgets.dart';
import '../../finance/data/finance_service.dart';
import '../data/insight_service.dart';
import 'ai_opinion_screen.dart';
import 'pattern_report_screen.dart';
import 'repeat_expense_screen.dart';
import 'saving_hint_screen.dart';

const p2PiggyIcon = 'assets/icons/p2_ai_piggy.svg';
const p2BagIcon = 'assets/icons/p2_ai_bag.svg';
const p2PencilIcon = 'assets/icons/p2_ai_pencil.svg';
const p2BellIcon = 'assets/icons/p2_ai_bell.svg';
const p2LockIcon = 'assets/icons/p2_ai_lock.svg';
const p2ChevronIcon = 'assets/icons/analysis_arrow_right.svg';

/// 분석_008-01: 소비 분석 탭의 [AI분석] 첫 화면 내용.
class AiAnalysisSection extends StatefulWidget {
  const AiAnalysisSection({
    required this.service,
    super.key,
    this.financeService,
    this.tabs,
  });

  final InsightService service;
  final FinanceService? financeService;

  /// 위쪽 [리포트] [AI분석] 칩.
  final Widget? tabs;

  @override
  State<AiAnalysisSection> createState() => AiAnalysisSectionState();
}

class AiAnalysisSectionState extends State<AiAnalysisSection> {
  Map<String, dynamic>? _opinion;
  Map<String, dynamic>? _saving;
  Map<String, dynamic>? _rewards;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() {
      _loading = _opinion == null;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.service.aiOpinionStatus(),
        widget.service.savingHintStatus(),
        widget.service.rewards(),
      ]);
      if (!mounted) return;
      setState(() {
        _opinion = results[0];
        _saving = results[1];
        _rewards = results[2];
      });
    } catch (_) {
      if (mounted && _opinion == null) {
        setState(() => _error = 'AI 분석을 불러오지 못했어요.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? _quota(Map<String, dynamic>? data) =>
      data?['quota'] as Map<String, dynamic>?;

  int _remaining(Map<String, dynamic>? data) =>
      _quota(data)?['remaining'] as int? ?? 0;

  Future<T?> _withLoading<T>(Future<T> Function() task) async {
    if (_busy) return null;
    setState(() => _busy = true);
    try {
      return await task();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showGenerateError(ApiException error) {
    final message = switch (error.code) {
      'E705' || 'E709' => '지난달 기록이 5건 이상이어야 받을 수 있어요',
      'E706' || 'E710' => '이번 달 이용 횟수를 모두 사용했어요',
      _ => '잠시 후 다시 시도해 주세요',
    };
    showTopToast(context, message, error: true);
  }

  Future<void> _openOpinion() async {
    final status = _opinion;
    if (_remaining(status) >= 1) {
      try {
        final created = await _withLoading(widget.service.generateAiOpinion);
        if (created == null || !mounted) return;
        await _pushOpinion(
          created['result'] as Map<String, dynamic>?,
          created['quota'] as Map<String, dynamic>?,
        );
      } on ApiException catch (error) {
        if (mounted) _showGenerateError(error);
      } catch (_) {
        if (mounted) showTopToast(context, '잠시 후 다시 시도해 주세요', error: true);
      }
      await reload();
      return;
    }
    final latest = status?['latest'] as Map<String, dynamic>?;
    if (latest == null) {
      showTopToast(
        context,
        '${monthDayLabel(_quota(status)?['next_reset_date'] as String?)}에 새로 받을 수 있어요',
        error: true,
      );
      return;
    }
    await _pushOpinion(latest, _quota(status));
  }

  Future<void> _pushOpinion(
    Map<String, dynamic>? result,
    Map<String, dynamic>? quota,
  ) async {
    if (result == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AiOpinionScreen(result: result, quota: quota),
      ),
    );
  }

  Future<void> _openSavingHint() async {
    var status = _saving;
    final consent = status?['consent'] as Map<String, dynamic>?;
    if (consent?['agreed'] != true) {
      final agreed = await showSavingHintConsent(context);
      if (!agreed || !mounted) return;
      try {
        final result = await _withLoading(
          widget.service.agreeSavingHintConsent,
        );
        if (result == null || !mounted) return;
        status = {...?status, 'consent': result['consent']};
        setState(() => _saving = status);
      } on ApiException catch (error) {
        if (mounted) showTopToast(context, error.message, error: true);
        return;
      }
    }
    if (_remaining(status) >= 1) {
      try {
        final created = await _withLoading(widget.service.generateSavingHint);
        if (created == null || !mounted) return;
        await _pushSaving(
          created['result'] as Map<String, dynamic>?,
          created['quota'] as Map<String, dynamic>?,
        );
      } on ApiException catch (error) {
        if (!mounted) return;
        if (error.code == 'E715') {
          setState(() {
            _saving = {
              ...?_saving,
              'consent': {'agreed': false},
            };
          });
          await _openSavingHint();
          return;
        }
        _showGenerateError(error);
      } catch (_) {
        if (mounted) showTopToast(context, '잠시 후 다시 시도해 주세요', error: true);
      }
      await reload();
      return;
    }
    final latest = status?['latest'] as Map<String, dynamic>?;
    if (latest == null) {
      showTopToast(
        context,
        '${monthDayLabel(_quota(status)?['next_reset_date'] as String?)}에 새로 받을 수 있어요',
        error: true,
      );
      return;
    }
    await _pushSaving(latest, _quota(status));
  }

  Future<void> _pushSaving(
    Map<String, dynamic>? result,
    Map<String, dynamic>? quota,
  ) async {
    if (result == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SavingHintScreen(result: result, quota: quota),
      ),
    );
  }

  Future<void> _openPattern() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PatternReportScreen(service: widget.service),
    ),
  );

  Future<void> _openRepeat() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => RepeatExpenseScreen(
        service: widget.service,
        financeService: widget.financeService,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      ?widget.tabs,
      const SizedBox(height: 26),
      const P2AsteriskDivider(),
      const SizedBox(height: 26),
      const P2SectionHeader(title: 'AI 코치', subtitle: 'AI가 내 기록을 읽고 조언해줘요'),
      const SizedBox(height: 25),
    ];
    if (_loading) {
      children.add(
        const SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    } else if (_error != null) {
      children.add(
        P2Card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: p2Caption80),
              TextButton(onPressed: reload, child: const Text('재시도')),
            ],
          ),
        ),
      );
    } else {
      children.addAll([
        P2Card(
          padding: const EdgeInsets.fromLTRB(21, 20, 21, 19),
          child: Column(
            children: [
              _coachRow(
                key: const Key('ai-coach-opinion'),
                icon: p2PiggyIcon,
                iconSize: const Size(24, 18),
                title: '소비 습관 진단',
                subtitle: '돈이 새는 곳과 바꿀 습관',
                data: _opinion,
                onTap: _openOpinion,
              ),
              const SizedBox(height: 15),
              const _RowDivider(),
              const SizedBox(height: 15.5),
              _coachRow(
                key: const Key('ai-coach-saving'),
                icon: p2BagIcon,
                iconSize: const Size(18, 18),
                title: '할인 찾기',
                subtitle: '자주 쓰는 곳의 할인·적립 정보',
                data: _saving,
                onTap: _openSavingHint,
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const Text('매달 1일, 기능마다 1회씩 새로 받아요', style: p2Caption50),
        const SizedBox(height: 26),
        const P2AsteriskDivider(),
        const SizedBox(height: 26),
        const P2SectionHeader(
          title: '기록하면 열리는 분석',
          subtitle: '내 기록을 숫자로 정리해줘요',
        ),
        const SizedBox(height: 26),
        P2Card(
          padding: const EdgeInsets.fromLTRB(21, 20, 21, 19),
          child: Column(
            children: [
              _unlockRow(
                key: const Key('ai-unlock-pattern'),
                icon: p2PencilIcon,
                iconSize: const Size(26, 26),
                title: '소비 패턴 리포트',
                subtitle: '요일·시간대·자주 간 가게',
                reward: rewardByKey(_rewards, 'streak_7'),
                hint: (target) => '연속 $target일 기록하면 열려요',
                defaultTarget: 7,
                onTap: _openPattern,
              ),
              const SizedBox(height: 15),
              const _RowDivider(),
              const SizedBox(height: 15.5),
              _unlockRow(
                key: const Key('ai-unlock-repeat'),
                icon: p2BellIcon,
                iconSize: const Size(18, 20),
                title: '반복 지출 분석',
                subtitle: '또 사는 물건·매달 나가는 돈',
                reward: rewardByKey(_rewards, 'month_20'),
                hint: (target) => '이번 달 $target일 소비 기록하면 열려요',
                defaultTarget: 20,
                onTap: _openRepeat,
              ),
            ],
          ),
        ),
      ]);
    }
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
        if (_busy)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x40121215),
              child: Center(
                child: CircularProgressIndicator(
                  key: Key('ai-generating'),
                  color: P2Colors.lavender,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _icon(String asset, Size size) => SizedBox.square(
    dimension: 26,
    child: Center(
      child: SvgPicture.asset(asset, width: size.width, height: size.height),
    ),
  );

  Widget _coachRow({
    required Key key,
    required String icon,
    required Size iconSize,
    required String title,
    required String subtitle,
    required Map<String, dynamic>? data,
    required VoidCallback onTap,
  }) {
    final quota = _quota(data);
    final remaining = quota?['remaining'] as int? ?? 0;
    final latest = data?['latest'] as Map<String, dynamic>?;
    final latestMonth = monthOf(latest?['target_month'] as String?);
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          _icon(icon, iconSize),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: p2Body),
                    const SizedBox(width: 8),
                    remaining >= 1
                        ? const P2Badge('이번 달 1회')
                        : P2Badge(
                            '${monthDayLabel(quota?['next_reset_date'] as String?)} 충전',
                            tone: P2BadgeTone.muted,
                          ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: p2Caption80),
                if (remaining == 0 && latestMonth != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$latestMonth월 결과 다시 보기',
                    style: p2Caption80.copyWith(color: P2Colors.lavender),
                  ),
                ],
              ],
            ),
          ),
          SvgPicture.asset(p2ChevronIcon, width: 24, height: 24),
        ],
      ),
    );
  }

  Widget _unlockRow({
    required Key key,
    required String icon,
    required Size iconSize,
    required String title,
    required String subtitle,
    required Map<String, dynamic>? reward,
    required String Function(int target) hint,
    required int defaultTarget,
    required VoidCallback onTap,
  }) {
    final unlocked = reward?['unlocked'] == true;
    final target = reward?['progress_target'] as int? ?? defaultTarget;
    final current = unlocked
        ? target
        : (reward?['progress_current'] as int? ?? 0).clamp(0, target);
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: unlocked ? onTap : null,
      child: Row(
        children: [
          _icon(icon, iconSize),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 238,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: p2Body),
                      Text(
                        '$current/$target일',
                        style: p2Caption80.copyWith(color: P2Colors.lavender),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: p2Caption80),
                const SizedBox(height: 9),
                _ProgressBar(
                  width: 238,
                  value: target == 0 ? 0 : current / target,
                ),
                const SizedBox(height: 9),
                Text(hint(target), style: p2Caption50),
              ],
            ),
          ),
          SizedBox.square(
            dimension: 24,
            child: Center(
              child: unlocked
                  ? SvgPicture.asset(p2ChevronIcon, width: 24, height: 24)
                  : SvgPicture.asset(p2LockIcon, width: 12.3, height: 15.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 305,
    height: 0.5,
    child: ColoredBox(color: AppColors.text10),
  );
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.width, required this.value});

  final double width;
  final double value;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: SizedBox(
      width: width,
      height: 7,
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.selected)),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: width * value.clamp(0, 1),
            child: const ColoredBox(color: AppColors.main),
          ),
        ],
      ),
    ),
  );
}
