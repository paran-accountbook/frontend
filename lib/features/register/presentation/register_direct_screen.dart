import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../finance/data/finance_service.dart';
import '../../ledger/presentation/ledger_screen.dart';
import 'receipt_entry_form.dart';

class RegisterDirectScreen extends StatefulWidget {
  const RegisterDirectScreen({super.key, this.financeService});
  final FinanceService? financeService;

  @override
  State<RegisterDirectScreen> createState() => _RegisterDirectScreenState();
}

class _RegisterDirectScreenState extends State<RegisterDirectScreen> {
  final _formKey = GlobalKey<ReceiptEntryFormState>();
  bool _isLoading = false;
  String? _error;

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
    try {
      await service.createExpense(payload);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LedgerScreen(financeService: service),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
            width: 354,
            child: ReceiptEntryForm(key: _formKey, editable: serviceEnabled),
          ),
          if (_error case final message?)
            Positioned(
              left: 24,
              right: 24,
              bottom: 118,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFF6B7A), fontSize: 12),
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

  bool get serviceEnabled => widget.financeService != null;
}
