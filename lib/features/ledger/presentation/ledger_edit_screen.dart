import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../shared/widgets/editable_receipt_form.dart';

class LedgerEditScreen extends StatelessWidget {
  const LedgerEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        child: Stack(
          children: [
            Positioned(
              left: 32,
              top: 133,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: SvgPicture.asset(
                  AppAssets.arrowBackLight,
                  width: 70,
                  height: 70,
                ),
              ),
            ),
            const Positioned(
              top: 151,
              width: 749,
              child: Text(
                '내역 수정',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Positioned(
              right: 32,
              top: 133,
              child: SizedBox(
                width: 70,
                height: 70,
                child: SvgPicture.asset(AppAssets.deleteRed),
              ),
            ),
            const Positioned(
              left: 46,
              top: 269,
              child: EditableReceiptForm(compact: true),
            ),
            Positioned(
              left: 46,
              top: 1466,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 655,
                  height: 102,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF252552), AppColors.main],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0x4DE2E2F9)),
                  ),
                  child: const Text(
                    '저장',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
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
