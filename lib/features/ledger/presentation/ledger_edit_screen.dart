import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../shared/widgets/editable_receipt_form.dart';
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
  bool _isSubmitting = false;
  String? _error;

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
      builder: (context) => AlertDialog(
        title: const Text('내역 삭제'),
        content: const Text('삭제한 내역은 되돌릴 수 없습니다. 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            key: const Key('confirm-delete-ledger-entry'),
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B7A),
            ),
            child: const Text('삭제'),
          ),
        ],
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
    final canSubmit = widget.financeService != null && widget.expenseId != null;
    return Scaffold(
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
            Positioned(
              left: 24,
              top: 141,
              width: 354,
              height: 592,
              child: ClipRect(
                child: SingleChildScrollView(
                  key: const Key('ledger-edit-receipt-scroll'),
                  child: EditableReceiptForm(
                    key: _formKey,
                    initialData: widget.initialData,
                    editable: canSubmit,
                  ),
                ),
              ),
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
            Positioned(
              left: 24,
              bottom: 40,
              child: GestureDetector(
                onTap: _isSubmitting ? null : _save,
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
                    _isSubmitting ? '처리 중...' : '저장',
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
