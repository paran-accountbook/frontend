import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../shared/widgets/app_chevron.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/p1_design_components.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/app_services.dart';
import '../../dutch/data/dutch_pay_service.dart';
import '../../dutch/presentation/dutch_people_screen.dart';
import '../../dutch/presentation/dutch_result_screen.dart';
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
            Positioned.fill(
              child: SingleChildScrollView(
                key: const Key('ledger-detail-scroll'),
                padding: EdgeInsets.zero,
                child: SizedBox(
                  width: 402,
                  height: 1203,
                  child: Stack(
                    children: [
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
                        child: FilledButton(
                          onPressed: _isStartingDutchPay
                              ? null
                              : _startDutchPay,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.main,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            _isStartingDutchPay
                                ? '불러오는 중...'
                                : _data?['dutch_pay_status'] == 'completed'
                                ? '정산 결과'
                                : '더치페이',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      if (!_isLoading &&
                          (_data != null || widget.expenseId == null))
                        Positioned(
                          left: 24,
                          top: 112,
                          width: 354,
                          height: 923,
                          child: _ReceiptDetail(
                            data: _data,
                            onEdit: _data == null ? null : _openEdit,
                            onDeletePhoto: _deletePhoto,
                            onItemsChanged: _updateItems,
                          ),
                        ),
                      if (_isLoading)
                        const Positioned(
                          key: Key('ledger-detail-loading'),
                          left: 24,
                          top: 112,
                          child: AppSkeletonReceipt(height: 923),
                        ),
                      if (_error case final message?)
                        Positioned(
                          left: 24,
                          right: 24,
                          top: 480,
                          child: Text(
                            message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFF6B7A),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (!_isLoading && _error == null)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 1046,
                          child: GestureDetector(
                            key: const Key('delete-ledger-entry'),
                            behavior: HitTestBehavior.opaque,
                            onTap: _deleteEntry,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  AppAssets.trashRed,
                                  width: 34,
                                  height: 34,
                                ),
                                const Text(
                                  '내역 삭제',
                                  style: TextStyle(
                                    color: Color(0xFFCF376A),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            P1BottomAction(
              key: const Key('save-ledger-entry'),
              label: '저장',
              blurBackground: false,
              onTap: _isLoading || _error != null ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_data != null) await _openEdit();
  }

  void _updateItems(List<Map<String, dynamic>> items) {
    if (_data == null) return;
    final total = items.fold<int>(
      0,
      (sum, item) =>
          sum +
          (item['unit_price'] as int? ?? 0) * (item['quantity'] as int? ?? 1),
    );
    setState(() => _data = {...?_data, 'items': items, 'total_amount': total});
  }

  Future<void> _deleteEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x99121215),
      builder: (context) => P1ConfirmDialog(
        title: '이 내역을 삭제할까요?',
        description:
            '${_data?['store_name'] as String? ?? '가맹점'} · ${_formatAmount(_data?['total_amount'] as int? ?? 0)}원',
        warning: '더치페이 정산 기록도 함께 삭제돼요',
        cancelLabel: '취소',
        confirmLabel: '삭제하기',
        confirmKey: const Key('confirm-delete-ledger-entry'),
        onConfirm: () => Navigator.pop(context, true),
      ),
    );
    if (confirmed != true || !mounted) return;
    final service = widget.financeService;
    final id = widget.expenseId;
    if (service == null || id == null) return;
    try {
      await service.deleteExpense(id);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _startDutchPay() async {
    final id = widget.expenseId;
    if (id == null) return;
    final service = widget.dutchPayService ?? AppServices.dutchPay;
    setState(() => _isStartingDutchPay = true);
    try {
      final entry = await service.entry(id);
      if (!mounted) return;
      if (entry['status'] == 'completed') {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DutchResultScreen(
              sessionId: entry['session_id'] as String?,
              dutchPayService: service,
              selfName: entry['self_name_suggestion'] as String?,
            ),
          ),
        );
        return;
      }
      if ((entry['participants'] as List?)?.isNotEmpty == true) {
        final resume = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('진행 중인 정산이 있어요'),
            content: const Text('이전에 저장한 인원과 배정 내용부터 이어서 진행할까요?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('이어하기'),
              ),
            ],
          ),
        );
        if (resume != true || !mounted) return;
      }
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

  Future<void> _deletePhoto(String photoId) async {
    final id = widget.expenseId;
    final service = widget.financeService;
    if (id == null || service is! ExpensePhotoService) return;
    final photoService = service as ExpensePhotoService;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('소비 사진을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await photoService.deleteExpensePhoto(id, photoId);
      if (!mounted) return;
      final photos =
          (_data?['photos'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .where((photo) => photo['id'] != photoId)
              .toList() ??
          const <Map<String, dynamic>>[];
      setState(() => _data = {...?_data, 'photos': photos});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('소비 사진이 삭제되었습니다')));
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _ReceiptDetail extends StatefulWidget {
  const _ReceiptDetail({
    this.data,
    this.onEdit,
    this.onDeletePhoto,
    this.onItemsChanged,
  });
  final Map<String, dynamic>? data;
  final VoidCallback? onEdit;
  final ValueChanged<String>? onDeletePhoto;
  final ValueChanged<List<Map<String, dynamic>>>? onItemsChanged;

  @override
  State<_ReceiptDetail> createState() => _ReceiptDetailState();
}

class _ReceiptDetailState extends State<_ReceiptDetail> {
  late List<Map<String, dynamic>> _items;
  int? _editingItemIndex;

  @override
  void initState() {
    super.initState();
    _items = _itemsFrom(widget.data);
  }

  @override
  void didUpdateWidget(covariant _ReceiptDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.data?['items'], oldWidget.data?['items']) &&
        _editingItemIndex == null) {
      _items = _itemsFrom(widget.data);
    }
  }

  static List<Map<String, dynamic>> _itemsFrom(Map<String, dynamic>? data) {
    final items = (data?['items'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    if (items != null && items.isNotEmpty) return items;
    return [
      {'item_name': '아메리카노', 'quantity': 3, 'unit_price': 4500},
      {'item_name': '카페라떼', 'quantity': 1, 'unit_price': 4500},
      {'item_name': '아메리카노', 'quantity': 3, 'unit_price': 4500},
    ];
  }

  void _changeQuantity(int index, int delta) {
    final quantity = _items[index]['quantity'] as int? ?? 1;
    if (quantity + delta < 1) return;
    setState(() => _items[index]['quantity'] = quantity + delta);
    _notifyItemsChanged();
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
      _editingItemIndex = null;
    });
    _notifyItemsChanged();
  }

  void _addItem() {
    setState(() {
      _items.add({'item_name': '', 'quantity': 1, 'unit_price': 0});
      _editingItemIndex = _items.length - 1;
    });
    _notifyItemsChanged();
  }

  void _updateItem(int index, {String? name, int? unitPrice}) {
    if (name != null) _items[index]['item_name'] = name;
    if (unitPrice != null) _items[index]['unit_price'] = unitPrice;
    _notifyItemsChanged();
  }

  void _finishEditing() {
    FocusScope.of(context).unfocus();
    setState(() => _editingItemIndex = null);
  }

  void _notifyItemsChanged() {
    widget.onItemsChanged?.call(
      _items.map((item) => Map<String, dynamic>.from(item)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final receiptImageUrl = data?['receipt_image_url'] as String?;
    final photos =
        (data?['photos'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        (data == null
            ? const [
                <String, dynamic>{'id': 'preview-1', 'url': null},
                <String, dynamic>{'id': 'preview-2', 'url': null},
                <String, dynamic>{'id': 'preview-3', 'url': null},
                <String, dynamic>{'id': 'preview-4', 'url': null},
              ]
            : const <Map<String, dynamic>>[]);
    return Stack(
      children: [
        const Positioned.fill(child: _ReceiptBackground()),
        Positioned(
          left: 17,
          right: 17,
          top: 30,
          bottom: 20,
          child: Column(
            children: [
              const _DarkAsterisks(),
              const SizedBox(height: 11),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('총 ', style: _darkLabel),
                  Text(
                    _formatAmount(data?['total_amount'] as int? ?? 40500),
                    style: _darkAmount,
                  ),
                  const SizedBox(width: 4),
                  SvgPicture.asset(AppAssets.wonDark, width: 18, height: 18),
                ],
              ),
              const SizedBox(height: 11),
              const _DarkAsterisks(),
              const SizedBox(height: 11),
              if (receiptImageUrl?.isNotEmpty == true || data == null) ...[
                _OriginalReceiptRow(
                  onTap: receiptImageUrl?.isNotEmpty == true
                      ? () => _showImage(context, receiptImageUrl!)
                      : null,
                ),
                const Divider(height: 1, color: Color(0x0D121215)),
              ],
              _DetailRow(
                label: '가맹점 명',
                value: data?['store_name'] as String? ?? '아주대학교 카페',
                onTap: widget.onEdit,
              ),
              _DetailRow(
                label: '결제일시',
                value: _dateLabel(data?['paid_at'] as String?),
                onTap: widget.onEdit,
              ),
              _DetailRow(
                label: '카테고리',
                value: data?['category'] as String? ?? '식비',
                onTap: widget.onEdit,
              ),
              _DetailRow(
                label: '결제수단',
                value: data?['payment_method'] as String? ?? '현금',
                onTap: widget.onEdit,
              ),
              const SizedBox(height: 10),
              const _DarkAsterisks(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('품목   ${_items.length}', style: _darkFieldMuted),
                  GestureDetector(
                    key: const Key('edit-ledger-entry'),
                    onTap: widget.onEdit ?? _addItem,
                    behavior: HitTestBehavior.opaque,
                    child: const Text(
                      '품목 추가 +',
                      style: TextStyle(
                        color: AppColors.main,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._items.indexed.map(
                (entry) => _DetailItem(
                  index: entry.$1,
                  name: entry.$2['item_name'] as String? ?? '',
                  quantity: entry.$2['quantity'] as int? ?? 1,
                  unitPrice: entry.$2['unit_price'] as int? ?? 0,
                  isEditing: _editingItemIndex == entry.$1,
                  onStartEditing: () =>
                      setState(() => _editingItemIndex = entry.$1),
                  onFinishEditing: _finishEditing,
                  onNameChanged: (value) => _updateItem(entry.$1, name: value),
                  onUnitPriceChanged: (value) =>
                      _updateItem(entry.$1, unitPrice: value),
                  onIncrease: () => _changeQuantity(entry.$1, 1),
                  onDecrease: () => _changeQuantity(entry.$1, -1),
                  onDelete: () => _deleteItem(entry.$1),
                ),
              ),
              if (photos.isNotEmpty) ...[
                const SizedBox(height: 8),
                const _DarkAsterisks(),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('소비사진  ${photos.length}', style: _darkFieldMuted),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 58,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      return _ExpensePhoto(
                        url: photo['url'] as String?,
                        deleteKey: Key(
                          'delete-expense-photo-${photo['id'] as String}',
                        ),
                        onOpen: (photo['url'] as String?)?.isNotEmpty == true
                            ? () => _showImage(context, photo['url'] as String)
                            : null,
                        onDelete: widget.onDeletePhoto == null
                            ? null
                            : () => widget.onDeletePhoto?.call(
                                photo['id'] as String,
                              ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const _DarkAsterisks(),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('메모', style: _darkFieldMuted),
                  Text(
                    '(선택)',
                    style: TextStyle(
                      color: AppColors.main,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  data?['memo'] as String? ?? '과제하다가 친구랑 마심',
                  style: _darkLabel,
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ],
    );
  }

  static void _showImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: .8,
                maxScale: 5,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Text(
                      '이미지를 불러오지 못했습니다',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _darkLabel = TextStyle(
  color: Color(0xFF1B1B1B),
  fontSize: 14,
  fontWeight: FontWeight.w500,
);
const _darkMuted = TextStyle(color: Color(0x80121215), fontSize: 12);
const _darkFieldMuted = TextStyle(
  color: Color(0x80121215),
  fontSize: 14,
  fontWeight: FontWeight.w500,
);
const _darkAmount = TextStyle(
  color: Color(0xFF1B1B1B),
  fontFamily: 'Amarante',
  fontSize: 28,
);

class _DarkAsterisks extends StatelessWidget {
  const _DarkAsterisks();
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    AppAssets.receiptAsteriskDivider,
    width: 320,
    height: 7,
    fit: BoxFit.fill,
  );
}

class _ReceiptBackground extends StatelessWidget {
  const _ReceiptBackground();

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFAFAFF), Color(0xFFE4E4FA)],
              stops: [0.16, 1],
            ),
          ),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: 10,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minWidth: 354,
            maxWidth: 354,
            minHeight: 593,
            maxHeight: 593,
            child: SvgPicture.asset(
              AppAssets.expenseReceiptBackground,
              width: 354,
              height: 593,
            ),
          ),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        height: 10,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.bottomCenter,
            minWidth: 354,
            maxWidth: 354,
            minHeight: 592,
            maxHeight: 592,
            child: SvgPicture.asset(
              AppAssets.expenseReceiptBackgroundBottom,
              width: 354,
              height: 592,
            ),
          ),
        ),
      ),
    ],
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      height: 42,
      child: Row(
        children: [
          Text(label, style: _darkFieldMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: _darkLabel,
            ),
          ),
          const SizedBox(width: 6),
          const AppChevron(color: Color(0x80121215), size: 24),
        ],
      ),
    ),
  );
}

class _OriginalReceiptRow extends StatelessWidget {
  const _OriginalReceiptRow({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const Key('open-receipt-original'),
    onTap: onTap,
    child: SizedBox(
      height: 42,
      child: Row(
        children: [
          const Text('영수증 원본', style: _darkFieldMuted),
          const Spacer(),
          SvgPicture.asset(AppAssets.receiptOriginal, width: 26, height: 26),
          const SizedBox(width: 6),
          const Text(
            '보기',
            style: TextStyle(
              color: AppColors.main,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          const AppChevron(color: Color(0x80121215), size: 24),
        ],
      ),
    ),
  );
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.index,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.isEditing,
    required this.onStartEditing,
    required this.onFinishEditing,
    required this.onNameChanged,
    required this.onUnitPriceChanged,
    required this.onIncrease,
    required this.onDecrease,
    required this.onDelete,
  });
  final int index;
  final String name;
  final int quantity;
  final int unitPrice;
  final bool isEditing;
  final VoidCallback onStartEditing;
  final VoidCallback onFinishEditing;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<int> onUnitPriceChanged;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 62.5,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                key: Key('ledger-detail-item-edit-$index'),
                behavior: HitTestBehavior.opaque,
                onDoubleTap: onStartEditing,
                child: isEditing
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 24,
                            child: TextFormField(
                              key: Key('ledger-detail-item-name-$index'),
                              initialValue: name,
                              autofocus: true,
                              textInputAction: TextInputAction.next,
                              style: _darkLabel,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                              onChanged: onNameChanged,
                            ),
                          ),
                          Row(
                            children: [
                              const Text('단가', style: _darkMuted),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 64,
                                height: 22,
                                child: TextFormField(
                                  key: Key(
                                    'ledger-detail-item-unit-price-$index',
                                  ),
                                  initialValue: unitPrice.toString(),
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  style: _darkMuted,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    suffixText: '원',
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (value) => onUnitPriceChanged(
                                    int.tryParse(value.replaceAll(',', '')) ??
                                        0,
                                  ),
                                  onFieldSubmitted: (_) => onFinishEditing(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  '${_formatAmount(unitPrice * quantity)}원',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _darkItemTotal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? '품목명을 입력해 주세요' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: name.isEmpty ? _darkFieldMuted : _darkLabel,
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Text('단가', style: _darkMuted),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  '${_formatAmount(unitPrice)}원',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _darkMuted,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  '${_formatAmount(unitPrice * quantity)}원',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _darkItemTotal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
            _LedgerItemControl(
              key: Key('ledger-detail-item-add-$index'),
              asset: AppAssets.ledgerItemAdd,
              onTap: onIncrease,
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 24,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF1B1B1B),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _LedgerItemControl(
              key: Key('ledger-detail-item-remove-$index'),
              asset: AppAssets.ledgerItemRemove,
              onTap: onDecrease,
            ),
            const SizedBox(width: 6),
            GestureDetector(
              key: Key('ledger-detail-item-delete-$index'),
              behavior: HitTestBehavior.opaque,
              onTap: onDelete,
              child: SvgPicture.asset(AppAssets.ledgerItemDelete),
            ),
          ],
        ),
      ),
      SvgPicture.asset(AppAssets.ledgerItemDivider),
    ],
  );
}

const _darkItemTotal = TextStyle(color: Color(0xFF1B1B1B), fontSize: 12);

class _LedgerItemControl extends StatelessWidget {
  const _LedgerItemControl({
    super.key,
    required this.asset,
    required this.onTap,
  });

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x33121215), width: .5),
      ),
      child: SvgPicture.asset(asset),
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

class _ExpensePhoto extends StatelessWidget {
  const _ExpensePhoto({this.url, this.deleteKey, this.onOpen, this.onDelete});

  final String? url;
  final Key? deleteKey;
  final VoidCallback? onOpen;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      GestureDetector(
        onTap: onOpen,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 50,
            height: 50,
            color: Colors.white,
            child: url?.isNotEmpty == true
                ? Image.network(
                    url!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.main,
                    ),
                  )
                : Center(
                    child: SvgPicture.asset(
                      AppAssets.expensePhoto,
                      width: 28,
                      height: 28,
                    ),
                  ),
          ),
        ),
      ),
      if (onDelete != null)
        Positioned(
          right: -5,
          top: -5,
          child: GestureDetector(
            key: deleteKey,
            onTap: onDelete,
            child: SvgPicture.asset(
              AppAssets.expensePhotoRemove,
              width: 18,
              height: 18,
            ),
          ),
        ),
    ],
  );
}
