import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/editable_receipt_form.dart';
import '../../../shared/widgets/p1_design_components.dart';
import '../../finance/data/finance_service.dart';

enum LedgerEditResult { updated, deleted }

class LedgerEditScreen extends StatefulWidget {
  const LedgerEditScreen({
    super.key,
    this.expenseId,
    this.financeService,
    this.initialData,
  });

  final String? expenseId;
  final FinanceService? financeService;
  final Map<String, dynamic>? initialData;

  @override
  State<LedgerEditScreen> createState() => _LedgerEditScreenState();
}

class _LedgerEditScreenState extends State<LedgerEditScreen> {
  final _formKey = GlobalKey<EditableReceiptFormState>();
  Map<String, dynamic>? _data;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  bool get _hasRemoteTarget =>
      widget.financeService != null && widget.expenseId != null;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;
    if (_data == null && _hasRemoteTarget) _load();
  }

  Future<void> _load() async {
    final service = widget.financeService;
    final id = widget.expenseId;
    if (service == null || id == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await service.expenseDetail(id);
      if (mounted) setState(() => _data = data);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '내역을 불러오지 못했습니다. 다시 시도해 주세요');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final service = widget.financeService;
    final id = widget.expenseId;
    if (service == null || id == null) {
      Navigator.of(context).maybePop();
      return;
    }
    final payload = _formKey.currentState?.buildUpdatePayload();
    if (payload == null) {
      setState(() => _error = '가맹점명과 품목 정보를 확인해 주세요');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await service.updateExpense(id, payload);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
      return;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
    if (mounted) Navigator.of(context).pop(LedgerEditResult.updated);
  }

  Future<void> _delete() async {
    final service = widget.financeService;
    final id = widget.expenseId;
    if (service == null || id == null || _isSubmitting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x99121215),
      builder: (context) => P1ConfirmDialog(
        title: '이 내역을 삭제할까요?',
        description:
            '${_data?['store_name'] as String? ?? '가맹점'} · ${_formatDeleteAmount(_data?['total_amount'] as int? ?? 0)}원',
        warning: '더치페이 정산 기록도 함께 삭제돼요',
        cancelLabel: '취소',
        confirmLabel: '삭제하기',
        confirmKey: const Key('confirm-delete-ledger-entry'),
        onConfirm: () => Navigator.pop(context, true),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await service.deleteExpense(id);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
      return;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
    if (mounted) Navigator.of(context).pop(LedgerEditResult.deleted);
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _hasRemoteTarget && _data != null;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: DesignCanvas(
        child: Stack(
          children: [
            const ColoredBox(color: AppColors.background),
            Positioned(
              left: 24,
              top: 50,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: SvgPicture.asset(
                  AppAssets.arrowBackLight,
                  width: 34,
                  height: 34,
                ),
              ),
            ),
            if (canSubmit)
              Positioned(
                right: 24,
                top: 50,
                child: GestureDetector(
                  key: const Key('delete-ledger-entry'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _isSubmitting ? null : _delete,
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: SvgPicture.asset(AppAssets.deleteRed),
                  ),
                ),
              ),
            if (!_isLoading && (_data != null || !_hasRemoteTarget))
              Positioned(
                left: 24,
                top: 112,
                width: 354,
                height: 621,
                child: ClipRect(
                  child: SingleChildScrollView(
                    key: const Key('ledger-edit-receipt-scroll'),
                    child: EditableReceiptForm(
                      key: _formKey,
                      initialData: _data,
                      editable: canSubmit,
                    ),
                  ),
                ),
              ),
            if (_isLoading)
              const Positioned(
                key: Key('ledger-edit-loading'),
                left: 24,
                top: 112,
                child: AppSkeletonReceipt(height: 621),
              ),
            if (_error case final message?)
              Positioned(
                left: 24,
                right: 24,
                bottom: 105,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFF6B7A),
                    fontSize: 12,
                  ),
                ),
              ),
            if (_error != null && _data == null)
              Positioned(
                left: 126,
                right: 126,
                top: 480,
                height: 40,
                child: OutlinedButton(
                  key: const Key('retry-ledger-detail'),
                  onPressed: _load,
                  child: const Text('다시 시도'),
                ),
              ),
            Positioned(
              left: 24,
              bottom: 40,
              child: GestureDetector(
                onTap: _isLoading || _error != null || _isSubmitting
                    ? null
                    : _save,
                child: Container(
                  width: 354,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: canSubmit ? AppColors.main : AppColors.selected,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Text(
                    _isLoading
                        ? '불러오는 중...'
                        : _isSubmitting
                        ? '처리 중...'
                        : '저장',
                    style: TextStyle(
                      color: canSubmit ? Colors.white : AppColors.text50,
                      fontSize: 15,
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

String _formatDeleteAmount(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);
