import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../finance/data/finance_service.dart';

/// 마이_002: 출석 및 기록 현황 화면.
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

  bool get _todayRecorded {
    final dates =
        (_data?['recorded_dates'] as List?)?.whereType<String>().toSet() ??
        const <String>{};
    final today = DateTime.now();
    final iso =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return dates.any((d) => d.startsWith(iso));
  }

  @override
  Widget build(BuildContext context) {
    final currentStreak = _data?['current_streak'] as int? ?? 0;
    final maxStreak = _data?['max_streak'] as int? ?? 0;
    final recordedDays = _data?['this_month_recorded_days'] as int? ?? 0;
    final recordingRate =
        (_data?['this_month_recording_rate'] as num?)?.toDouble() ?? 0;
    final noSpendDays = _data?['this_month_no_spend_days'] as int? ?? 0;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: '연속 기록',
                            value: '$currentStreak일',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: '최고 기록',
                            value: '$maxStreak일',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: '이번 달 기록일',
                            value: '$recordedDays일',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: '이번 달 기록률',
                            value: '${recordingRate.toStringAsFixed(0)}%',
                          ),
                        ),
                      ],
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
          ],
        ),
      ),
    );
  }
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.text50, fontSize: 12)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
