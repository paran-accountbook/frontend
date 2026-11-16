import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import '../../category/data/category_service.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/form_save_button.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../shared/widgets/p2_widgets.dart';
import '../../finance/data/finance_service.dart';
import 'receipt_entry_form.dart';
import 'expense_registration_complete_screen.dart';
import 'receipt_scan_loading_screen.dart';

class ReceiptResultScreen extends StatefulWidget {
  const ReceiptResultScreen({
    required this.imagePath,
    this.initialData,
    this.financeService,
    this.imageSource,
    super.key,
  });
  final String imagePath;
  final Map<String, dynamic>? initialData;
  final FinanceService? financeService;
  final ImageSource? imageSource;

  @override
  State<ReceiptResultScreen> createState() => _ReceiptResultScreenState();
}

class _ReceiptResultScreenState extends State<ReceiptResultScreen> {
  final _formKey = GlobalKey<ReceiptEntryFormState>();
  bool _isLoading = false;
  String? _error;
  final List<String> _photoPaths = [];

  Future<void> _addPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (image != null && mounted) setState(() => _photoPaths.add(image.path));
  }

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
      if (service is ExpensePhotoService) {
        for (final path in List<String>.from(_photoPaths)) {
          await (service as ExpensePhotoService).uploadExpensePhoto(
            expenseId,
            path,
          );
          _photoPaths.remove(path);
        }
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => ExpenseRegistrationCompleteScreen(
            expenseId: expenseId,
            financeService: service,
            storeName:
                created['store_name'] as String? ??
                payload['store_name'] as String?,
            totalAmount:
                created['total_amount'] as int? ??
                payload['total_amount'] as int?,
            showDutchPay: created['can_dutch_pay'] as bool? ?? true,
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

  Future<void> _pickAgain() async {
    final source = widget.imageSource;
    if (source == null) return;
    final image = await ImagePicker().pickImage(
      source: source,
      requestFullMetadata: false,
    );
    if (image == null || !mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ReceiptScanLoadingScreen(
          imagePath: image.path,
          imageSource: source,
          financeService: widget.financeService,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    preloadCategories(widget.financeService);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        fitWidthWithKeyboard: MediaQuery.viewInsetsOf(context).bottom > 0,
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
              right: 0,
              bottom: 0,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  children: [
                    ReceiptEntryForm(
                      key: _formKey,
                      showMemo: true,
                      trailingInset: 24,
                      initialData: widget.initialData,
                      editable: widget.financeService != null,
                      photos: P2PhotoAttachButton(
                        count: _photoPaths.length,
                        onTap: widget.financeService != null ? _addPhoto : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: Column(
                        children: [
                          if (widget.imageSource != null) ...[
                            const SizedBox(height: 16),
                            OutlinedButton(
                              key: const Key('receipt-result-retry'),
                              onPressed: _pickAgain,
                              child: Text(
                                widget.imageSource == ImageSource.camera
                                    ? '다시 촬영'
                                    : '다시 선택',
                              ),
                            ),
                          ],
                          if (_error case final message?) ...[
                            const SizedBox(height: 12),
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFFF6B7A),
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FormSaveButton(
                            keyboardVisible:
                                MediaQuery.viewInsetsOf(context).bottom > 0,
                            label: _isLoading ? '저장 중...' : '저장',
                            onPressed: _isLoading ? null : _save,
                          ),
                        ],
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
  }
}
