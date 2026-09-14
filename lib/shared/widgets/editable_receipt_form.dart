import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import 'app_chevron.dart';
import 'receipt_surface.dart';

class EditableReceiptForm extends StatefulWidget {
  const EditableReceiptForm({
    super.key,
    this.initialData,
    this.editable = false,
  });

  final Map<String, dynamic>? initialData;
  final bool editable;

  @override
  State<EditableReceiptForm> createState() => EditableReceiptFormState();
}

class EditableReceiptFormState extends State<EditableReceiptForm> {
  late String _storeName;
  late DateTime _paidAt;
  late String _category;
  late String _paymentMethod;
  late String _memo;
  late final List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _storeName = widget.initialData?['store_name'] as String? ?? '입력';
    _paidAt =
        DateTime.tryParse(
          widget.initialData?['paid_at'] as String? ?? '',
        )?.toLocal() ??
        DateTime(2026, 9, 1, 15, 20);
    _category = widget.initialData?['category'] as String? ?? '선택';
    _paymentMethod = widget.initialData?['payment_method'] as String? ?? '현금';
    _memo = widget.initialData?['memo'] as String? ?? '과제하다가 친구랑 마심';
    final remoteItems = (widget.initialData?['items'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .map(Map<String, dynamic>.from)
        .toList();
    _items = remoteItems == null || remoteItems.isEmpty
        ? [
            {'item_name': '아메리카노', 'quantity': 3, 'unit_price': 4500},
            {'item_name': '카페라떼', 'quantity': 1, 'unit_price': 4500},
            {'item_name': '아메리카노', 'quantity': 3, 'unit_price': 4500},
          ]
        : remoteItems;
  }

  int get _total => _items.fold(
    0,
    (sum, item) =>
        sum +
        (item['quantity'] as int? ?? 1) * (item['unit_price'] as int? ?? 0),
  );

  int get _photoCount {
    if (widget.initialData == null) return 4;
    final paths = widget.initialData?['receipt_image_paths'];
    if (paths is List) return paths.length.clamp(0, 4);
    final path = widget.initialData?['receipt_image_path'] as String?;
    return path == null || path.isEmpty ? 0 : 1;
  }

  @override
  Widget build(BuildContext context) => ReceiptSurface(
    width: 354,
    height: 657 + (_items.length * 72),
    startColor: const Color(0xFFFAFAFF),
    endColor: const Color(0xFFBCBCE4),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(17, 28, 17, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PaperDivider(),
          const SizedBox(height: 11),
          _TotalRow(total: _total),
          const SizedBox(height: 11),
          const _PaperDivider(),
          const SizedBox(height: 11),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                _FieldRow(
                  label: '가맹점 명',
                  value: _storeName,
                  onTap: widget.editable ? _editStore : null,
                ),
                const _FieldGap(),
                _FieldRow(
                  label: '결제일시',
                  value: _dateLabel(_paidAt),
                  onTap: widget.editable ? _editPaidAt : null,
                ),
                const _FieldGap(),
                _FieldRow(
                  label: '카테고리',
                  value: _category,
                  onTap: widget.editable ? _editCategory : null,
                ),
                const _FieldGap(),
                _FieldRow(
                  label: '결제수단',
                  value: _paymentMethod,
                  onTap: widget.editable ? _editPaymentMethod : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          const _PaperDivider(),
          const SizedBox(height: 11),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                _SectionHeader(
                  label: '품목',
                  count: _items.length,
                  action: '품목 추가 +',
                  onTap: widget.editable ? _addItem : null,
                ),
                const SizedBox(height: 16),
                ...List.generate(
                  _items.length,
                  (index) => _EditableItem(
                    item: _items[index],
                    editable: widget.editable,
                    onEdit: () => _editItem(index),
                    onIncrement: () => _changeQuantity(index, 1),
                    onDecrement: () => _changeQuantity(index, -1),
                    onRemove: () => _removeItem(index),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          const _PaperDivider(),
          const SizedBox(height: 11),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                _SectionHeader(
                  label: '소비사진',
                  count: _photoCount,
                  action: '(선택)',
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    ...List.generate(
                      _photoCount,
                      (_) => const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: _PhotoTile(),
                      ),
                    ),
                    if (_photoCount < 5) const _PhotoAddTile(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          const _PaperDivider(),
          const SizedBox(height: 11),
          GestureDetector(
            onTap: widget.editable ? _editMemo : null,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('메모', style: _paperMuted),
                      Text('(선택)', style: _paperAction),
                    ],
                  ),
                  const SizedBox(height: 11),
                  SizedBox(
                    height: 40,
                    child: Text(
                      _memo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _paperValue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Map<String, Object?>? buildUpdatePayload() {
    if (_storeName.trim().isEmpty || _items.isEmpty) return null;
    final items = <Map<String, Object?>>[];
    for (final item in _items) {
      final name = item['item_name'] as String? ?? '';
      final quantity = item['quantity'] as int? ?? 0;
      final unitPrice = item['unit_price'] as int? ?? 0;
      if (name.trim().isEmpty || quantity < 1 || unitPrice < 0) return null;
      items.add({
        'item_name': name.trim(),
        'quantity': quantity,
        'unit_price': unitPrice,
      });
    }
    return {
      'store_name': _storeName.trim(),
      'paid_at': _paidAt.toUtc().toIso8601String(),
      'category': _category == '선택' ? '기타' : _category,
      'payment_method': _paymentMethod,
      'items': items,
      'memo': _memo.trim().isEmpty ? null : _memo.trim(),
    };
  }

  Future<String?> _ask(String title, String initial) async {
    var value = initial;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          initialValue: initial,
          autofocus: true,
          onChanged: (next) => value = next,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, value.trim()),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _editStore() async {
    final value = await _ask('가맹점명', _storeName == '입력' ? '' : _storeName);
    if (value != null && value.isNotEmpty && mounted) {
      setState(() => _storeName = value);
    }
  }

  Future<void> _editMemo() async {
    final value = await _ask('메모', _memo);
    if (value != null && mounted) setState(() => _memo = value);
  }

  Future<void> _editPaidAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_paidAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _paidAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _editCategory() async {
    final value = await _selectOption(const [
      '식비',
      '카페',
      '쇼핑',
      '교통',
      '의료',
      '문화',
      '교육',
      '기타',
    ]);
    if (value != null && mounted) setState(() => _category = value);
  }

  Future<void> _editPaymentMethod() async {
    final value = await _selectOption(const ['현금', '카드', '미지정']);
    if (value != null && mounted) setState(() => _paymentMethod = value);
  }

  Future<String?> _selectOption(List<String> values) =>
      showModalBottomSheet<String>(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: values
                .map(
                  (value) => ListTile(
                    title: Text(value),
                    onTap: () => Navigator.pop(context, value),
                  ),
                )
                .toList(),
          ),
        ),
      );

  Future<void> _editItem(int index) async {
    final item = _items[index];
    final name = await _ask('품목명', item['item_name'] as String? ?? '');
    if (name == null || !mounted) return;
    final priceText = await _ask('단가', '${item['unit_price'] ?? 0}');
    final price = int.tryParse(priceText ?? '');
    if (price == null || price < 0 || !mounted) return;
    setState(() {
      item['item_name'] = name;
      item['unit_price'] = price;
    });
  }

  void _addItem() => setState(() {
    if (_items.length < 5) {
      _items.add({'item_name': '', 'quantity': 1, 'unit_price': 0});
    }
  });

  void _changeQuantity(int index, int delta) => setState(() {
    final quantity = _items[index]['quantity'] as int? ?? 1;
    _items[index]['quantity'] = (quantity + delta).clamp(1, 99);
  });

  void _removeItem(int index) => setState(() {
    if (_items.length > 1) _items.removeAt(index);
  });
}

class _PaperDivider extends StatelessWidget {
  const _PaperDivider();
  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset(AppAssets.receiptAsteriskDivider, width: 320, height: 7);
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.total});
  final int total;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 38,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '총',
          style: TextStyle(
            color: _paperText,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          _formatAmount(total),
          style: const TextStyle(
            color: _paperText,
            fontFamily: 'Amarante',
            fontSize: 30,
          ),
        ),
        const SizedBox(width: 4),
        SvgPicture.asset(AppAssets.wonDark, width: 19, height: 20),
      ],
    ),
  );
}

class _FieldGap extends StatelessWidget {
  const _FieldGap();
  @override
  Widget build(BuildContext context) => const Column(
    children: [
      SizedBox(height: 10),
      Divider(height: 1, thickness: 0.5, color: Color(0x331B1B1B)),
      SizedBox(height: 10),
    ],
  );
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.value, this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: SizedBox(
      height: 24,
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: _paperMuted)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _paperValue,
            ),
          ),
          const SizedBox(width: 6),
          const AppChevron(color: _paperText50, size: 24),
        ],
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    required this.action,
    this.onTap,
  });
  final String label;
  final int count;
  final String action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Text(label, style: _paperMuted),
          const SizedBox(width: 10),
          Text('$count', style: _paperValue),
        ],
      ),
      GestureDetector(
        onTap: onTap,
        child: Text(action, style: _paperAction),
      ),
    ],
  );
}

class _EditableItem extends StatelessWidget {
  const _EditableItem({
    required this.item,
    required this.editable,
    required this.onEdit,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });
  final Map<String, dynamic> item;
  final bool editable;
  final VoidCallback onEdit;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) {
    final quantity = item['quantity'] as int? ?? 1;
    final unitPrice = item['unit_price'] as int? ?? 0;
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x141B1B1B))),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: editable ? onEdit : null,
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['item_name'] as String? ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _paperValue,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    '단가   ${_formatAmount(unitPrice)}원   ${_formatAmount(unitPrice * quantity)}원',
                    style: const TextStyle(color: _paperText50, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          _RoundControl(
            asset: AppAssets.receiptAddItem,
            onTap: editable ? onIncrement : null,
          ),
          SizedBox(
            width: 34,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _paperText,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _RoundControl(
            asset: AppAssets.receiptRemoveItem,
            onTap: editable ? onDecrement : null,
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: editable ? onRemove : null,
            child: SvgPicture.asset(
              AppAssets.receiptDeleteItem,
              width: 24,
              height: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({required this.asset, this.onTap});
  final String asset;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x331B1B1B), width: 0.5),
      ),
      child: SvgPicture.asset(
        asset,
        colorFilter: const ColorFilter.mode(_paperText, BlendMode.srcIn),
      ),
    ),
  );
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile();
  @override
  Widget build(BuildContext context) => Container(
    width: 50,
    height: 50,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
    ),
    child: SvgPicture.asset(
      AppAssets.registerGallery,
      width: 28,
      height: 28,
      colorFilter: const ColorFilter.mode(AppColors.main, BlendMode.srcIn),
    ),
  );
}

class _PhotoAddTile extends StatelessWidget {
  const _PhotoAddTile();
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const _DashedBorderPainter(),
    child: SizedBox(
      width: 50,
      height: 50,
      child: Center(
        child: SvgPicture.asset(
          AppAssets.addPurple,
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(_paperText50, BlendMode.srcIn),
        ),
      ),
    ),
  );
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _paperText50
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(13)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, (distance + 5).clamp(0, metric.length)),
          paint,
        );
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}

const _paperText = Color(0xFF1B1B1B);
const _paperText50 = Color(0x801B1B1B);
const _paperMuted = TextStyle(
  color: _paperText50,
  fontSize: 14,
  fontWeight: FontWeight.w500,
);
const _paperValue = TextStyle(
  color: _paperText,
  fontSize: 14,
  fontWeight: FontWeight.w500,
);
const _paperAction = TextStyle(
  color: AppColors.main,
  fontSize: 14,
  fontWeight: FontWeight.w500,
);

String _formatAmount(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return '${amount < 0 ? '-' : ''}$buffer';
}

String _dateLabel(DateTime value) {
  final period = value.hour < 12 ? '오전' : '오후';
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  return '${value.year}년 ${value.month}월 ${value.day}일 $period $hour:${value.minute.toString().padLeft(2, '0')}';
}
