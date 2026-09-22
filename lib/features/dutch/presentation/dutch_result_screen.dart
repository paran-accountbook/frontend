import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../data/dutch_pay_service.dart';
import 'dutch_request_screen.dart';

/// 더치_004: 정산 결과 확인 화면.
class DutchResultScreen extends StatefulWidget {
  const DutchResultScreen({
    super.key,
    this.sessionId,
    this.dutchPayService,
    this.selfName,
    this.onNext,
  });

  final String? sessionId;
  final DutchPayService? dutchPayService;
  final String? selfName;
  final VoidCallback? onNext;

  @override
  State<DutchResultScreen> createState() => _DutchResultScreenState();
}

class _DutchResultScreenState extends State<DutchResultScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = false;
  String? _error;
  final Set<String> _expanded = {};

  bool get _isLive => widget.dutchPayService != null && widget.sessionId != null;

  @override
  void initState() {
    super.initState();
    if (_isLive) {
      _isLoading = true;
      _load();
    } else if (_participants.isNotEmpty) {
      _expanded.add(_participants.first['participant_id'] as String);
    }
  }

  Future<void> _load() async {
    try {
      final data = await widget.dutchPayService!.result(widget.sessionId!);
      final participants = (data['participants'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          const [];
      if (participants.isNotEmpty) {
        _expanded.add(participants.first['participant_id'] as String);
      }
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted) setState(() => _error = '정산 결과를 불러오지 못했습니다. 다시 시도해 주세요');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _participants {
    final list = (_data?['participants'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    if (list != null) return list;
    return const [
      {
        'participant_id': 'self',
        'name': '나',
        'amount': 14500,
        'items': [
          {'expense_item_id': '1', 'item_name': '김치찌개', 'share_amount': 12000},
          {'expense_item_id': '2', 'item_name': '콜라', 'share_amount': 2500},
        ],
      },
      {'participant_id': 'p2', 'name': '철수', 'amount': 14500, 'items': []},
      {'participant_id': 'p3', 'name': '영희', 'amount': 14500, 'items': []},
    ];
  }

  int get _totalAmount => _data?['total_amount'] as int? ?? 150000;

  void _toggleExpand(String id) {
    setState(() {
      if (!_expanded.remove(id)) _expanded.add(id);
    });
  }

  void _goNext() {
    if (widget.onNext case final callback?) {
      callback();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DutchRequestScreen(
          sessionId: widget.sessionId,
          dutchPayService: widget.dutchPayService,
        ),
      ),
    );
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
              '정산 결과 확인',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 75,
              ),
            ),
          ),
          Positioned(left: 0, top: 326, child: _ReceiptTotal(total: _totalAmount)),
          if (_isLoading)
            const Positioned(
              top: 620,
              width: 749,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.main),
              ),
            )
          else
            Positioned(
              left: 0,
              right: 0,
              top: 583,
              bottom: 210,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final participant in _participants)
                      _PersonResultCard(
                        name: participant['name'] as String? ?? '',
                        amount: participant['amount'] as int? ?? 0,
                        items: (participant['items'] as List?)
                                ?.whereType<Map<String, dynamic>>()
                                .toList() ??
                            const [],
                        self:
                            (widget.selfName != null &&
                                participant['name'] == widget.selfName),
                        expanded: _expanded.contains(
                          participant['participant_id'],
                        ),
                        onTap: () => _toggleExpand(
                          participant['participant_id'] as String,
                        ),
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
                _ActionButton(label: '다음', gradient: true, onTap: _goNext),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ReceiptTotal extends StatelessWidget {
  const _ReceiptTotal({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 749,
    height: 215,
    child: Stack(
      children: [
        const Positioned(left: 46, top: 0, child: _AsteriskDivider()),
        const Positioned(
          top: 50,
          width: 749,
          child: Text(
            '영수증 총액',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0x80E2E2F9), fontSize: 23),
          ),
        ),
        Positioned(
          top: 96,
          width: 749,
          child: Center(child: _TotalAmount(value: total)),
        ),
        const Positioned(left: 46, bottom: 0, child: _AsteriskDivider()),
      ],
    ),
  );
}

class _AsteriskDivider extends StatelessWidget {
  const _AsteriskDivider();

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    AppAssets.asteriskDividerDark,
    width: 657,
    height: 15,
    colorFilter: const ColorFilter.mode(Color(0xFFE2E2F9), BlendMode.srcIn),
  );
}

class _TotalAmount extends StatelessWidget {
  const _TotalAmount({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text(
        '총',
        style: TextStyle(
          color: AppColors.text,
          fontSize: 25,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(width: 5),
      Text(
        _formatAmount(value),
        style: const TextStyle(
          color: AppColors.text,
          fontFamily: 'Amarante',
          fontSize: 55,
        ),
      ),
      const SizedBox(width: 5),
      SvgPicture.asset(AppAssets.wonLight, width: 37, height: 40),
    ],
  );
}

class _PersonResultCard extends StatelessWidget {
  const _PersonResultCard({
    required this.name,
    required this.amount,
    required this.items,
    required this.expanded,
    required this.onTap,
    this.self = false,
  });

  final String name;
  final int amount;
  final List<Map<String, dynamic>> items;
  final bool expanded;
  final bool self;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      width: 749,
      color: AppColors.secondary,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          SizedBox(
            height: 148,
            child: Stack(
              children: [
                Positioned(
                  left: 46,
                  top: 42,
                  child: RotatedBox(
                    quarterTurns: expanded ? 2 : 0,
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: Center(
                        child: SvgPicture.asset(
                          AppAssets.arrowDown,
                          width: 34,
                          height: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 132,
                  top: 39,
                  child: SvgPicture.asset(
                    self ? AppAssets.avatarSelf : AppAssets.avatarSelected,
                    width: 70,
                    height: 70,
                  ),
                ),
                Positioned(
                  left: 224,
                  top: 34,
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Positioned(
                  left: 224,
                  top: 83,
                  child: Text(
                    '배정 품목 ${items.length}개',
                    style: const TextStyle(color: Color(0x80E2E2F9), fontSize: 23),
                  ),
                ),
                Positioned(
                  right: 46,
                  top: 48,
                  child: _ResultAmount(value: amount),
                ),
              ],
            ),
          ),
          if (expanded)
            for (final item in items)
              _ResultItem(
                name: item['item_name'] as String? ?? '',
                amount: item['share_amount'] as int? ?? 0,
              ),
        ],
      ),
    ),
  );
}

class _ResultItem extends StatelessWidget {
  const _ResultItem({required this.name, required this.amount});

  final String name;
  final int amount;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 749,
    height: 87,
    child: Stack(
      children: [
        Positioned(
          left: 46,
          top: 10,
          child: Text(
            name,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: 50,
            ),
          ),
        ),
        Positioned(
          right: 46,
          top: 19,
          child: Opacity(
            opacity: 0.5,
            child: _ResultAmount(value: amount),
          ),
        ),
      ],
    ),
  );
}

class _ResultAmount extends StatelessWidget {
  const _ResultAmount({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) => Row(
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
