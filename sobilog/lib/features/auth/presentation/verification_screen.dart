import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../shared/widgets/receipt_surface.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key, this.onVerified});

  final VoidCallback? onVerified;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        child: ColoredBox(
          color: AppColors.background,
          child: Stack(
            children: [
              Positioned(
                left: 33,
                top: 593,
                child: ReceiptSurface(
                  child: Stack(
                    children: [
                      const Positioned(
                        left: 53,
                        top: 61,
                        child: _AsteriskDivider(),
                      ),
                      const Positioned(
                        left: 231,
                        top: 146,
                        child: Text(
                          '인증번호를 입력하세요',
                          style: TextStyle(
                            color: Color(0xFF1B1B1B),
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 98,
                        top: 230,
                        child: Row(
                          children: List.generate(6, (index) {
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index == 5 ? 0 : 16,
                              ),
                              child: GestureDetector(
                                onTap: onVerified,
                                child: Container(
                                  width: 68,
                                  height: 68,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B1B1B),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Amarante',
                                      fontSize: 40,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const Positioned(
                        left: 53,
                        top: 368,
                        child: _AsteriskDivider(),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 303,
                top: 1469,
                child: Text(
                  '팀 로고',
                  style: TextStyle(
                    color: AppColors.text50,
                    fontSize: 50,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AsteriskDivider extends StatelessWidget {
  const _AsteriskDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 577,
      height: 13,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          18,
          (_) => const Text(
            '*',
            style: TextStyle(
              color: Color(0x331B1B1B),
              fontSize: 20,
              height: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}
