import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_chevron.dart';
import '../../category/data/category_models.dart';
import '../../category/data/category_service.dart';
import '../../finance/data/payment_methods.dart';

class ReceiptEntryForm extends StatefulWidget {
  const ReceiptEntryForm({
    super.key,
    this.showMemo = false,
    this.initialData,
    this.editable = false,
    this.lightReceipt = false,
    this.originalReceipt,
    this.trailingInset = 0,
    this.photos,
  });
  final bool showMemo;
  final Map<String, dynamic>? initialData;
  final bool editable;
  final bool lightReceipt;
  final Widget? originalReceipt;
  final double trailingInset;
  final Widget? photos;
  @override
  State<ReceiptEntryForm> createState() => ReceiptEntryFormState();
}

class ReceiptEntryFormState extends State<ReceiptEntryForm> {
  late final List<Map<String, dynamic>> _items;
  late final List<int> _quantities;
  late String _paymentMethod;
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
                    'unit_price': null,
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
    _paymentMethod = normalizePaymentMethod(
      widget.initialData?['payment_method'] as String?,
    );
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
    final inset = EdgeInsets.only(right: widget.trailingInset);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: inset,
          child: Column(
            children: [
              if (widget.editable) ...[
                if (!widget.lightReceipt) ...[
                  const SizedBox(height: 25),
                  const _Asterisks(lightReceipt: false),
                  const SizedBox(height: 26),
                ],
                _buildTotal(),
                const SizedBox(height: 14),
                if (widget.lightReceipt) ...[
                  const _Asterisks(lightReceipt: true),
                  const SizedBox(height: 12),
                ],
                ?widget.originalReceipt,
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
                lightReceipt: widget.lightReceipt,
                label: '가맹점 명',
                value: _storeName.isEmpty ? '입력해 주세요' : _storeName,
                missing: _storeName.isEmpty,
                onTap: widget.editable ? _editStore : null,
              ),
              const SizedBox(height: 16),
              _InfoRow(
                lightReceipt: widget.lightReceipt,
                label: '결제일시',
                value: _paidAtLabel,
                onTap: widget.editable ? _editPaidAt : null,
              ),
              if (widget.editable && !widget.lightReceipt) ...[
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
                lightReceipt: widget.lightReceipt,
                label: '카테고리',
                value: _category,
                onTap: widget.editable ? _selectCategory : null,
              ),
              if (widget.lightReceipt) ...[
                const SizedBox(height: 16),
                _InfoRow(
                  key: const Key('receipt-payment-method-row'),
                  lightReceipt: true,
                  label: '결제수단',
                  value: _paymentMethod,
                  onTap: widget.editable ? _selectPaymentMethod : null,
                ),
              ],
              const SizedBox(height: 25),
              _Asterisks(lightReceipt: widget.lightReceipt),
            ],
          ),
        ),
        if (!widget.lightReceipt) ...[
          const SizedBox(height: 20),
          SingleChildScrollView(
            key: const Key('receipt-payment-method-scroll'),
            scrollDirection: Axis.horizontal,
            padding: inset,
            child: Row(
              spacing: 8,
              children: _paymentOptions(
                widget.editable
                    ? (method) => setState(() => _paymentMethod = method)
                    : null,
              ),
            ),
          ),
        ],
        SizedBox(height: widget.lightReceipt ? 20 : 31),
        Padding(
          padding: inset,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text.rich(
                    TextSpan(
                      text: '품목  ',
                      children: [
                        TextSpan(
                          text: '${_items.length}',
                          style: _receiptValue,
                        ),
                      ],
                    ),
                    style: _receiptLabel,
                  ),
                  GestureDetector(
                    onTap: widget.editable ? _addItem : null,
                    child: Text(
                      '품목 추가 +',
                      style: _receiptValue.copyWith(color: _accent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(_items.length, _buildItem),
              if (widget.photos case final photos?) ...[
                SizedBox(height: widget.lightReceipt ? 16 : 10),
                photos,
              ],
              if (widget.showMemo) ...[
                const SizedBox(height: 26),
                GestureDetector(
                  key: const Key('receipt-memo-field'),
                  onTap: widget.editable ? _editMemo : null,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 354,
                    height: 98,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    decoration: BoxDecoration(
                      color: widget.lightReceipt
                          ? Colors.white.withValues(alpha: .64)
                          : AppColors.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: '메모 ',
                            children: [
                              TextSpan(
                                text: '(선택)',
                                style: TextStyle(color: _accent),
                              ),
                            ],
                          ),
                          style: _receiptValue.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _memo.isEmpty ? '메모를 입력해 주세요' : _memo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _receiptLabel.color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotal() {
    final light = widget.lightReceipt;
    final amount = _formatAmount(_itemsTotal);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: light ? 0 : 6),
      child: Row(
        mainAxisAlignment: light
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceBetween,
        spacing: 4,
        children: [
          Text(
            light ? '총' : '품목 합계',
            style: light
                ? _receiptValue.copyWith(
                    fontSize: 15,
                    height: 18 / 15,
                    fontWeight: FontWeight.w600,
                  )
                : _receiptLabel,
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Flexible(
                  child: Text(
                    amount,
                    key: const Key('receipt-items-total'),
                    semanticsLabel:
                        '$amount'
                        '원',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: light ? AppColors.background : AppColors.text,
                      fontFamily: 'Amarante',
                      fontSize: light ? 30 : 20,
                      fontWeight: FontWeight.w400,
                      height: light ? 38 / 30 : 25 / 20,
                    ),
                  ),
                ),
                SvgPicture.asset(
                  light ? AppAssets.wonDark : AppAssets.wonLight,
                  width: light ? 19 : 14,
                  height: light ? 20 : 15,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(int index) {
    final item = _items[index];
    final name = item['item_name'] as String? ?? '';
    final unitPrice = item['unit_price'] as int? ?? 0;
    final editing = _editingItemIndex == index;
    void startEditing() {
      if (widget.editable && !editing) {
        setState(() => _editingItemIndex = index);
      }
    }

    final deleteButton = widget.editable
        ? GestureDetector(
            key: Key('receipt-item-delete-$index'),
            behavior: HitTestBehavior.opaque,
            onTap: _items.length <= 1
                ? null
                : () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() {
                      _editingItemIndex = null;
                      _items.removeAt(index);
                      _quantities.removeAt(index);
                    });
                  },
            child: Semantics(
              button: true,
              label: '품목 삭제',
              child: SvgPicture.asset(
                AppAssets.receiptDeleteItem,
                width: 24,
                height: 24,
                colorFilter: widget.lightReceipt
                    ? const ColorFilter.mode(Color(0x80121215), BlendMode.srcIn)
                    : null,
              ),
            ),
          )
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _ink.withValues(alpha: .08))),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              key: Key('receipt-item-$index'),
              behavior: HitTestBehavior.opaque,
              onTap: startEditing,
              child: Focus(
                onFocusChange: (hasFocus) {
                  if (!hasFocus && editing) {
                    _finishItemEditing(
                      index,
                      item['item_name'] as String? ?? '',
                    );
                  }
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 96),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          if (editing)
                            Expanded(
                              child: TextFormField(
                                key: Key('receipt-item-name-input-$index'),
                                initialValue: name,
                                autofocus: true,
                                scrollPadding: const EdgeInsets.only(
                                  bottom: 84,
                                ),
                                textInputAction: TextInputAction.next,
                                style: _itemNameStyle,
                                decoration: _itemInputDecoration('품목명 입력'),
                                onTapOutside: (_) => FocusManager
                                    .instance
                                    .primaryFocus
                                    ?.unfocus(),
                                onChanged: (value) => item['item_name'] = value,
                              ),
                            )
                          else
                            Flexible(
                              child: Text(
                                name.isEmpty ? '품목명 입력' : name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _itemNameStyle,
                              ),
                            ),
                          if (deleteButton != null) ...[
                            const SizedBox(width: 3),
                            deleteButton,
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        item['unit_price'] == null
                            ? (editing ? '0원' : '단가 입력')
                            : '${_formatAmount(unitPrice * _quantities[index])}원',
                        style: item['unit_price'] == null && !editing
                            ? _unitPriceStyle
                            : _itemPriceStyle,
                      ),
                      if (editing || item['unit_price'] != null) ...[
                        const SizedBox(height: 14),
                        if (editing)
                          Row(
                            children: [
                              Text('단가', style: _unitPriceStyle),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  key: Key('receipt-item-price-input-$index'),
                                  initialValue:
                                      item['unit_price']?.toString() ?? '',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(9),
                                  ],
                                  textInputAction: TextInputAction.done,
                                  style: _unitPriceStyle,
                                  decoration: _itemInputDecoration(
                                    '입력',
                                    suffix: '원',
                                  ),
                                  onTapOutside: (_) => FocusManager
                                      .instance
                                      .primaryFocus
                                      ?.unfocus(),
                                  onChanged: (value) => setState(
                                    () => item['unit_price'] = int.tryParse(
                                      value,
                                    ),
                                  ),
                                  onFieldSubmitted: (_) => _finishItemEditing(
                                    index,
                                    item['item_name'] as String? ?? '',
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Text('단가', style: _unitPriceStyle),
                              const SizedBox(width: 12),
                              Text(
                                '${_formatAmount(unitPrice)}원',
                                style: _unitPriceStyle,
                              ),
                            ],
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _RoundControl(
            lightReceipt: widget.lightReceipt,
            asset: AppAssets.receiptAddItem,
            onTap: () => setState(() => _quantities[index]++),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 23.833,
            child: Text(
              _quantities[index].toString(),
              textAlign: TextAlign.center,
              style: _receiptValue.copyWith(
                fontSize: 15,
                height: 18 / 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          _RoundControl(
            lightReceipt: widget.lightReceipt,
            asset: AppAssets.receiptRemoveItem,
            onTap: () => setState(() {
              if (_quantities[index] > 1) _quantities[index]--;
            }),
          ),
        ],
      ),
    );
  }

  InputDecoration _itemInputDecoration(String hint, {String? suffix}) =>
      InputDecoration(
        hintText: hint,
        suffixText: suffix,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        hintStyle: _receiptLabel,
        suffixStyle: _unitPriceStyle,
      );

  TextStyle get _unitPriceStyle => _receiptLabel;

  TextStyle get _itemNameStyle =>
      _receiptValue.copyWith(fontSize: 20, height: 24 / 20);

  TextStyle get _itemPriceStyle => _receiptValue.copyWith(color: _accent);

  Color get _accent =>
      widget.lightReceipt ? AppColors.main : const Color(0xFFA8A3FF);

  Color get _ink =>
      widget.lightReceipt ? const Color(0xFF1B1B1B) : AppColors.text;
  TextStyle get _receiptLabel => widget.lightReceipt
      ? _labelStyle.copyWith(color: const Color(0x80121215))
      : _labelStyle;
  TextStyle get _receiptValue => _valueStyle.copyWith(color: _ink);

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

  List<Widget> _paymentOptions(ValueChanged<String>? onSelected) => [
    for (final method in paymentMethods)
      ChoiceChip(
        label: Text(method),
        selected: _paymentMethod == method,
        showCheckmark: false,
        shape: const StadiumBorder(),
        backgroundColor: AppColors.selected,
        disabledColor: _paymentMethod == method
            ? const Color(0xFFA8A3FF)
            : AppColors.selected,
        selectedColor: const Color(0xFFA8A3FF),
        side: const BorderSide(color: AppColors.text20, width: .5),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        labelPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 7.5),
        padding: EdgeInsets.zero,
        labelStyle: TextStyle(
          fontSize: 15,
          height: 18 / 15,
          fontFamily: 'Pretendard',
          letterSpacing: 0,
          fontWeight: FontWeight.w600,
          color: _paymentMethod == method
              ? const Color(0xFF1B1B1B)
              : AppColors.text50,
        ),
        onSelected: onSelected == null ? null : (_) => onSelected(method),
      ),
  ];

  Future<void> _selectPaymentMethod() async {
    final method = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.secondary,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('결제수단 선택', style: _valueStyle),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _paymentOptions(
                  (method) => Navigator.pop(context, method),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (method != null && mounted) setState(() => _paymentMethod = method);
  }

  Future<void> _selectCategory() async {
    final categories = categoryNames(
      CategoryKind.expense,
      including: _category,
    );
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
      _items.add({'item_name': '', 'quantity': 1, 'unit_price': null});
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

  Map<String, Object?>? buildUpdatePayload() {
    if (_storeName.trim().isEmpty) return null;
    final items = <Map<String, Object?>>[];
    for (var index = 0; index < _items.length; index++) {
      final name = _items[index]['item_name'] as String? ?? '';
      final price = _items[index]['unit_price'] as int?;
      if (name.trim().isEmpty || price == null) return null;
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
      'payment_method': _paymentMethod,
      'items': items,
      'memo': _memo.trim().isEmpty ? null : _memo.trim(),
    };
  }

  Map<String, Object?>? buildPayload({required String source}) {
    final update = buildUpdatePayload();
    if (update == null) return null;
    return {
      ...update,
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

const _valueStyle = TextStyle(
  fontFamily: 'Pretendard',
  color: AppColors.text,
  fontSize: 14,
  height: 22 / 14,
  letterSpacing: 0,
  fontWeight: FontWeight.w500,
);
final _labelStyle = _valueStyle.copyWith(color: AppColors.text50);

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.missing = false,
    this.lightReceipt = false,
  });
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool missing;
  final bool lightReceipt;
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
            Text(
              label,
              style: lightReceipt
                  ? _labelStyle.copyWith(color: const Color(0x80121215))
                  : _labelStyle,
            ),
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
                          : lightReceipt
                          ? _valueStyle.copyWith(color: const Color(0xFF1B1B1B))
                          : _valueStyle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AppChevron(
                    size: 20,
                    color: lightReceipt
                        ? const Color(0x80121215)
                        : AppColors.text,
                  ),
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
  const _Asterisks({required this.lightReceipt});
  final bool lightReceipt;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 7,
    child: SvgPicture.asset(
      AppAssets.receiptAsteriskDivider,
      fit: BoxFit.fill,
      colorFilter: lightReceipt
          ? null
          : const ColorFilter.mode(AppColors.text, BlendMode.srcIn),
    ),
  );
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.asset,
    required this.onTap,
    required this.lightReceipt,
  });
  final bool lightReceipt;
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
          color: lightReceipt ? Colors.white : AppColors.selected,
          shape: BoxShape.circle,
          border: Border.all(
            color: lightReceipt ? const Color(0x26121215) : AppColors.outline,
            width: .5,
          ),
        ),
        child: lightReceipt
            ? Icon(
                asset == AppAssets.receiptAddItem ? Icons.add : Icons.remove,
                color: const Color(0xFF1B1B1B),
                size: 21,
              )
            : SvgPicture.asset(asset),
      ),
    );
  }
}
