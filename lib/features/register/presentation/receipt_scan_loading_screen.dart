import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../finance/data/finance_service.dart';
import 'receipt_result_screen.dart';

class ReceiptScanLoadingScreen extends StatefulWidget {
  const ReceiptScanLoadingScreen({
    required this.imagePath,
    this.financeService,
    this.autoRecognize = true,
    super.key,
  });
  final String imagePath;
  final FinanceService? financeService;
  final bool autoRecognize;
  @override
  State<ReceiptScanLoadingScreen> createState() =>
      _ReceiptScanLoadingScreenState();
}

class _ReceiptScanLoadingScreenState extends State<ReceiptScanLoadingScreen> {
  String? _error;
  @override
  void initState() {
    super.initState();
    if (widget.autoRecognize) _recognize();
  }

  Future<void> _recognize() async {
    setState(() => _error = null);
    try {
      final result = await (widget.financeService ?? AppServices.finance)
          .recognizeReceipt(widget.imagePath);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ReceiptResultScreen(
            imagePath: widget.imagePath,
            initialData: result,
            financeService: widget.financeService ?? AppServices.finance,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        child: Stack(
          alignment: Alignment.center,
          children: [
            const ColoredBox(color: AppColors.background),
            SvgPicture.asset(
              AppAssets.receiptScannerFrame,
              width: 254,
              height: 254,
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 36,
                  child: SvgPicture.asset(AppAssets.receiptScannerCheck),
                ),
                const SizedBox(height: 20),
                Text(
                  _error ?? '영수증 인식중',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  TextButton(onPressed: _recognize, child: const Text('다시 시도')),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
