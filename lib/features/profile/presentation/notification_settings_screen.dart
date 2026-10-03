import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/app_chevron.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../analysis/presentation/analysis_overview_screen.dart';
import '../../finance/data/finance_service.dart';
import '../../home/presentation/home_screen.dart';
import '../../ledger/presentation/ledger_screen.dart';
import '../../register/presentation/register_type_screen.dart';
import 'profile_screen.dart';

/// 마이_004: 알림 설정 화면.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key, this.financeService});
  final FinanceService? financeService;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _pushEnabled = false;
  bool _reminderEnabled = false;
  String _reminderTime = '21:00';
  bool _budgetAlertEnabled = true;
  bool _rewardAlertEnabled = true;
  bool _marketingAgreed = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.financeService != null) {
      _isLoading = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final data = await widget.financeService!.notificationSettings();
      if (mounted) {
        setState(() {
          _pushEnabled = data['push_enabled'] as bool? ?? _pushEnabled;
          _reminderEnabled =
              data['reminder_enabled'] as bool? ?? _reminderEnabled;
          _reminderTime = data['reminder_time'] as String? ?? _reminderTime;
          _budgetAlertEnabled =
              data['budget_alert_enabled'] as bool? ?? _budgetAlertEnabled;
          _rewardAlertEnabled =
              data['reward_alert_enabled'] as bool? ?? _rewardAlertEnabled;
          _marketingAgreed =
              data['marketing_agreed'] as bool? ?? _marketingAgreed;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _update(Map<String, Object?> body) async {
    final service = widget.financeService;
    if (service == null) return;
    try {
      await service.updateNotificationSettings(body);
      if (mounted) setState(() => _error = null);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
        await _load();
      }
    }
  }

  Future<void> _openSystemSettings() async {
    try {
      final opened = await launchUrl(Uri.parse('app-settings:'));
      if (opened || !mounted) return;
    } catch (_) {
      if (!mounted) return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('시스템 설정을 열 수 없습니다.')));
  }

  void _navigate(int index) {
    final Widget? destination = switch (index) {
      0 => HomeScreen(financeService: widget.financeService),
      1 => LedgerScreen(financeService: widget.financeService),
      2 => RegisterTypeScreen(financeService: widget.financeService),
      3 => AnalysisOverviewScreen(financeService: widget.financeService),
      4 => ProfileScreen(financeService: widget.financeService),
      _ => null,
    };
    if (destination == null) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
  }

  Future<void> _pickReminderTime() async {
    final parts = _reminderTime.split(':');
    final initial = TimeOfDay(
      hour: parts.isNotEmpty ? int.tryParse(parts[0]) ?? 21 : 21,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() => _reminderTime = formatted);
    await _update({'reminder_time': formatted});
  }

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
              top: 125,
              child: Text(
                '알림 설정',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ToggleRow(
                      label: '전체 푸시 알림',
                      value: _pushEnabled,
                      onChanged: (value) {
                        setState(() => _pushEnabled = value);
                        _update({'push_enabled': value});
                      },
                    ),
                    const SizedBox(height: 7),
                    const _SectionDivider(),
                    const SizedBox(height: 4),
                    const Text(
                      '항목별 설정',
                      style: TextStyle(color: AppColors.text50, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    _ToggleRow(
                      label: '기록 리마인더',
                      value: _reminderEnabled,
                      onChanged: (value) {
                        setState(() => _reminderEnabled = value);
                        _update({'reminder_enabled': value});
                      },
                    ),
                    const SizedBox(height: 24),
                    _ToggleRow(
                      label: '목표 초과 경고',
                      value: _budgetAlertEnabled,
                      onChanged: (value) {
                        setState(() => _budgetAlertEnabled = value);
                        _update({'budget_alert_enabled': value});
                      },
                    ),
                    const SizedBox(height: 24),
                    _ToggleRow(
                      label: '리워드 획득 알림',
                      value: _rewardAlertEnabled,
                      onChanged: (value) {
                        setState(() => _rewardAlertEnabled = value);
                        _update({'reward_alert_enabled': value});
                      },
                    ),
                    const SizedBox(height: 24),
                    _ToggleRow(
                      label: '마케팅 정보 수신',
                      value: _marketingAgreed,
                      onChanged: (value) {
                        setState(() => _marketingAgreed = value);
                        _update({'marketing_agreed': value});
                      },
                    ),
                    const _SectionDivider(),
                    _RowButton(
                      label: '기록 리마인더 시간',
                      value: _reminderTime,
                      onTap: _pickReminderTime,
                    ),
                    _RowButton(
                      label: 'iOS 알림 권한',
                      value: '시스템 설정 열기',
                      onTap: _openSystemSettings,
                    ),
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
            Positioned(
              left: 0,
              bottom: 0,
              child: AppBottomNavigation(
                selectedIndex: 4,
                onSelected: _navigate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 20),
    child: SizedBox(
      width: 354,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.text10)),
        ),
        child: SizedBox(height: 1),
      ),
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      _ToggleSwitch(value: value, onChanged: onChanged),
    ],
  );
}

class _ToggleSwitch extends StatelessWidget {
  const _ToggleSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 54,
      height: 32,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: value ? AppColors.main : AppColors.selected,
        borderRadius: BorderRadius.circular(30),
      ),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      child: SizedBox(
        width: 22,
        height: 22,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: value ? AppColors.text : AppColors.text20,
            shape: BoxShape.circle,
          ),
        ),
      ),
    ),
  );
}

class _RowButton extends StatelessWidget {
  const _RowButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(color: AppColors.text, fontSize: 14),
            ),
            const SizedBox(width: 6),
            const AppChevron(size: 16),
          ],
        ),
      ],
    ),
  );
}
