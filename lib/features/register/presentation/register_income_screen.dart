import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../shared/widgets/receipt_surface.dart';

class RegisterIncomeScreen extends StatelessWidget {
  const RegisterIncomeScreen({super.key});

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
            const Positioned(left: 33, top: 246, child: _IncomeReceipt()),
            Positioned(left: 57, top: 1468, child: _SaveButton()),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton();

  @override
  Widget build(BuildContext context) => Container(
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
  );
}

class _IncomeReceipt extends StatelessWidget {
  const _IncomeReceipt();

  @override
  Widget build(BuildContext context) {
    return ReceiptSurface(
      width: 683,
      height: 1173,
      endColor: const Color(0xFFC5C5ED),
      child: Stack(
        children: [
          const Positioned(left: 53, top: 72, child: _Asterisks()),
          Positioned(
            top: 130,
            width: 683,
            child: _Amount(value: '+0', size: 52),
          ),
          const Positioned(
            left: 53,
            top: 228,
            child: _Field(label: '이름', value: '소비로그'),
          ),
          const Positioned(
            left: 53,
            top: 304,
            child: _Field(label: '수입일', value: '2026년 8월 19일 오전 10:30'),
          ),
          const Positioned(left: 53, top: 370, child: _Asterisks()),
          const Positioned(left: 50, top: 426, child: _Categories()),
          const Positioned(left: 50, top: 522, child: _IncomeItem()),
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.value, required this.size});

  final String value;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text(
        '총',
        style: TextStyle(
          color: Color(0xFF1B1B1B),
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(width: 8),
      Text(
        value,
        style: TextStyle(
          color: const Color(0xFF1B1B1B),
          fontFamily: 'Amarante',
          fontSize: size,
          height: 1,
        ),
      ),
      const SizedBox(width: 7),
      SvgPicture.asset(AppAssets.wonDark, width: 36, height: 39),
    ],
  );
}

class _Asterisks extends StatelessWidget {
  const _Asterisks();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 577,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        18,
        (_) => const Text(
          '*',
          style: TextStyle(color: Color(0x331B1B1B), fontSize: 20),
        ),
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 577,
    height: 50,
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0x801B1B1B), fontSize: 23),
        ),
        const SizedBox(width: 30),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1B1B1B),
                fontSize: 23,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 25),
        const Icon(Icons.close, color: Color(0x801B1B1B), size: 37),
      ],
    ),
  );
}

class _Categories extends StatelessWidget {
  const _Categories();

  @override
  Widget build(BuildContext context) {
    const labels = ['전체', '식비', '교통', '의료', '문화', '○○'];
    return SizedBox(
      width: 633,
      height: 58,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: labels
            .map(
              (label) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 23),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: label == '전체'
                      ? const Color(0xFF1B1B1B)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  border: label == '전체'
                      ? null
                      : Border.all(color: const Color(0xFF1B1B1B)),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: label == '전체'
                        ? Colors.white
                        : const Color(0xFF1B1B1B),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _IncomeItem extends StatelessWidget {
  const _IncomeItem();

  @override
  Widget build(BuildContext context) => Container(
    width: 583,
    height: 148,
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0x141B1B1B))),
    ),
    child: Stack(
      children: [
        const Positioned(
          top: 43,
          child: Text(
            '용돈',
            style: TextStyle(
              color: Color(0xFF1B1B1B),
              fontFamily: 'BujangnimNunchi',
              fontSize: 39,
              height: 1,
            ),
          ),
        ),
        Positioned(
          right: 57,
          top: 49,
          child: Row(
            children: [
              const Text(
                '+0',
                style: TextStyle(
                  color: Color(0xFF1B1B1B),
                  fontFamily: 'Amarante',
                  fontSize: 40,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              SvgPicture.asset(AppAssets.wonDark, width: 29, height: 31),
            ],
          ),
        ),
        const Positioned(
          right: 0,
          top: 49,
          child: Icon(Icons.close, color: Color(0x801B1B1B), size: 39),
        ),
      ],
    ),
  );
}
