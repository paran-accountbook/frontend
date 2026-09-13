import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';

class ReceiptEntryForm extends StatefulWidget {
  const ReceiptEntryForm({
    super.key,
    this.showMemo = false,
    this.initialData,
    this.editable = false,
  });
  final bool showMemo;
  final Map<String, dynamic>? initialData;
  final bool editable;
  @override
  State<ReceiptEntryForm> createState() => ReceiptEntryFormState();
}

class ReceiptEntryFormState extends State<ReceiptEntryForm> {
  late final List<Map<String, dynamic>> _items;
  late final List<int> _quantities;
  int _paymentMethod = 0;
  late String _storeName;
  late String _category;
  late DateTime _paidAt;

  @override
  void initState() {
    super.initState();
    final remoteItems = (widget.initialData?['items'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    _items = remoteItems == null || remoteItems.isEmpty
        ? widget.editable
              ? [
                  <String, dynamic>{
                    'item_name': '',
                    'quantity': 1,
                    'unit_price': 0,
                  },
                ]
              : List.generate(
                  3,
                  (_) => {
                    'item_name': '아메리카노',
                    'quantity': 3,
                    'unit_price': 4500,
                  },
                )
        : remoteItems;
    _quantities = _items.map((item) => item['quantity'] as int? ?? 1).toList();
    _paymentMethod = switch (widget.initialData?['payment_method']) {
      '카드' => 1,
      '미지정' => 2,
      _ => 0,
    };
    _storeName =
        widget.initialData?['store_name'] as String? ??
        (widget.editable ? '' : '아주대학교');
    _category = widget.initialData?['category'] as String? ?? '식비';
    _paidAt =
        DateTime.tryParse(
          widget.initialData?['paid_at'] as String? ?? '',
        )?.toLocal() ??
        (widget.editable ? DateTime.now() : DateTime(2026, 9, 1, 15, 20));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoRow(
          label: '가맹점 명',
          value: _storeName.isEmpty ? '입력해 주세요' : _storeName,
          onTap: widget.editable ? _editStore : null,
        ),
        const SizedBox(height: 16),
        _InfoRow(label: '결제일시', value: _paidAtLabel),
        const SizedBox(height: 16),
        _InfoRow(
          label: '카테고리',
          value: _category,
          onTap: widget.editable ? _selectCategory : null,
        ),
        const SizedBox(height: 25),
        const _Asterisks(),
        const SizedBox(height: 20),
        Row(
          children: List.generate(
            3,
            (index) => Padding(
              padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
              child: GestureDetector(
                onTap: () => setState(() => _paymentMethod = index),
                child: Container(
                  width: index == 2 ? 92 : 79,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _paymentMethod == index
                        ? const Color(0xFFA8A3FF)
                        : AppColors.selected,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.outline, width: 0.5),
                  ),
                  child: Text(
                    const ['현금', '카드', '미지정'][index],
                    style: TextStyle(
                      color: _paymentMethod == index
                          ? const Color(0xFF1B1B1B)
                          : AppColors.text50,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 31),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('품목   ${_items.length}', style: _labelStyle),
            GestureDetector(
              onTap: widget.editable ? _addItem : null,
              child: const Text(
                '품목 추가 +',
                style: TextStyle(color: Color(0xFFA8A3FF), fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        ...List.generate(_items.length, _buildItem),
        if (widget.showMemo) ...[
          const SizedBox(height: 20),
          Container(
            width: 354,
            height: 91,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF191A1F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('메모 (선택)', style: _valueStyle),
                const SizedBox(height: 8),
                Text(
                  widget.initialData?['memo'] as String? ?? '안녕하세요',
                  style: const TextStyle(color: AppColors.text50, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildItem(int index) {
    final item = _items[index];
    final unitPrice = item['unit_price'] as int? ?? 0;
    return Container(
      width: 354,
      height: 72,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x0DE2E2F9))),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: widget.editable ? () => _editItem(index) : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['item_name'] as String? ?? '품목',
                    style: _valueStyle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '단가   ${_formatAmount(unitPrice)}원   ${_formatAmount(unitPrice * _quantities[index])}원',
                    style: const TextStyle(
                      color: AppColors.text50,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _RoundControl(
            asset: AppAssets.receiptAddItem,
            onTap: () => setState(() => _quantities[index]++),
          ),
          SizedBox(
            width: 34,
            child: Text(
              _quantities[index].toString(),
              textAlign: TextAlign.center,
              style: _valueStyle,
            ),
          ),
          _RoundControl(
            asset: AppAssets.receiptRemoveItem,
            onTap: () => setState(() {
              if (_quantities[index] > 1) _quantities[index]--;
            }),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: widget.editable && _items.length > 1
                ? () => setState(() {
                    _items.removeAt(index);
                    _quantities.removeAt(index);
                  })
                : null,
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

  String get _paidAtLabel {
    final local = _paidAt;
    final period = local.hour < 12 ? '오전' : '오후';
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    return '${local.year}년 ${local.month}월 ${local.day}일 $period $hour:${local.minute.toString().padLeft(2, '0')}';
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
    final value = await _ask('가맹점명', _storeName);
    if (value != null) setState(() => _storeName = value);
  }

  Future<void> _editItem(int index) async {
    final name = await _ask('품목명', _items[index]['item_name'] as String? ?? '');
    if (name == null) return;
    final priceText = await _ask('단가', '${_items[index]['unit_price'] ?? 0}');
    final price = int.tryParse(priceText ?? '');
    if (price == null) return;
    setState(() {
      _items[index]['item_name'] = name;
      _items[index]['unit_price'] = price;
    });
  }

  Future<void> _selectCategory() async {
    const categories = ['식비', '카페', '쇼핑', '교통', '의료', '문화', '교육', '기타'];
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: categories
              .map(
                (item) => ListTile(
                  title: Text(item),
                  onTap: () => Navigator.pop(context, item),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (value != null) setState(() => _category = value);
  }

  void _addItem() {
    setState(() {
      _items.add({'item_name': '', 'quantity': 1, 'unit_price': 0});
      _quantities.add(1);
    });
  }

  Map<String, Object?>? buildPayload({required String source}) {
    if (_storeName.trim().isEmpty) return null;
    final items = <Map<String, Object?>>[];
    for (var index = 0; index < _items.length; index++) {
      final name = _items[index]['item_name'] as String? ?? '';
      final price = _items[index]['unit_price'] as int? ?? 0;
      if (name.trim().isEmpty || price == 0) return null;
      items.add({
        'item_name': name.trim(),
        'quantity': _quantities[index],
        'unit_price': price,
      });
    }
    return {
      'store_name': _storeName.trim(),
      'paid_at': _paidAt.toIso8601String(),
      'category': _category,
      'payment_method': const ['현금', '카드', '미지정'][_paymentMethod],
      'items': items,
      'memo': widget.initialData?['memo'],
      'source': source,
      'receipt_image_path': widget.initialData?['receipt_image_path'],
      'receipt_image_hash': widget.initialData?['receipt_image_hash'],
    };
  }
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

const _labelStyle = TextStyle(color: AppColors.text50, fontSize: 14);
const _valueStyle = TextStyle(
  color: AppColors.text,
  fontSize: 14,
  fontWeight: FontWeight.w500,
);

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 28,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: _labelStyle),
            Row(
              children: [
                Text(value, style: _valueStyle),
                const SizedBox(width: 6),
                const Text(
                  '〉',
                  style: TextStyle(color: AppColors.text, fontSize: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Asterisks extends StatelessWidget {
  const _Asterisks();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 354,
      child: Text(
        List.filled(18, '*').join('   '),
        maxLines: 1,
        style: const TextStyle(color: AppColors.text20, fontSize: 11),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({required this.asset, required this.onTap});
  final String asset;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.selected,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.outline, width: 0.5),
        ),
        child: SvgPicture.asset(asset),
      ),
    );
  }
}
