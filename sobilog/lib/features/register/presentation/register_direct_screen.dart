import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../shared/widgets/editable_receipt_form.dart';

class RegisterDirectScreen extends StatelessWidget {
  const RegisterDirectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        child: Stack(
          children: [
            Positioned(
              left: 55,
              top: 151,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.text,
                  size: 47,
                ),
              ),
            ),
            const Positioned(
              top: 164,
              width: 749,
              child: Text(
                '등록',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Positioned(
              left: 33,
              top: 246,
              child: EditableReceiptForm(draft: true),
            ),
            Positioned(
              left: 57,
              top: 1468,
              child: Container(
                width: 635,
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF33298F), AppColors.main],
                  ),
                  borderRadius: BorderRadius.circular(29),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  '저장',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
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
