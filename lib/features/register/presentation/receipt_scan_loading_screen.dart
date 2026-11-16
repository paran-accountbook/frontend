import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/app_services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../finance/data/finance_service.dart';
import 'register_direct_screen.dart';
import 'direct_input_guide_screen.dart';
import 'receipt_result_screen.dart';

enum _ReceiptFailureAction { retry, direct }

class ReceiptScanLoadingScreen extends StatefulWidget {
  const ReceiptScanLoadingScreen({
    required this.imagePath,
    this.imageSource,
    this.financeService,
    this.autoRecognize = true,
    super.key,
  });
  final String imagePath;
  final ImageSource? imageSource;
  final FinanceService? financeService;
  final bool autoRecognize;
  @override
  State<ReceiptScanLoadingScreen> createState() =>
      _ReceiptScanLoadingScreenState();
}

class _ReceiptScanLoadingScreenState extends State<ReceiptScanLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinnerController;

  @override
  void initState() {
    super.initState();
    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    if (widget.autoRecognize) _recognize();
  }

  @override
  void dispose() {
    _spinnerController.dispose();
    super.dispose();
  }

  Future<void> _recognize() async {
    if (!_spinnerController.isAnimating) _spinnerController.repeat();
    try {
      final result = await (widget.financeService ?? AppServices.finance)
          .recognizeReceipt(widget.imagePath);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ReceiptResultScreen(
            imagePath: widget.imagePath,
            imageSource: widget.imageSource,
            initialData: result,
            financeService: widget.financeService ?? AppServices.finance,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _spinnerController.stop();
      if (error.code == 'E508') {
        // 병원·약국 영수증: AI 정리 없이 막고 사진도 넘기지 않는다.
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => DirectInputGuideScreen(
              financeService: widget.financeService ?? AppServices.finance,
            ),
          ),
        );
        return;
      }
      final action = await _showFailureDialog();
      if (!mounted) return;
      switch (action) {
        case _ReceiptFailureAction.retry:
          await _pickAgain();
        case _ReceiptFailureAction.direct:
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => RegisterDirectScreen(
                financeService: widget.financeService ?? AppServices.finance,
                initialImagePath: widget.imagePath,
              ),
            ),
          );
        case null:
          break;
      }
    }
  }

  Future<void> _pickAgain() async {
    final source = widget.imageSource;
    if (source == null) {
      await _recognize();
      return;
    }
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

  Future<_ReceiptFailureAction?> _showFailureDialog() =>
      showDialog<_ReceiptFailureAction>(
        context: context,
        barrierDismissible: false,
        barrierColor: const Color(0xB3000000),
        builder: (dialogContext) => _ReceiptRecognitionFailureDialog(
          retryLabel: widget.imageSource == ImageSource.camera
              ? '다시 촬영'
              : widget.imageSource == ImageSource.gallery
              ? '다시 선택'
              : '다시 시도',
        ),
      );

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
                Semantics(
                  label: '영수증 등록 처리 중',
                  child: SizedBox.square(
                    dimension: 52,
                    child: RotationTransition(
                      key: const ValueKey('receipt-registration-spinner'),
                      turns: _spinnerController,
                      child: const CircularProgressIndicator(
                        value: 0.75,
                        strokeWidth: 5,
                        strokeCap: StrokeCap.butt,
                        color: AppColors.main,
                        backgroundColor: AppColors.text,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '영수증 인식중',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRecognitionFailureDialog extends StatelessWidget {
  const _ReceiptRecognitionFailureDialog({this.retryLabel = '다시 시도'});
  final String retryLabel;

  @override
  Widget build(BuildContext context) => Dialog(
    key: const ValueKey('receipt-recognition-failure-dialog'),
    backgroundColor: AppColors.secondary,
    surfaceTintColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 36),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.outline),
    ),
    child: SizedBox(
      key: const ValueKey('receipt-recognition-failure-dialog-panel'),
      width: 326,
      height: 270,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 27, 30, 26),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.main.withValues(alpha: .12),
                border: Border.all(color: AppColors.main, width: 1.5),
              ),
              child: const Text(
                '!',
                style: TextStyle(
                  color: AppColors.main,
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const SizedBox(
              width: double.infinity,
              height: 24,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '영수증을 인식하지 못했어요',
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Column(
              children: [
                Text(
                  '다시 시도하거나',
                  style: TextStyle(
                    color: AppColors.text50,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                ),
                Text(
                  '직접 등록할 수 있어요.',
                  style: TextStyle(
                    color: AppColors.text50,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: _FailureActionButton(
                    label: retryLabel,
                    onPressed: () =>
                        Navigator.of(context).pop(_ReceiptFailureAction.retry),
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: _FailureActionButton(
                    label: '직접 등록',
                    primary: true,
                    onPressed: () =>
                        Navigator.of(context).pop(_ReceiptFailureAction.direct),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _FailureActionButton extends StatelessWidget {
  const _FailureActionButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: primary ? Colors.white : AppColors.text80,
        backgroundColor: primary ? AppColors.main : AppColors.selected,
        side: BorderSide(color: primary ? AppColors.main : AppColors.text20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    ),
  );
}
