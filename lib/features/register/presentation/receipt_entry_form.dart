import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_chevron.dart';

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
  late String _memo;
  late DateTime _paidAt;
  int? _editingItemIndex;

  @override
  void initState() {
    super.initState();
    final remoteItems = (widget.initialData?['items'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .map(Map<String, dynamic>.from)
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
      '현금' => 0,
      _ => widget.editable ? 2 : 0,
    };
    _storeName =
        widget.initialData?['store_name'] as String? ??
        (widget.editable ? '' : '아주대학교');
    _category = widget.initialData?['category'] as String? ?? '식비';
    _memo = widget.initialData?['memo'] as String? ?? '';
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
        if (widget.editable) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('품목 합계', style: _labelStyle),
              Text(
                '${_formatAmount(_itemsTotal)}원',
                key: const Key('receipt-items-total'),
                style: const TextStyle(
                  color: AppColors.text,
                  fontFamily: 'Amarante',
                  fontSize: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        if (widget.initialData?['is_duplicate'] == true) ...[
          const _RecognitionWarning('이미 등록된 영수증과 동일한 이미지예요.'),
          const SizedBox(height: 10),
        ],
        if (widget.initialData?['amount_mismatch'] == true) ...[
          const _RecognitionWarning('인식된 총액과 품목 합계가 달라요. 내용을 확인해 주세요.'),
          const SizedBox(height: 10),
        ],
        _InfoRow(
          label: '가맹점 명',
          value: _storeName.isEmpty ? '입력해 주세요' : _storeName,
          missing: _storeName.isEmpty,
          onTap: widget.editable ? _editStore : null,
        ),
        const SizedBox(height: 16),
        _InfoRow(
          label: '결제일시',
          value: _paidAtLabel,
          onTap: widget.editable ? _editPaidAt : null,
        ),
        if (widget.editable) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              _DateQuickChip(
                label: '오늘',
                onTap: () => _setQuickDate(DateTime.now()),
              ),
              const SizedBox(width: 8),
              _DateQuickChip(
                label: '어제',
                onTap: () => _setQuickDate(
                  DateTime.now().subtract(const Duration(days: 1)),
                ),
              ),
            ],
          ),
        ],
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
                    border: Border.all(
                      color: _paymentMethod == 2 && index == 2
                          ? const Color(0xFFCF376A)
                          : AppColors.outline,
                      width: 0.5,
                    ),
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
          GestureDetector(
            key: const Key('receipt-memo-field'),
            onTap: widget.editable ? _editMemo : null,
            behavior: HitTestBehavior.opaque,
            child: Container(
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
                    _memo.isEmpty ? '메모를 입력해 주세요' : _memo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text50,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
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
              key: Key('receipt-item-$index'),
              onDoubleTap: widget.editable
                  ? () => setState(() => _editingItemIndex = index)
                  : null,
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_editingItemIndex == index)
                    Focus(
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) {
                          _finishItemEditing(
                            index,
                            item['item_name'] as String? ?? '',
                          );
                        }
                      },
                      child: Column(
                        children: [
                          TextFormField(
                            key: Key('receipt-item-name-input-$index'),
                            initialValue: item['item_name'] as String? ?? '',
                            autofocus: true,
                            maxLines: 1,
                            textInputAction: TextInputAction.next,
                            style: _valueStyle,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                            ),
                            onChanged: (value) => item['item_name'] = value,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text('단가', style: _labelStyle),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 62,
                                child: TextFormField(
                                  key: Key('receipt-item-price-input-$index'),
                                  initialValue: unitPrice.toString(),
                                  // The numeric keypad has no Done key on iOS.
                                  // Keep digits-only input while exposing Return.
                                  keyboardType: TextInputType.text,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(9),
                                  ],
                                  textInputAction: TextInputAction.done,
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 12,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    suffixText: '원',
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (value) => setState(
                                    () => item['unit_price'] =
                                        int.tryParse(value) ?? 0,
                                  ),
                                  onFieldSubmitted: (_) => _finishItemEditing(
                                    index,
                                    item['item_name'] as String? ?? '',
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_formatAmount((item['unit_price'] as int? ?? 0) * _quantities[index])}원',
                                style: const TextStyle(
                                  color: AppColors.text50,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (item['item_name'] as String?)?.isNotEmpty == true
                              ? item['item_name'] as String
                              : '품목명을 입력해 주세요',
                          style:
                              (item['item_name'] as String?)?.isNotEmpty == true
                              ? _valueStyle
                              : const TextStyle(
                                  color: Color(0xFFFF9BB8),
                                  fontSize: 14,
                                ),
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

  int get _itemsTotal {
    var total = 0;
    for (var index = 0; index < _items.length; index++) {
      total += (_items[index]['unit_price'] as int? ?? 0) * _quantities[index];
    }
    return total;
  }

  void _setQuickDate(DateTime date) {
    final now = DateTime.now();
    final candidate = DateTime(
      date.year,
      date.month,
      date.day,
      _paidAt.hour,
      _paidAt.minute - (_paidAt.minute % 5),
    );
    setState(() => _paidAt = candidate.isAfter(now) ? now : candidate);
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

  void _finishItemEditing(int index, String value) {
    if (_editingItemIndex != index) return;
    _items[index]['item_name'] = value.trim();
    setState(() => _editingItemIndex = null);
    FocusScope.of(context).unfocus();
  }

  Future<void> _editMemo() async {
    var value = _memo;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메모 수정'),
        content: TextFormField(
          key: const Key('receipt-memo-input'),
          initialValue: _memo,
          autofocus: true,
          maxLength: 500,
          maxLines: 4,
          onChanged: (next) => value = next,
        ),
        actions: [
          if (_memo.isNotEmpty)
            TextButton(
              key: const Key('delete-receipt-memo'),
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('삭제'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, value.trim()),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (result != null && mounted) setState(() => _memo = result);
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

  Future<void> _editPaidAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final selected = await _showFiveMinutePicker(date);
    if (selected == null || !mounted) return;
    if (selected.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('미래 시각은 선택할 수 없습니다.')));
      return;
    }
    setState(() => _paidAt = selected);
  }

  Future<DateTime?> _showFiveMinutePicker(DateTime date) async {
    final now = DateTime.now();
    var initial = DateTime(
      date.year,
      date.month,
      date.day,
      _paidAt.hour,
      _paidAt.minute - (_paidAt.minute % 5),
    );
    if (initial.isAfter(now)) {
      initial = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute - (now.minute % 5),
      );
    }
    var value = initial;
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: AppColors.secondary,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: 320,
          child: Column(
            children: [
              SizedBox(
                height: 250,
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.dark,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: AppColors.text,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    key: const Key('receipt-five-minute-picker'),
                    mode: CupertinoDatePickerMode.time,
                    minuteInterval: 5,
                    initialDateTime: initial,
                    maximumDate:
                        date.year == now.year &&
                            date.month == now.month &&
                            date.day == now.day
                        ? now
                        : null,
                    onDateTimeChanged: (time) {
                      value = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    },
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, value),
                child: const Text('선택 완료'),
              ),
            ],
          ),
        ),
      ),
    );
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
      'paid_at': _paidAt.toUtc().toIso8601String(),
      'category': _category,
      'payment_method': const ['현금', '카드', '미지정'][_paymentMethod],
      'items': items,
      'memo': _memo.trim().isEmpty ? null : _memo.trim(),
      'source': source,
      // 등록_006: OCR 응답의 store_address를 저장 요청에 그대로 되돌려주면
      // 백엔드가 사업장 주소 기반 상호명 매칭에 사용한다.
      'store_address': widget.initialData?['store_address'],
      'receipt_image_path': widget.initialData?['receipt_image_path'],
      'receipt_image_hash': widget.initialData?['receipt_image_hash'],
    };
  }
}

class _DateQuickChip extends StatelessWidget {
  const _DateQuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: Key('receipt-date-$label'),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.selected,
        border: Border.all(color: AppColors.text20, width: .5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.text80, fontSize: 12),
      ),
    ),
  );
}

class _RecognitionWarning extends StatelessWidget {
  const _RecognitionWarning(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: 354,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0x22CF376A),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFCF376A)),
    ),
    child: Text(
      message,
      style: const TextStyle(color: Color(0xFFFF9BB8), fontSize: 12),
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

const _labelStyle = TextStyle(color: AppColors.text50, fontSize: 14);
const _valueStyle = TextStyle(
  color: AppColors.text,
  fontSize: 14,
  fontWeight: FontWeight.w500,
);

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.onTap,
    this.missing = false,
  });
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool missing;
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
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: missing
                          ? const TextStyle(
                              color: Color(0xFFFF9BB8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            )
                          : _valueStyle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const AppChevron(size: 20),
                ],
              ),
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
