import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import 'receipt_result_screen.dart';

class ReceiptScanLoadingScreen extends StatefulWidget {
  const ReceiptScanLoadingScreen({required this.imagePath, super.key});
  final String imagePath;
  @override
  State<ReceiptScanLoadingScreen> createState() =>
      _ReceiptScanLoadingScreenState();
}

class _ReceiptScanLoadingScreenState extends State<ReceiptScanLoadingScreen> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ReceiptResultScreen(imagePath: widget.imagePath),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
                const Text(
                  '영수증 인식중',
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
