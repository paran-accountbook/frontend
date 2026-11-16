import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/network/app_services.dart';
import '../../../core/notifications/local_notifications.dart';
import '../../../core/notifications/notification_sync.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/p2_widgets.dart';
import '../../analysis/presentation/analysis_overview_screen.dart';
import '../../finance/data/finance_service.dart';
import '../../home/presentation/home_screen.dart';
import '../../ledger/presentation/ledger_screen.dart';
import '../../register/presentation/register_type_screen.dart';
import 'profile_screen.dart';

const _chevron = 'assets/icons/analysis_arrow_right.svg';

/// 마이_004-01 알림 설정 (+ 마이_004-02 기록 리마인더 시간 시트).
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({
    super.key,
    this.financeService,
    this.notifications,
    this.preferences,
  });

  final FinanceService? financeService;
  final LocalNotificationService? notifications;
  final AppPreferences? preferences;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  late final LocalNotificationService _local =
      widget.notifications ?? AppServices.notifications;
  late final AppPreferences _prefs =
      widget.preferences ?? AppServices.preferences;

  bool _loading = true;

  /// 서버 push_enabled(전체 알림). 화면에 전체 스위치는 없고, 꺼져 있으면 두 스위치를 꺼진 모양으로 보여준다.
  bool _push = true;
  bool _reminder = false;
  bool _ai = true;
  TimeOfDay _time = const TimeOfDay(hour: 21, minute: 0);
  NotificationPermission _permission = NotificationPermission.notDetermined;
  bool _saving = false;

  bool get _osOff => _permission == NotificationPermission.denied;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    final asked = await _prefs.notificationPermissionAsked();
    final permission = await _local.permission(asked: asked);
    if (mounted) setState(() => _permission = permission);
  }

  Future<void> _load() async {
    final service = widget.financeService;
    try {
      final json = service == null
          ? const <String, dynamic>{
              'push_enabled': true,
              'reminder_enabled': false,
              'reminder_time': '21:00',
            }
          : await service.notificationSettings();
      final settings = NotificationSettings.fromJson(
        json,
        aiFallback: await _prefs.aiAlertEnabled(),
      );
      await _checkPermission();
      if (!mounted) return;
      setState(() {
        _push = settings.pushEnabled;
        _reminder = settings.reminderEnabled;
        _time = settings.reminderTime;
        _ai = settings.aiReportEnabled;
        _loading = false;
      });
      await _reschedule();
    } catch (_) {
      if (!mounted) return;
      showTopToast(context, '알림 설정을 불러오지 못했어요', error: true);
      Navigator.of(context).maybePop();
    }
  }

  NotificationSettings get _settings => NotificationSettings(
    pushEnabled: _push,
    reminderEnabled: _reminder,
    reminderTime: _time,
    aiReportEnabled: _ai,
  );

  /// 현재 값으로 로컬 알림을 다시 예약 (전체 꺼짐·권한 없음이면 전부 취소).
  Future<void> _reschedule() => applyNotificationSettings(
    _settings,
    notifications: _local,
    preferences: _prefs,
  );

  /// 서버에 저장하고 알림을 다시 예약한다. 실패하면 [revert] 후 안내.
  Future<bool> _save(Map<String, Object?> body, VoidCallback revert) async {
    setState(() => _saving = true);
    try {
      await widget.financeService?.updateNotificationSettings(body);
      await _prefs.setAiAlertEnabled(_ai);
      await _reschedule();
      return true;
    } catch (_) {
      if (!mounted) return false;
      setState(revert);
      _saveFailed();
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 스위치를 켤 때 iOS 권한을 확인한다. 허용되면 true.
  Future<bool> _ensurePermission() async {
    if (_permission == NotificationPermission.granted) return true;
    if (_permission == NotificationPermission.denied) return false;
    final granted = await _local.requestPermission();
    await _prefs.setNotificationPermissionAsked();
    if (!mounted) return false;
    setState(
      () => _permission = granted
          ? NotificationPermission.granted
          : NotificationPermission.denied,
    );
    return granted;
  }

  void _saveFailed() =>
      showTopToast(context, '저장하지 못했어요. 다시 시도해 주세요', error: true, bottom: true);

  Future<void> _toggleReminder(bool value) => _toggle(value, reminder: true);

  Future<void> _toggleAi(bool value) => _toggle(value, reminder: false);

  /// 스위치 켬/끔. 전체 알림(push_enabled)이 꺼진 상태에서 하나를 켜면 push_enabled 를 켜면서
  /// 나머지 항목도 화면에 보이던 값(꺼짐)으로 함께 보낸다. 서버에는 push_enabled 만 false 이고
  /// 각 항목은 true 로 남아 있을 수 있어, 사용자가 켜지 않은 알림까지 켜지는 것을 막기 위함.
  Future<void> _toggle(bool value, {required bool reminder}) async {
    if (_saving || _osOff) return;
    if (value && !await _ensurePermission()) return;
    final before = (_push, _reminder, _ai);
    final wasPushOff = !_push;
    setState(() {
      if (reminder) {
        _reminder = value;
      } else {
        _ai = value;
      }
      if (value && wasPushOff) {
        _push = true;
        if (reminder) {
          _ai = false;
        } else {
          _reminder = false;
        }
      }
    });
    final body = <String, Object?>{
      'push_enabled': _push,
      if (reminder || (value && wasPushOff)) 'reminder_enabled': _reminder,
      if (!reminder || (value && wasPushOff)) 'ai_report_alert_enabled': _ai,
    };
    final saved = await _save(body, () {
      _push = before.$1;
      _reminder = before.$2;
      _ai = before.$3;
    });
    if (saved && value && mounted) {
      showTopToast(context, '알림을 켰어요', bottom: true);
    }
  }

  Future<void> _pickTime() async {
    if (_osOff || _saving) return;
    final picked = await showReminderTimeSheet(context, initial: _time);
    if (picked == null || !mounted) return;
    final previous = _time;
    setState(() => _time = picked);
    final saved = await _save({
      'reminder_time': formatReminderTime(picked),
    }, () => _time = previous);
    if (saved && mounted) {
      showTopToast(
        context,
        '매일 ${formatReminderTime(picked)}에 알려드릴게요',
        bottom: true,
      );
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
    final dim = _osOff ? .3 : 1.0;
    final items = Opacity(
      opacity: 1,
      child: IgnorePointer(
        ignoring: _osOff,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: dim,
              child: const Text(
                '항목별 설정',
                style: TextStyle(
                  color: AppColors.text80,
                  fontSize: 12.34,
                  fontWeight: FontWeight.w500,
                  height: 15 / 12.34,
                ),
              ),
            ),
            const SizedBox(height: 26),
            _SwitchRow(
              key: const Key('noti-reminder'),
              title: '기록 리마인더',
              subtitle: '매일 정한 시간에 기록을 알려드려요',
              value: _push && _reminder && !_osOff,
              dim: dim,
              onChanged: _toggleReminder,
            ),
            const SizedBox(height: 26),
            GestureDetector(
              key: const Key('noti-reminder-time'),
              behavior: HitTestBehavior.opaque,
              onTap: _pickTime,
              child: Opacity(
                opacity: dim,
                child: SizedBox(
                  width: 354,
                  height: 36,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '리마인더 시간',
                          style: p2Body.copyWith(color: AppColors.text50),
                        ),
                      ),
                      Text(formatReminderTime(_time), style: p2Body),
                      const SizedBox(width: 6),
                      SvgPicture.asset(_chevron, width: 24, height: 24),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            _SwitchRow(
              key: const Key('noti-ai'),
              title: '이달의 AI 분석 알림',
              subtitle: '매달 1일, 새 소비 습관 진단과 할인 찾기를 알려드려요',
              value: _push && _ai && !_osOff,
              dim: dim,
              onChanged: _toggleAi,
            ),
          ],
        ),
      ),
    );
    return P2Page(
      title: '알림 설정',
      bottomHeight: 100,
      bottom: Center(
        child: AppBottomNavigation(selectedIndex: 4, onSelected: _navigate),
      ),
      children: [
        const SizedBox(height: 1),
        const P2AsteriskDivider(),
        const SizedBox(height: 20),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 100),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.main),
            ),
          )
        else ...[
          if (_osOff) ...[
            _OsOffCard(onOpen: _local.openSystemSettings),
            const SizedBox(height: 20),
          ],
          items,
        ],
      ],
    );
  }
}

class _OsOffCard extends StatelessWidget {
  const _OsOffCard({required this.onOpen});

  final Future<void> Function() onOpen;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const Key('noti-open-settings'),
    behavior: HitTestBehavior.opaque,
    onTap: onOpen,
    child: Container(
      width: 354,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('휴대폰 알림이 꺼져 있어요', style: p2Body),
                Text('설정 > 소비로그 > 알림에서 허용해 주세요', style: p2Caption50),
              ],
            ),
          ),
          Text('설정 열기', style: p2Body.copyWith(color: P2Colors.lavender)),
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

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    super.key,
    this.dim = 1,
  });

  final String title;
  final String subtitle;
  final bool value;
  final double dim;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => onChanged(!value),
    child: SizedBox(
      width: 354,
      height: 42,
      child: Row(
        children: [
          Expanded(
            child: Opacity(
              opacity: dim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: p2Body.copyWith(height: 21 / 14)),
                  Text(subtitle, style: p2Caption50),
                ],
              ),
            ),
          ),
          P2Switch(value: value),
        ],
      ),
    ),
  );
}

/// 54×32 스위치 (켜짐: 보라 + 오른쪽 손잡이, 꺼짐: 회색 + 흐린 왼쪽 손잡이).
class P2Switch extends StatelessWidget {
  const P2Switch({required this.value, super.key});

  final bool value;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 54,
      height: 32,
      decoration: BoxDecoration(
        color: value ? AppColors.main : AppColors.selected,
        borderRadius: BorderRadius.circular(30),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 150),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 22,
          height: 22,
          margin: EdgeInsets.only(left: value ? 0 : 5, right: value ? 6 : 0),
          decoration: BoxDecoration(
            color: value ? AppColors.text : AppColors.text20,
            shape: BoxShape.circle,
          ),
        ),
      ),
    ),
  );
}

/// 마이_004-02 기록 리마인더 시간 시트 (5분 단위). [저장]이면 선택한 시각.
Future<TimeOfDay?> showReminderTimeSheet(
  BuildContext context, {
  required TimeOfDay initial,
}) => showBlurOverlay<TimeOfDay>(
  context,
  label: '기록 리마인더 시간',
  dismissible: true,
  builder: (dialogContext) => P2DesignFrame(
    child: Align(
      alignment: Alignment.bottomCenter,
      child: _ReminderTimeSheet(initial: initial),
    ),
  ),
);

class _ReminderTimeSheet extends StatefulWidget {
  const _ReminderTimeSheet({required this.initial});

  final TimeOfDay initial;

  @override
  State<_ReminderTimeSheet> createState() => _ReminderTimeSheetState();
}

class _ReminderTimeSheetState extends State<_ReminderTimeSheet> {
  static const _rows = 1000;
  late int _hour = widget.initial.hour;
  late int _minute = (widget.initial.minute / 5).round() % 12 * 5;
  late final FixedExtentScrollController _hours = FixedExtentScrollController(
    initialItem: _rows * 24 + _hour,
  );
  late final FixedExtentScrollController _minutes = FixedExtentScrollController(
    initialItem: _rows * 12 + _minute ~/ 5,
  );

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    super.dispose();
  }

  Widget _wheel({
    required Key key,
    required FixedExtentScrollController controller,
    required int count,
    required int selected,
    required String Function(int index) label,
    required ValueChanged<int> onChanged,
  }) => SizedBox(
    width: 100,
    height: 195,
    child: ListWheelScrollView.useDelegate(
      key: key,
      controller: controller,
      itemExtent: 39,
      diameterRatio: 100,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) => onChanged(index % count),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: _rows * count * 2,
        builder: (context, index) {
          final value = index % count;
          final raw = (value - selected).abs();
          final distance = raw > count / 2 ? count - raw : raw;
          final (size, opacity) = switch (distance) {
            0 => (24.0, 1.0),
            1 => (19.0, .5),
            _ => (17.0, .25),
          };
          return Center(
            child: Text(
              label(value),
              style: TextStyle(
                color: AppColors.text.withValues(alpha: opacity),
                fontFamily: 'Amarante',
                fontSize: size,
                height: 1.25,
              ),
            ),
          );
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Container(
    width: 402,
    height: 392,
    decoration: const BoxDecoration(
      color: AppColors.secondary,
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      border: Border(top: BorderSide(color: AppColors.text10)),
    ),
    child: Stack(
      children: [
        Positioned(
          left: 181,
          top: 13,
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0x40E2E2F9),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const Positioned(
          left: 25,
          top: 35,
          child: Text(
            '기록 리마인더 시간',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 24 / 20,
            ),
          ),
        ),
        Positioned(
          left: 25,
          top: 155,
          child: Container(
            width: 354,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0x14E2E2F9),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Positioned(
          left: 91.5,
          top: 79.5,
          child: _wheel(
            key: const Key('reminder-hour-wheel'),
            controller: _hours,
            count: 24,
            selected: _hour,
            label: (value) => '$value',
            onChanged: (value) => setState(() => _hour = value),
          ),
        ),
        const Positioned(
          left: 198,
          top: 161,
          child: Text(
            ':',
            style: TextStyle(
              color: AppColors.text,
              fontFamily: 'Amarante',
              fontSize: 24,
              height: 1.25,
            ),
          ),
        ),
        Positioned(
          left: 209.5,
          top: 79.5,
          child: _wheel(
            key: const Key('reminder-minute-wheel'),
            controller: _minutes,
            count: 12,
            selected: _minute ~/ 5,
            label: (value) => (value * 5).toString().padLeft(2, '0'),
            onChanged: (value) => setState(() => _minute = value * 5),
          ),
        ),
        Positioned(
          left: 25,
          top: 295,
          child: Row(
            children: [
              P2Button(
                key: const Key('reminder-cancel'),
                label: '취소',
                tone: P2ButtonTone.grey,
                width: 167,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 20),
              P2Button(
                key: const Key('reminder-save'),
                label: '저장',
                width: 167,
                onPressed: () => Navigator.of(
                  context,
                ).pop(TimeOfDay(hour: _hour, minute: _minute)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
