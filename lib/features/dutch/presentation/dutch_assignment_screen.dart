import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../shared/widgets/p1_design_components.dart';
import '../data/dutch_pay_service.dart';
import 'dutch_result_screen.dart';

class DutchAssignmentScreen extends StatefulWidget {
  const DutchAssignmentScreen({
    super.key,
    this.sessionId,
    this.items = const [],
    this.participants = const [],
    this.initialAssignments = const [],
    this.dutchPayService,
    this.onNext,
  });
  final String? sessionId;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> participants;
  final List<Map<String, dynamic>> initialAssignments;
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

  bool get _isLive =>
      widget.dutchPayService != null && widget.sessionId != null;

  @override
  void initState() {
    super.initState();
    _items = widget.items.isNotEmpty
        ? widget.items
        : _isLive
        ? const []
        : const [
            {'id': 'demo-1', 'item_name': '커피', 'amount': 10000, 'quantity': 2},
            {'id': 'demo-2', 'item_name': '콜라', 'amount': 10000, 'quantity': 2},
          ];
    _participants = widget.participants.isNotEmpty
        ? widget.participants
        : _isLive
        ? const []
        : const [
            {'id': 'self', 'name': '나', 'is_self': true},
            {'id': 'p2', 'name': '철수', 'is_self': false},
            {'id': 'p3', 'name': '영희', 'is_self': false},
          ];
    for (final item in _items) {
      _assignments[item['id'] as String] = <String>{};
    }
    for (final assignment in widget.initialAssignments) {
      final itemId = assignment['expense_item_id'] as String?;
      if (itemId == null || !_assignments.containsKey(itemId)) continue;
      _assignments[itemId] =
          (assignment['participant_ids'] as List?)
              ?.whereType<String>()
              .toSet() ??
          <String>{};
    }
    if (widget.items.isEmpty && widget.participants.isEmpty) {
      _assignments['demo-1'] = {'self', 'p2'};
      _assignments['demo-2'] = {'self', 'p2', 'p3'};
    }
  }

  void _toggle(String itemId, String participantId) {
    setState(() {
      final selected = _assignments.putIfAbsent(itemId, () => <String>{});
      if (!selected.remove(participantId)) selected.add(participantId);
      _error = null;
    });
  }

  int get _assignedCount =>
      _assignments.values.where((value) => value.isNotEmpty).length;

  String? get _selfName {
    for (final participant in _participants) {
      if (participant['is_self'] == true) return participant['name'] as String?;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_assignedCount < _items.length) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('배정되지 않은 품목이 있어요'),
          content: const Text('배정되지 않은 품목을 남겨두고 계속할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('돌아가기'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('계속'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
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
      await widget.dutchPayService!.setAssignments(widget.sessionId!, [
        for (final item in _items)
          {
            'expense_item_id': item['id'],
            'participant_ids': (_assignments[item['id']] ?? const <String>{})
                .toList(),
          },
      ]);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DutchResultScreen(
            sessionId: widget.sessionId,
            dutchPayService: widget.dutchPayService,
            selfName: _selfName,
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
      child: Stack(
        children: [
          const ColoredBox(color: AppColors.background),
          P1ScreenHeader(
            title: '항목별 인원 배정',
            subtitle: '배정 완료 $_assignedCount/${_items.length} 품목',
          ),
          Positioned(
            left: 24,
            right: 24,
            top: 227,
            bottom: 112,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var index = 0; index < _items.length; index++) ...[
                    if (index > 0) const SizedBox(height: 26),
                    _AssignmentCard(
                      item: _items[index],
                      participants: _participants,
                      selected:
                          _assignments[_items[index]['id']] ?? const <String>{},
                      onToggle: (participantId) =>
                          _toggle(_items[index]['id'] as String, participantId),
                    ),
                  ],
                  if (_error case final message?) ...[
                    const SizedBox(height: 18),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Color(0xFFFF6B7A),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          P1BottomAction(
            label: _isSaving ? '저장 중...' : '다음',
            onTap: _isSaving ? null : _submit,
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
    final quantity = item['quantity'] as int? ?? 1;
    final perItem = quantity == 0 ? amount : amount ~/ quantity;
    final perPerson = selected.isEmpty ? 0 : amount ~/ selected.length;
    final remainder = selected.isEmpty ? 0 : amount % selected.length;
    final selectedParticipants = participants
        .where((participant) => selected.contains(participant['id']))
        .toList();
    final remainderParticipant =
        selectedParticipants
            .where((participant) => participant['is_self'] == true)
            .firstOrNull ??
        selectedParticipants.firstOrNull;
    return Column(
      children: [
        const P1AsteriskDivider(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['item_name'] as String? ?? '',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  '$quantity개 · 개당 ${formatP1Amount(perItem)}원',
                  style: const TextStyle(color: AppColors.text50, fontSize: 12),
                ),
              ],
            ),
            P1Amount(value: amount),
          ],
        ),
        const SizedBox(height: 12),
        for (final participant in participants)
          _ParticipantRow(
            name: participant['name'] as String? ?? '',
            checked: selected.contains(participant['id']),
            amount: selected.contains(participant['id'])
                ? perPerson +
                      (participant['id'] == remainderParticipant?['id']
                          ? remainder
                          : 0)
                : null,
            onTap: () => onToggle(participant['id'] as String),
          ),
        const SizedBox(height: 10),
        const Divider(height: 1, color: AppColors.text10),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${selected.length}명 선택 · 1인당',
              style: const TextStyle(color: AppColors.text50, fontSize: 12),
            ),
            const SizedBox(width: 20),
            Text(
              '${formatP1Amount(perPerson)}원',
              style: const TextStyle(color: AppColors.text, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.name,
    required this.checked,
    required this.amount,
    required this.onTap,
  });
  final String name;
  final bool checked;
  final int? amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: SizedBox(
      height: 50,
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: checked ? AppColors.main : AppColors.selected,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.text20),
            ),
            child: checked
                ? SvgPicture.asset(AppAssets.checkLight, width: 20, height: 14)
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: AppColors.text80,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (amount != null) P1Amount(value: amount!, color: AppColors.text50),
        ],
      ),
    ),
  );
}
