import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../data/dutch_pay_service.dart';

/// 더치_005: 인원별 정산 요청(계좌+요청금액 복사·공유) 화면.
class DutchRequestScreen extends StatefulWidget {
  const DutchRequestScreen({super.key, this.sessionId, this.dutchPayService});

  final String? sessionId;
  final DutchPayService? dutchPayService;

  @override
  State<DutchRequestScreen> createState() => _DutchRequestScreenState();
}

class _DutchRequestScreenState extends State<DutchRequestScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = false;
  bool _isCompleting = false;
  String? _error;

  bool get _isLive => widget.dutchPayService != null && widget.sessionId != null;

  @override
  void initState() {
    super.initState();
    if (_isLive) {
      _isLoading = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final data = await widget.dutchPayService!.summary(widget.sessionId!);
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted) setState(() => _error = '정산 정보를 불러오지 못했습니다. 다시 시도해 주세요');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _requests {
    final list = (_data?['requests'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    if (list != null) return list;
    return const [
      {
        'participant_id': 'p2',
        'name': '철수',
        'amount': 14500,
        'message': '철수 님  14,500원',
      },
      {
        'participant_id': 'p3',
        'name': '영희',
        'amount': 14500,
        'message': '영희 님  14,500원',
      },
    ];
  }

  String get _bankLabel {
    final bankName = _data?['bank_name'] as String?;
    final account = _data?['bank_account_number'] as String?;
    if (bankName == null || account == null) return '계좌 정보를 등록해 주세요';
    return '$bankName $account';
  }

  Future<void> _editAccount() async {
    final bankNameController = TextEditingController(
      text: _data?['bank_name'] as String? ?? '',
    );
    final accountController = TextEditingController(
      text: _data?['bank_account_number'] as String? ?? '',
    );
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계좌 정보 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bankNameController,
              decoration: const InputDecoration(hintText: '은행명'),
            ),
            TextField(
              controller: accountController,
              decoration: const InputDecoration(hintText: '계좌번호'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (result != true || !mounted) return;
    if (!_isLive) {
      setState(() {
        _data = {
          ...?_data,
          'bank_name': bankNameController.text.trim(),
          'bank_account_number': accountController.text.trim(),
        };
      });
      return;
    }
    try {
      final updated = await widget.dutchPayService!.updateAccount(
        widget.sessionId!,
        bankName: bankNameController.text.trim(),
        bankAccountNumber: accountController.text.trim(),
      );
      if (mounted) {
        setState(() => _data = {...?_data, ...updated});
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _copy(String message) async {
    await Clipboard.setData(ClipboardData(text: message));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('메시지를 복사했어요')));
  }

  Future<void> _complete() async {
    if (!_isLive) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    setState(() {
      _isCompleting = true;
      _error = null;
    });
    try {
      final message = await widget.dutchPayService!.complete(widget.sessionId!);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isCompleting = false);
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
              '정산 요청',
              style: TextStyle(
                color: AppColors.text,
                fontFamily: 'BujangnimNunchi',
                fontSize: 75,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 337,
            child: _AccountCard(label: _bankLabel, onEdit: _editAccount),
          ),
          Positioned(
            left: 46,
            top: 701,
            child: Text(
              '요청할 인원 ${_requests.length}명',
              style: const TextStyle(color: Color(0x80E2E2F9), fontSize: 23),
            ),
          ),
          if (_isLoading)
            const Positioned(
              top: 800,
              width: 749,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.main),
              ),
            )
          else
            Positioned(
              left: 0,
              right: 0,
              top: 770,
              bottom: 210,
              child: SingleChildScrollView(
                child: _RequestPeople(requests: _requests, onCopy: _copy),
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
            child: GestureDetector(
              onTap: _isCompleting ? null : _complete,
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
                  _isCompleting ? '처리 중...' : '완료',
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

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.label, required this.onEdit});
  final String label;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Container(
    width: 749,
    height: 195,
    color: AppColors.secondary,
    child: Stack(
      children: [
        const Positioned(
          left: 46,
          top: 39,
          child: Text(
            '내 계좌',
            style: TextStyle(color: AppColors.text, fontSize: 23),
          ),
        ),
        Positioned(
          left: 38,
          top: 96,
          right: 130,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 40,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Positioned(
          left: 499,
          top: 92,
          child: GestureDetector(
            onTap: onEdit,
            child: SvgPicture.asset(AppAssets.editLight, width: 64, height: 64),
          ),
        ),
      ],
    ),
  );
}

class _RequestPeople extends StatelessWidget {
  const _RequestPeople({required this.requests, required this.onCopy});
  final List<Map<String, dynamic>> requests;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final request in requests)
        _RequestPerson(
          name: request['name'] as String? ?? '',
          amount: request['amount'] as int? ?? 0,
          onCopy: () => onCopy(
            request['message'] as String? ??
                '${request['name']} 님  ${_formatAmount(request['amount'] as int? ?? 0)}원',
          ),
        ),
    ],
  );
}

class _RequestPerson extends StatelessWidget {
  const _RequestPerson({
    required this.name,
    required this.amount,
    required this.onCopy,
  });

  final String name;
  final int amount;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => Container(
    width: 749,
    height: 148,
    color: AppColors.secondary,
    child: Stack(
      children: [
        Positioned(
          left: 46,
          top: 39,
          child: SvgPicture.asset(
            AppAssets.avatarSelected,
            width: 70,
            height: 70,
          ),
        ),
        Positioned(
          left: 138,
          top: 53,
          child: Text(
            name,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 30,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Positioned(right: 119, top: 48, child: _RequestAmount(value: amount)),
        Positioned(
          right: 46,
          top: 59,
          child: GestureDetector(
            onTap: onCopy,
            child: const Text(
              '복사',
              style: TextStyle(color: Color(0xCCE2E2F9), fontSize: 23),
            ),
          ),
        ),
      ],
    ),
  );
}

class _RequestAmount extends StatelessWidget {
  const _RequestAmount({required this.value});
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

String _formatAmount(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return '${amount < 0 ? '-' : ''}$buffer';
}
