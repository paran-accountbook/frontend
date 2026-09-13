import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_assets.dart';
import 'receipt_surface.dart';

class EditableReceiptForm extends StatefulWidget {
  const EditableReceiptForm({
    super.key,
    this.income = false,
    this.draft = false,
    this.compact = false,
    this.initialData,
    this.editable = false,
  });

  final bool income;
  final bool draft;
  final bool compact;
  final Map<String, dynamic>? initialData;
  final bool editable;

  @override
  State<EditableReceiptForm> createState() => EditableReceiptFormState();
}

class EditableReceiptFormState extends State<EditableReceiptForm> {
  late String _storeName;
  late DateTime _paidAt;
  late final List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _storeName =
        widget.initialData?['store_name'] as String? ??
        (widget.income ? '수입처를 입력하세요' : (widget.draft ? '소비로그' : '아주대학교 카페'));
    _paidAt =
        DateTime.tryParse(
          widget.initialData?['paid_at'] as String? ?? '',
        )?.toLocal() ??
        DateTime(2026, 8, 19, 10, 30);
    final remoteItems = (widget.initialData?['items'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    _items = remoteItems == null || remoteItems.isEmpty
        ? List.generate(
            widget.income ? 1 : 5,
            (_) => {
              'item_name': '커피',
              'quantity': 1,
              'unit_price': widget.draft || widget.income ? 0 : 150000,
            },
          )
        : remoteItems;
  }

  @override
  Widget build(BuildContext context) {
    final paperWidth = widget.compact ? 657.0 : 683.0;
    final paperHeight = widget.compact ? 1130.0 : 1174.0;
    final contentOffset = widget.compact ? -13.0 : 0.0;
    final total = widget.initialData == null
        ? (widget.income || widget.draft ? 0 : 150000)
        : _items.fold<int>(
            0,
            (sum, item) =>
                sum +
                (item['quantity'] as int? ?? 1) *
                    (item['unit_price'] as int? ?? 0),
          );

    return ReceiptSurface(
      width: paperWidth,
      height: paperHeight,
      startColor: widget.compact ? const Color(0xFFFAFAFF) : Colors.white,
      endColor: widget.compact
          ? const Color(0xFFBCBCE4)
          : const Color(0xFFC5C5ED),
      child: Stack(
        children: [
          Positioned(
            left: widget.compact ? 51 : 53,
            top: widget.compact ? 67 : 70,
            child: _PaperAsterisks(width: widget.compact ? 555 : 577),
          ),
          Positioned(
            top: 115,
            width: paperWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '총',
                  style: TextStyle(
                    color: Color(0xFF1B1B1B),
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  _formatAmount(total),
                  style: const TextStyle(
                    color: Color(0xFF1B1B1B),
                    fontFamily: 'Amarante',
                    fontSize: 52,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 7),
                SvgPicture.asset(AppAssets.wonDark, width: 36, height: 39),
              ],
            ),
          ),
          Positioned(
            left: widget.compact ? -12.5 : 1,
            top: 205,
            child: _FieldRow(
              width: 682,
              label: '가맹점 명',
              value: _storeName,
              onTap: widget.editable ? _editStore : null,
            ),
          ),
          Positioned(
            left: widget.compact ? -12.5 : 1,
            top: 280,
            child: _FieldRow(
              width: 682,
              label: '결제일시',
              value: _dateLabel(_paidAt),
              onTap: widget.editable ? _editPaidAt : null,
            ),
          ),
          Positioned(
            left: widget.compact ? 51 : 53,
            top: widget.compact ? 362 : 366,
            child: _PaperAsterisks(width: widget.compact ? 555 : 577),
          ),
          Positioned(
            top: 416,
            width: paperWidth,
            child: Center(
              child: _AddButton(onTap: widget.editable ? _addItem : null),
            ),
          ),
          Positioned(
            left: contentOffset,
            top: 521,
            child: _EditableItems(
              items: _items,
              editable: widget.editable,
              onEdit: _editItem,
              onRemove: _removeItem,
            ),
          ),
        ],
      ),
    );
  }

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
      'category': widget.initialData?['category'] ?? '기타',
      'payment_method': widget.initialData?['payment_method'] ?? '미지정',
      'items': items,
      'memo': widget.initialData?['memo'],
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
    final value = await _ask('가맹점명', _storeName);
    if (value != null && mounted) setState(() => _storeName = value);
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

  void _removeItem(int index) => setState(() {
    if (_items.length > 1) _items.removeAt(index);
  });
}

class _PaperAsterisks extends StatelessWidget {
  const _PaperAsterisks({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          18,
          (_) => const Text(
            '*',
            style: TextStyle(color: Color(0x331B1B1B), fontSize: 20),
          ),
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.width,
    required this.label,
    required this.value,
    this.onTap,
  });

  final double width;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: 66,
        child: Stack(
          children: [
            Positioned(
              left: 51,
              top: 15,
              child: Text(
                label,
                style: const TextStyle(color: Color(0x801B1B1B), fontSize: 23),
              ),
            ),
            Positioned(
              right: 105,
              top: 16,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF1B1B1B),
                  fontSize: 23,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Positioned(right: 38, top: 10, child: _CloseIcon(onTap: onTap)),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B1B),
          borderRadius: BorderRadius.circular(20),
        ),
        child: SvgPicture.asset(AppAssets.addLight, width: 28, height: 28),
      ),
    );
  }
}

class _EditableItems extends StatelessWidget {
  const _EditableItems({
    required this.items,
    required this.editable,
    required this.onEdit,
    required this.onRemove,
  });

  final List<Map<String, dynamic>> items;
  final bool editable;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 683,
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return _EditableItem(
            name: item['item_name'] as String? ?? '',
            quantity: item['quantity'] as int? ?? 1,
            unitPrice: item['unit_price'] as int? ?? 0,
            onTap: editable ? () => onEdit(index) : null,
            onRemove: editable ? () => onRemove(index) : null,
          );
        }),
      ),
    );
  }
}

class _EditableItem extends StatelessWidget {
  const _EditableItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.onTap,
    this.onRemove,
  });

  final String name;
  final int quantity;
  final int unitPrice;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 148,
        child: Stack(
          children: [
            const Positioned(
              left: 49,
              top: 0,
              child: SizedBox(
                width: 585,
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0x141B1B1B),
                ),
              ),
            ),
            Positioned(
              left: 49,
              top: 27,
              child: Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF1B1B1B),
                  fontFamily: 'BujangnimNunchi',
                  fontSize: 50,
                ),
              ),
            ),
            Positioned(
              left: 49,
              top: 85,
              child: Text(
                'X $quantity',
                style: const TextStyle(color: Color(0x801B1B1B), fontSize: 23),
              ),
            ),
            Positioned(
              right: 108,
              top: 49,
              child: Row(
                children: [
                  Text(
                    _formatAmount(unitPrice * quantity),
                    style: const TextStyle(
                      color: Color(0xFF1B1B1B),
                      fontFamily: 'Amarante',
                      fontSize: 40,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SvgPicture.asset(AppAssets.wonDark, width: 29, height: 31),
                ],
              ),
            ),
            Positioned(right: 39, top: 51, child: _CloseIcon(onTap: onRemove)),
          ],
        ),
      ),
    );
  }
}

class _CloseIcon extends StatelessWidget {
  const _CloseIcon({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SvgPicture.asset(AppAssets.closeDark, width: 46, height: 46),
    );
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

String _dateLabel(DateTime value) {
  final period = value.hour < 12 ? '오전' : '오후';
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  return '${value.year}년 ${value.month}월 ${value.day}일 $period $hour:${value.minute.toString().padLeft(2, '0')}';
}
