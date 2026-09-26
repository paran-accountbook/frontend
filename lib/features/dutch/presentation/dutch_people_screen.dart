import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../data/dutch_pay_service.dart';
import 'dutch_assignment_screen.dart';

/// 더치_002: 더치페이 인원 등록 화면.
class DutchPeopleScreen extends StatefulWidget {
  const DutchPeopleScreen({
    super.key,
    this.sessionId,
    this.selfNameSuggestion,
    this.items = const [],
    this.totalAmount = 0,
    this.dutchPayService,
    this.initialParticipants = const [],
    this.initialAssignments = const [],
    this.onNext,
  });

  factory DutchPeopleScreen.fromEntry({
    required Map<String, dynamic> entry,
    required DutchPayService dutchPayService,
  }) => DutchPeopleScreen(
    sessionId: entry['session_id'] as String?,
    selfNameSuggestion: entry['self_name_suggestion'] as String?,
    items:
        (entry['items'] as List?)?.whereType<Map<String, dynamic>>().toList() ??
        const [],
    totalAmount: entry['total_amount'] as int? ?? 0,
    initialParticipants:
        (entry['participants'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const [],
    initialAssignments:
        (entry['assignments'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const [],
    dutchPayService: dutchPayService,
  );

  /// 더치_001에서 발급받은 정산 세션 ID.
  final String? sessionId;

  /// 마이_001 닉네임 기준 본인 이름 제안값.
  final String? selfNameSuggestion;

  /// 정산 대상 품목 목록 (더치_001 진입 응답의 items).
  final List<Map<String, dynamic>> items;
  final int totalAmount;
  final DutchPayService? dutchPayService;
  final List<Map<String, dynamic>> initialParticipants;
  final List<Map<String, dynamic>> initialAssignments;

  /// 테스트/프리뷰용 오버라이드. 지정하지 않으면 실제 정산 흐름으로 다음 화면 이동.
  final VoidCallback? onNext;

  @override
  State<DutchPeopleScreen> createState() => _DutchPeopleScreenState();
}

class _DutchPeopleScreenState extends State<DutchPeopleScreen> {
  final _nameController = TextEditingController();
  final List<String> _names = [];
  List<String> _recentNames = const [];
  bool _isSaving = false;
  String? _error;
  bool _participantsChanged = false;
  late String _selfName;

  bool get _isLive =>
      widget.dutchPayService != null && widget.sessionId != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialParticipants.isNotEmpty) {
      _selfName =
          widget.initialParticipants
              .where((participant) => participant['is_self'] == true)
              .map((participant) => participant['name'] as String? ?? '')
              .firstOrNull ??
          '';
      _names.addAll(
        widget.initialParticipants
            .map((participant) => participant['name'] as String? ?? '')
            .where((name) => name.isNotEmpty),
      );
    } else {
      _selfName = (widget.selfNameSuggestion?.trim().isNotEmpty ?? false)
          ? widget.selfNameSuggestion!.trim()
          : _isLive
          ? '나 (본인)'
          : '홍길동 (본인)';
      _names.add(_selfName);
    }
    if (_isLive) {
      _loadRecentNames();
    } else {
      _names.addAll(const ['철수', '지은', '민수']);
      _recentNames = const ['영희', '민수', '철수', '지은'];
      _nameController.text = '현우';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentNames() async {
    try {
      final names = await widget.dutchPayService!.recentNames();
      if (mounted) setState(() => _recentNames = names);
    } catch (_) {
      // 최근 이름 추천은 부가 기능이므로 실패해도 화면을 막지 않는다.
    }
  }

  void _addName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    if (_names.contains(trimmed)) {
      setState(() => _error = '이미 등록된 이름입니다');
      return;
    }
    setState(() {
      _names.add(trimmed);
      _participantsChanged = true;
      _nameController.clear();
      _error = null;
    });
  }

  void _removeName(int index) {
    setState(() {
      _names.removeAt(index);
      _participantsChanged = true;
    });
  }

  Future<void> _editName(int index) async {
    final controller = TextEditingController(text: _names[index]);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이름 수정'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty || !mounted) return;
    if (_names.indexed.any((entry) => entry.$1 != index && entry.$2 == value)) {
      setState(() => _error = '이미 등록된 이름입니다');
      return;
    }
    setState(() {
      if (_names[index] == _selfName) _selfName = value;
      _names[index] = value;
      _participantsChanged = true;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_names.length < 2) {
      setState(() => _error = '본인 포함 최소 2명을 등록해 주세요');
      return;
    }
    if (widget.onNext case final callback?) {
      callback();
      return;
    }
    if (!_isLive) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const DutchAssignmentScreen()),
      );
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final participants =
          widget.initialParticipants.isNotEmpty && !_participantsChanged
          ? widget.initialParticipants
          : await widget.dutchPayService!.setParticipants(widget.sessionId!, [
              for (var i = 0; i < _names.length; i++)
                {'name': _names[i], 'is_self': _names[i] == _selfName},
            ]);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DutchAssignmentScreen(
            sessionId: widget.sessionId,
            items: widget.items,
            participants: participants,
            initialAssignments: _participantsChanged
                ? const []
                : widget.initialAssignments,
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        width: 749,
        height: 1628,
        child: Stack(
          children: [
            const ColoredBox(color: AppColors.background),
            Positioned(
              left: 32,
              top: 104,
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
              top: 227,
              child: Text(
                '인원 등록',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 50,
                ),
              ),
            ),
            const Positioned(
              left: 46,
              top: 324,
              child: Text(
                '인원을 추가하세요',
                style: TextStyle(color: Color(0xCCE2E2F9), fontSize: 30),
              ),
            ),
            Positioned(
              left: 46,
              top: 426,
              child: _NameInput(
                controller: _nameController,
                onSubmitted: _addName,
              ),
            ),
            Positioned(
              left: 46,
              top: 567,
              right: 46,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < _names.length; i++)
                    _PersonChip(
                      name: _names[i],
                      self: _names[i] == _selfName,
                      onEdit: () => _editName(i),
                      onRemove: () => _removeName(i),
                    ),
                ],
              ),
            ),
            if (_recentNames.isNotEmpty) ...[
              const Positioned(
                top: 1176,
                width: 749,
                child: Text(
                  '최근 정산에 사용한 이름',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0x80E2E2F9), fontSize: 23),
                ),
              ),
              Positioned(
                left: 46,
                right: 46,
                top: 1240,
                child: _RecentPeople(names: _recentNames, onSelected: _addName),
              ),
            ],
            if (_error case final message?)
              Positioned(
                left: 46,
                right: 46,
                top: 1400,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFF6B7A),
                    fontSize: 22,
                  ),
                ),
              ),
            Positioned(
              left: 46,
              top: 1451,
              child: GestureDetector(
                onTap: _isSaving ? null : _submit,
                child: Container(
                  width: 655,
                  height: 102,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.main,
                    borderRadius: BorderRadius.circular(37),
                    border: Border.all(color: const Color(0x4DE2E2F9)),
                  ),
                  child: Text(
                    _isSaving ? '저장 중...' : '정산하기',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameInput extends StatelessWidget {
  const _NameInput({required this.controller, required this.onSubmitted});
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) => Container(
    width: 655,
    height: 102,
    padding: const EdgeInsets.only(left: 36, right: 21),
    decoration: BoxDecoration(
      color: AppColors.selected,
      borderRadius: BorderRadius.circular(37),
      border: Border.all(color: AppColors.text20),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: '이름 입력',
              hintStyle: TextStyle(color: AppColors.text30, fontSize: 26),
            ),
            textInputAction: TextInputAction.done,
            maxLength: 20,
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => null,
            onSubmitted: onSubmitted,
          ),
        ),
        GestureDetector(
          onTap: () => onSubmitted(controller.text),
          child: SizedBox(
            width: 63,
            height: 63,
            child: Center(
              child: SvgPicture.asset(
                AppAssets.addPurple,
                width: 34,
                height: 34,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _PersonChip extends StatelessWidget {
  const _PersonChip({
    required this.name,
    this.self = false,
    this.onEdit,
    this.onRemove,
  });

  final String name;
  final bool self;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Container(
    height: 117,
    padding: EdgeInsets.only(left: self ? 45 : 26, right: 26),
    decoration: BoxDecoration(
      color: self ? AppColors.main : const Color(0x805E56FF),
      borderRadius: BorderRadius.circular(60),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!self)
          Padding(
            padding: const EdgeInsets.only(right: 11),
            child: SvgPicture.asset(
              AppAssets.avatarSelected,
              width: 63,
              height: 63,
            ),
          ),
        GestureDetector(
          onTap: onEdit,
          child: Text(
            name,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (self || onRemove != null) ...[
          const SizedBox(width: 11),
          GestureDetector(
            onTap: onRemove,
            child: SvgPicture.asset(
              AppAssets.closeLight,
              width: 45,
              height: 45,
            ),
          ),
        ],
      ],
    ),
  );
}

class _RecentPeople extends StatelessWidget {
  const _RecentPeople({required this.names, required this.onSelected});
  final List<String> names;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (var index = 0; index < names.length; index++) ...[
          if (index > 0) const SizedBox(width: 12),
          GestureDetector(
            onTap: () => onSelected(names[index]),
            child: _RecentChip(names[index]),
          ),
        ],
      ],
    ),
  );
}

class _RecentChip extends StatelessWidget {
  const _RecentChip(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => Container(
    height: 117,
    padding: const EdgeInsets.fromLTRB(14, 14, 30, 14),
    decoration: BoxDecoration(
      color: AppColors.selected,
      borderRadius: BorderRadius.circular(60),
      border: Border.all(color: AppColors.text20, width: .5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(AppAssets.avatarRecent, width: 63, height: 63),
        const SizedBox(width: 16),
        Text(
          name,
          style: const TextStyle(
            color: Color(0xCCE2E2F9),
            fontSize: 30,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
