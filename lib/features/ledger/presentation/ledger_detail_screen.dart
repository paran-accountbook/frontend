import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../shared/widgets/app_chevron.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/app_services.dart';
import '../../dutch/data/dutch_pay_service.dart';
import '../../dutch/presentation/dutch_people_screen.dart';
import '../../finance/data/finance_service.dart';
import 'ledger_edit_screen.dart';

class LedgerDetailScreen extends StatefulWidget {
  const LedgerDetailScreen({
    super.key,
    this.expenseId,
    this.financeService,
    this.dutchPayService,
  });
  final String? expenseId;
  final FinanceService? financeService;
  final DutchPayService? dutchPayService;

  @override
  State<LedgerDetailScreen> createState() => _LedgerDetailScreenState();
}

class _LedgerDetailScreenState extends State<LedgerDetailScreen> {
  Map<String, dynamic>? _data;
  late bool _isLoading;
  String? _error;
  bool _isStartingDutchPay = false;

  @override
  void initState() {
    super.initState();
    _isLoading = widget.expenseId != null && widget.financeService != null;
    _load();
  }

  Future<void> _load() async {
    final id = widget.expenseId;
    final service = widget.financeService;
    if (id == null || service == null) return;
    try {
      final data = await service.expenseDetail(id);
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted) setState(() => _error = '내역을 불러오지 못했습니다. 다시 시도해 주세요');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            Positioned(
              right: 24,
              top: 50,
              height: 36,
              child: OutlinedButton(
                onPressed: _isStartingDutchPay ? null : _startDutchPay,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.text20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  _isStartingDutchPay ? '불러오는 중...' : '더치페이 하기',
                  style: const TextStyle(color: AppColors.text, fontSize: 12),
                ),
              ),
            ),
            if (!_isLoading && (_data != null || widget.expenseId == null))
              Positioned(
                left: 24,
                top: 112,
                width: 354,
                height: 622,
                child: _ReceiptDetail(
                  data: _data,
                  onEdit: _data == null ? null : _openEdit,
                ),
              ),
            if (_isLoading)
              const Positioned(
                key: Key('ledger-detail-loading'),
                left: 24,
                top: 112,
                child: AppSkeletonReceipt(),
              ),
            if (_error case final message?)
              Positioned(
                left: 24,
                right: 24,
                top: 430,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFF6B7A),
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _startDutchPay() async {
    final id = widget.expenseId;
    if (id == null) return;
    final service = widget.dutchPayService ?? AppServices.dutchPay;
    setState(() => _isStartingDutchPay = true);
    try {
      final entry = await service.entry(id);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DutchPeopleScreen.fromEntry(
            entry: entry,
            dutchPayService: service,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isStartingDutchPay = false);
    }
  }

  Future<void> _openEdit() async {
    final id = widget.expenseId;
    final service = widget.financeService;
    final data = _data;
    if (id == null || service == null || data == null) return;
    final result = await Navigator.of(context).push<LedgerEditResult>(
      MaterialPageRoute<LedgerEditResult>(
        builder: (_) => LedgerEditScreen(
          expenseId: id,
          financeService: service,
          initialData: data,
        ),
      ),
    );
    if (!mounted) return;
    if (result == LedgerEditResult.deleted) {
      Navigator.of(context).pop(true);
      return;
    }
    if (result == LedgerEditResult.updated) await _load();
  }
}

class _ReceiptDetail extends StatelessWidget {
  const _ReceiptDetail({this.data, this.onEdit});
  final Map<String, dynamic>? data;
  final VoidCallback? onEdit;
  @override
  Widget build(BuildContext context) {
    final items = (data?['items'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    final visibleItems = items == null || items.isEmpty
        ? const [
            {'item_name': '아메리카노', 'quantity': 3, 'unit_price': 4500},
            {'item_name': '카페라떼', 'quantity': 1, 'unit_price': 4500},
            {'item_name': '아메리카노', 'quantity': 3, 'unit_price': 4500},
          ]
        : items;
    final receiptImageUrl = data?['receipt_image_url'] as String?;
    final hasReceiptImage =
        data == null || (receiptImageUrl != null && receiptImageUrl.isNotEmpty);
    return Stack(
      children: [
        Positioned.fill(
          child: SvgPicture.asset(
            AppAssets.homeReceiptCompact,
            fit: BoxFit.fill,
          ),
        ),
        Positioned(
          left: 17,
          right: 17,
          top: 30,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('총 ', style: _darkLabel),
                  Text(
                    _formatAmount(data?['total_amount'] as int? ?? 40500),
                    style: _darkAmount,
                  ),
                  const SizedBox(width: 4),
                  const Text('원', style: _darkLabel),
                ],
              ),
              const SizedBox(height: 20),
              const _DarkAsterisks(),
              const SizedBox(height: 16),
              _DetailRow(
                label: '가맹점 명',
                value: data?['store_name'] as String? ?? '아주대학교 카페',
              ),
              _DetailRow(
                label: '결제일시',
                value: _dateLabel(data?['paid_at'] as String?),
              ),
              _DetailRow(
                label: '카테고리',
                value: data?['category'] as String? ?? '식비',
              ),
              _DetailRow(
                label: '결제수단',
                value: data?['payment_method'] as String? ?? '현금',
              ),
              const SizedBox(height: 10),
              const _DarkAsterisks(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('품목   ${visibleItems.length}', style: _darkMuted),
                  GestureDetector(
                    key: const Key('edit-ledger-entry'),
                    onTap: onEdit,
                    behavior: HitTestBehavior.opaque,
                    child: const Row(
                      children: [
                        Text(
                          '수정',
                          style: TextStyle(color: AppColors.main, fontSize: 12),
                        ),
                        SizedBox(width: 2),
                        AppChevron(color: AppColors.main, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...visibleItems
                  .take(3)
                  .map(
                    (item) => _DetailItem(
                      name: item['item_name'] as String? ?? '품목',
                      quantity: item['quantity'] as int? ?? 1,
                      unitPrice: item['unit_price'] as int? ?? 0,
                    ),
                  ),
              if (hasReceiptImage) ...[
                const SizedBox(height: 8),
                const _DarkAsterisks(),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('소비사진  1', style: _darkMuted),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: _PhotoPlaceholder(),
                ),
                const SizedBox(height: 10),
              ],
              const _DarkAsterisks(),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('메모', style: _darkMuted),
                  Text(
                    data?['memo'] as String? ?? '과제하다가 친구랑 마심',
                    style: _darkLabel,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _darkLabel = TextStyle(
  color: Color(0xFF1B1B1B),
  fontSize: 12,
  fontWeight: FontWeight.w500,
);
const _darkMuted = TextStyle(color: Color(0x80121215), fontSize: 12);
const _darkAmount = TextStyle(
  color: Color(0xFF1B1B1B),
  fontFamily: 'Amarante',
  fontSize: 28,
);

class _DarkAsterisks extends StatelessWidget {
  const _DarkAsterisks();
  @override
  Widget build(BuildContext context) => Text(
    List.filled(18, '*').join('   '),
    maxLines: 1,
    style: const TextStyle(color: Color(0x33121215), fontSize: 10),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: _darkMuted),
        Text(value, style: _darkLabel),
      ],
    ),
  );
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });
  final String name;
  final int quantity;
  final int unitPrice;
  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0x0D121215))),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: _darkLabel),
              const SizedBox(height: 5),
              Text(
                '단가   ${_formatAmount(unitPrice)}원    ${_formatAmount(unitPrice * quantity)}원',
                style: _darkMuted,
              ),
            ],
          ),
        ),
        Text('$quantity개', style: _darkLabel),
      ],
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

String _dateLabel(String? raw) {
  final value = DateTime.tryParse(raw ?? '')?.toLocal();
  if (value == null) return '2026년 9월 1일 오후 3:20';
  final period = value.hour < 12 ? '오전' : '오후';
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  return '${value.year}년 ${value.month}월 ${value.day}일 $period $hour:${value.minute.toString().padLeft(2, '0')}';
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
    width: 50,
    height: 50,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.image, color: AppColors.main, size: 24),
  );
}
