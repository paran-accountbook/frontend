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
import 'expense_registration_complete_screen.dart';
import 'receipt_entry_form.dart';

class RegisterDirectScreen extends StatefulWidget {
  const RegisterDirectScreen({
    super.key,
    this.financeService,
    this.initialImagePath,
  });
  final FinanceService? financeService;
  final String? initialImagePath;

  @override
  State<RegisterDirectScreen> createState() => _RegisterDirectScreenState();
}

class _RegisterDirectScreenState extends State<RegisterDirectScreen> {
  final _formKey = GlobalKey<ReceiptEntryFormState>();
  bool _isLoading = false;
  String? _error;
  late final List<String> _photoPaths = widget.initialImagePath == null
      ? <String>[]
      : <String>[widget.initialImagePath!];
  String? _createdExpenseId;

  Future<void> _save() async {
    final service = widget.financeService;
    if (service == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    final payload = _formKey.currentState?.buildPayload(source: 'manual');
    if (payload == null) {
      setState(() => _error = '가맹점명과 품목 정보를 입력해 주세요');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    Map<String, dynamic>? createdExpense;
    try {
      final created = _createdExpenseId == null
          ? await service.createExpense(payload)
          : null;
      createdExpense = created;
      final expenseId = _createdExpenseId ?? created?['id'] as String?;
      _createdExpenseId = expenseId;
      if (expenseId != null && service is ExpensePhotoService) {
        for (final path in List<String>.from(_photoPaths)) {
          await (service as ExpensePhotoService).uploadExpensePhoto(
            expenseId,
            path,
          );
          _photoPaths.remove(path);
        }
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => ExpenseRegistrationCompleteScreen(
          expenseId: _createdExpenseId!,
          financeService: service,
          storeName:
              createdExpense?['store_name'] as String? ??
              payload['store_name'] as String?,
          totalAmount:
              createdExpense?['total_amount'] as int? ??
              payload['total_amount'] as int?,
        ),
      ),
      (_) => false,
    );
  }

  Future<void> _addPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (image != null && mounted) setState(() => _photoPaths.add(image.path));
  }

  @override
  void initState() {
    super.initState();
    preloadCategories(widget.financeService);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
          const Positioned(
            left: 24,
            top: 128,
            child: Text(
              '직접 등록',
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
                    editable: serviceEnabled,
                    showMemo: true,
                    trailingInset: 24,
                    photos: P2PhotoAttachButton(
                      count: _photoPaths.length,
                      onTap: serviceEnabled ? _addPhoto : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Column(
                      children: [
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

  bool get serviceEnabled => widget.financeService != null;
}
