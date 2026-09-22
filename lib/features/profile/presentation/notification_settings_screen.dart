import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_chevron.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../finance/data/finance_service.dart';

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
  bool _pushEnabled = true;
  bool _reminderEnabled = true;
  String _reminderTime = '21:00';
  bool _budgetAlertEnabled = true;
  bool _rewardAlertEnabled = true;
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
      setState(() => _error = null);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
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
              top: 128,
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
                    const _SectionDivider(),
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
                    if (_reminderEnabled) ...[
                      const _SectionDivider(),
                      _RowButton(
                        label: '기록 리마인더 시간',
                        value: _reminderTime,
                        onTap: _pickReminderTime,
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
        decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.text10))),
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
          fontSize: 15,
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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: value ? AppColors.main : AppColors.selected,
        borderRadius: BorderRadius.circular(30),
      ),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(color: AppColors.text, fontSize: 15),
            ),
            const SizedBox(width: 6),
            const AppChevron(size: 16),
          ],
        ),
      ],
    ),
  );
}
