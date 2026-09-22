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
    this.onNext,
  });

  /// 더치_001에서 발급받은 정산 세션 ID.
  final String? sessionId;

  /// 마이_001 닉네임 기준 본인 이름 제안값.
  final String? selfNameSuggestion;

  /// 정산 대상 품목 목록 (더치_001 진입 응답의 items).
  final List<Map<String, dynamic>> items;
  final int totalAmount;
  final DutchPayService? dutchPayService;

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

  bool get _isLive => widget.dutchPayService != null && widget.sessionId != null;

  @override
  void initState() {
    super.initState();
    _names.add(
      (widget.selfNameSuggestion?.trim().isNotEmpty ?? false)
          ? widget.selfNameSuggestion!.trim()
          : '나 (본인)',
    );
    if (_isLive) {
      _loadRecentNames();
    } else {
      _recentNames = const ['철수', '영희', '지은', '민수'];
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
    if (_names.contains(trimmed)) return;
    setState(() {
      _names.add(trimmed);
      _nameController.clear();
      _error = null;
    });
  }

  void _removeName(int index) {
    if (index == 0) return; // 본인은 제거할 수 없다.
    setState(() => _names.removeAt(index));
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
      final participants = await widget.dutchPayService!.setParticipants(
        widget.sessionId!,
        [
          for (var i = 0; i < _names.length; i++)
            {'name': _names[i], 'is_self': i == 0},
        ],
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DutchAssignmentScreen(
            sessionId: widget.sessionId,
            items: widget.items,
            participants: participants,
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
                '인원 등록',
                style: TextStyle(
                  color: AppColors.text,
                  fontFamily: 'BujangnimNunchi',
                  fontSize: 75,
                ),
              ),
            ),
            const Positioned(
              left: 46,
              top: 330,
              child: Text(
                '인원을 추가하세요',
                style: TextStyle(color: Color(0xCCE2E2F9), fontSize: 30),
              ),
            ),
            Positioned(
              left: 58,
              top: 419,
              child: _NameInput(
                controller: _nameController,
                onSubmitted: _addName,
              ),
            ),
            Positioned(
              left: 46,
              top: 582,
              right: 46,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < _names.length; i++)
                    _PersonChip(
                      name: _names[i],
                      self: i == 0,
                      onRemove: i == 0 ? null : () => _removeName(i),
                    ),
                ],
              ),
            ),
            if (_recentNames.isNotEmpty) ...[
              const Positioned(
                top: 1217,
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
                top: 1288,
                child: _RecentPeople(
                  names: _recentNames,
                  onSelected: _addName,
                ),
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
                  style: const TextStyle(color: Color(0xFFFF6B7A), fontSize: 22),
                ),
              ),
            Positioned(
              left: 46,
              top: 1466,
              child: GestureDetector(
                onTap: _isSaving ? null : _submit,
                child: Container(
                  width: 655,
                  height: 102,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF252552), AppColors.main],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0x4DE2E2F9)),
                  ),
                  child: Text(
                    _isSaving ? '저장 중...' : '정산하기',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
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
    width: 633,
    height: 102,
    padding: const EdgeInsets.only(left: 36, right: 21),
    decoration: BoxDecoration(
      color: AppColors.secondary,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: '이름 입력',
              hintStyle: TextStyle(color: AppColors.text30, fontSize: 30),
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
          child: Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B1B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: SvgPicture.asset(AppAssets.addPurple, width: 28, height: 28),
          ),
        ),
      ],
    ),
  );
}

class _PersonChip extends StatelessWidget {
  const _PersonChip({required this.name, this.self = false, this.onRemove});

  final String name;
  final bool self;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Container(
    height: 102,
    padding: EdgeInsets.only(left: self ? 36 : 14, right: 22),
    decoration: BoxDecoration(
      color: self ? const Color(0xFF6456FF) : const Color(0x803D3592),
      borderRadius: BorderRadius.circular(60),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!self)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SvgPicture.asset(
              AppAssets.avatarSelected,
              width: 70,
              height: 70,
            ),
          ),
        Text(
          name,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 30,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (onRemove != null) ...[
          const SizedBox(width: 14),
          GestureDetector(
            onTap: onRemove,
            child: SvgPicture.asset(
              AppAssets.closeLight,
              width: 30,
              height: 30,
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
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      for (final name in names)
        GestureDetector(
          onTap: () => onSelected(name),
          child: _RecentChip(name),
        ),
    ],
  );
}

class _RecentChip extends StatelessWidget {
  const _RecentChip(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => Container(
    height: 98,
    padding: const EdgeInsets.fromLTRB(14, 14, 30, 14),
    decoration: BoxDecoration(
      color: AppColors.selected,
      borderRadius: BorderRadius.circular(60),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(AppAssets.avatarRecent, width: 70, height: 70),
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
