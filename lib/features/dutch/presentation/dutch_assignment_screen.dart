import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../data/dutch_pay_service.dart';
import 'dutch_result_screen.dart';

/// 더치_003: 품목별 인원 배정 화면.
class DutchAssignmentScreen extends StatefulWidget {
  const DutchAssignmentScreen({
    super.key,
    this.sessionId,
    this.items = const [],
    this.participants = const [],
    this.dutchPayService,
    this.onNext,
  });

  final String? sessionId;

  /// 더치_001 응답의 items (id, item_name, amount).
  final List<Map<String, dynamic>> items;

  /// 더치_002에서 등록된 participants (id, name, is_self).
  final List<Map<String, dynamic>> participants;
  final DutchPayService? dutchPayService;
  final VoidCallback? onNext;

  @override
  State<DutchAssignmentScreen> createState() => _DutchAssignmentScreenState();
}

class _DutchAssignmentScreenState extends State<DutchAssignmentScreen> {
  late final List<Map<String, dynamic>> _items;
  late final List<Map<String, dynamic>> _participants;
  final Map<String, Set<String>> _assignments = {};
  bool _isSaving = false;
  String? _error;

  bool get _isLive => widget.dutchPayService != null && widget.sessionId != null;

  @override
  void initState() {
    super.initState();
    _items = widget.items.isNotEmpty
        ? widget.items
        : const [
            {'id': 'demo-1', 'item_name': '커피', 'amount': 34000},
            {'id': 'demo-2', 'item_name': '디저트', 'amount': 18000},
          ];
    _participants = widget.participants.isNotEmpty
        ? widget.participants
        : const [
            {'id': 'self', 'name': '나', 'is_self': true},
            {'id': 'p2', 'name': '철수', 'is_self': false},
            {'id': 'p3', 'name': '영희', 'is_self': false},
          ];
    for (final item in _items) {
      _assignments[item['id'] as String] = <String>{};
    }
  }

  void _toggle(String itemId, String participantId) {
    setState(() {
      final set = _assignments.putIfAbsent(itemId, () => <String>{});
      if (!set.remove(participantId)) set.add(participantId);
    });
  }

  int get _assignedCount =>
      _assignments.values.where((set) => set.isNotEmpty).length;

  Future<void> _submit() async {
    if (_assignedCount < _items.length) {
      setState(() => _error = '모든 품목에 인원을 배정해 주세요');
      return;
    }
    if (widget.onNext case final callback?) {
      callback();
      return;
    }
    if (!_isLive) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const DutchResultScreen()),
      );
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.dutchPayService!.setAssignments(
        widget.sessionId!,
        [
          for (final item in _items)
            {
              'expense_item_id': item['id'],
              'participant_ids': (_assignments[item['id']] ?? const <String>{})
                  .toList(),
            },
        ],
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DutchResultScreen(
            sessionId: widget.sessionId,
            dutchPayService: widget.dutchPayService,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DesignCanvas(
      width: 749,
      height: 1628,
      child: Stack(
        children: [
          const ColoredBox(color: AppColors.background),
          Positioned(
            left: 32,
            top: 133,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: SvgPicture.asset(
                AppAssets.arrowBackLight,
                width: 70,
                height: 70,
              ),
            ),
          ),
          const Positioned(
            left: 46,
            top: 214,
            child: Text(
              '항목별 인원 배정',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 75,
              ),
            ),
          ),
          Positioned(
            left: 46,
            top: 330,
            child: Text(
              '배정 완료 $_assignedCount/${_items.length} 품목',
              style: const TextStyle(color: Color(0xCCE2E2F9), fontSize: 30),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 420,
            bottom: 210,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final item in _items)
                    _AssignmentCard(
                      item: item,
                      participants: _participants,
                      selected:
                          _assignments[item['id']] ?? const <String>{},
                      onToggle: (participantId) =>
                          _toggle(item['id'] as String, participantId),
                    ),
                ],
              ),
            ),
          ),
          if (_error case final message?)
            Positioned(
              left: 46,
              right: 46,
              bottom: 190,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFF6B7A), fontSize: 22),
              ),
            ),
          Positioned(
            left: 46,
            top: 1466,
            child: Row(
              children: [
                _ActionButton(
                  label: '이전',
                  gradient: false,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 20),
                _ActionButton(
                  label: _isSaving ? '저장 중...' : '다음',
                  gradient: true,
                  onTap: _isSaving ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.item,
    required this.participants,
    required this.selected,
    required this.onToggle,
  });

  final Map<String, dynamic> item;
  final List<Map<String, dynamic>> participants;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final amount = item['amount'] as int? ?? 0;
    final perPerson = selected.isEmpty ? 0 : (amount / selected.length).round();
    return Container(
      width: 749,
      color: AppColors.secondary,
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(46, 17, 46, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['item_name'] as String? ?? '',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 50,
                  ),
                ),
                _Amount(value: amount, opacity: 1),
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (final participant in participants)
            _ParticipantRow(
              name: participant['name'] as String? ?? '',
              checked: selected.contains(participant['id']),
              onTap: () => onToggle(participant['id'] as String),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                '${selected.length}명 선택 · 1인당 ${_formatAmount(perPerson)}원',
                style: const TextStyle(color: Color(0x80E2E2F9), fontSize: 23),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.name,
    required this.checked,
    required this.onTap,
  });

  final String name;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: SizedBox(
      width: 749,
      height: 87,
      child: Stack(
        children: [
          Positioned(
            left: 46,
            top: 21,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: checked ? AppColors.main : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: const Color(0x4DE2E2F9)),
              ),
              child: checked
                  ? SvgPicture.asset(
                      AppAssets.checkLight,
                      width: 26.68,
                      height: 18.21,
                    )
                  : null,
            ),
          ),
          Positioned(
            left: 112,
            top: 24,
            child: Text(
              name,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 30,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Amount extends StatelessWidget {
  const _Amount({required this.value, required this.opacity});

  final int value;
  final double opacity;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: opacity,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatAmount(value),
          style: const TextStyle(
            color: AppColors.text,
            fontFamily: 'Amarante',
            fontSize: 40,
          ),
        ),
        const SizedBox(width: 5),
        SvgPicture.asset(AppAssets.wonLight, width: 29, height: 31),
      ],
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.gradient,
    this.onTap,
  });

  final String label;
  final bool gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 317.5,
      height: 102,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient
              ? const [Color(0xFF252552), AppColors.main]
              : const [AppColors.surface, Color(0xFF4E5058)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x4DE2E2F9)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

String _formatAmount(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return '${amount < 0 ? '-' : ''}$buffer';
}
