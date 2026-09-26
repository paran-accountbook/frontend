import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../finance/data/finance_service.dart';
import 'receipt_entry_form.dart';
import 'expense_registration_complete_screen.dart';

class ReceiptResultScreen extends StatefulWidget {
  const ReceiptResultScreen({
    required this.imagePath,
    this.initialData,
    this.financeService,
    super.key,
  });
  final String imagePath;
  final Map<String, dynamic>? initialData;
  final FinanceService? financeService;

  @override
  State<ReceiptResultScreen> createState() => _ReceiptResultScreenState();
}

class _ReceiptResultScreenState extends State<ReceiptResultScreen> {
  final _formKey = GlobalKey<ReceiptEntryFormState>();
  bool _isLoading = false;
  String? _error;

  Future<void> _save() async {
    final service = widget.financeService;
    final data = widget.initialData;
    if (service == null || data == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    final payload = _formKey.currentState?.buildPayload(source: 'ocr');
    if (payload == null) {
      setState(() => _error = '가맹점명과 품목 정보를 확인해 주세요');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final created = await service.createExpense(payload);
      final expenseId = created['id'] as String?;
      if (expenseId == null) {
        throw const ApiException(message: '등록 결과를 확인하지 못했습니다.');
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => ExpenseRegistrationCompleteScreen(
            expenseId: expenseId,
            financeService: service,
          ),
        ),
        (_) => false,
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
              left: 24,
              top: 128,
              child: Text(
                '인식 결과 확인',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 166,
              width: 354,
              child: ReceiptEntryForm(
                key: _formKey,
                showMemo: true,
                initialData: widget.initialData,
                editable: widget.financeService != null,
              ),
            ),
            if (_error case final message?)
              Positioned(
                left: 24,
                right: 24,
                bottom: 118,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFF6B7A),
                    fontSize: 12,
                  ),
                ),
              ),
            AuthBottomAction(
              label: _isLoading ? '저장 중...' : '저장',
              onPressed: _isLoading ? () {} : _save,
            ),
          ],
        ),
      ),
    );
  }
}
