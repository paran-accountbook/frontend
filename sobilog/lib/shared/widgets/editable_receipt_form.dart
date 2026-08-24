import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_assets.dart';
import 'receipt_surface.dart';

class EditableReceiptForm extends StatelessWidget {
  const EditableReceiptForm({
    super.key,
    this.income = false,
    this.draft = false,
  });

  final bool income;
  final bool draft;

  @override
  Widget build(BuildContext context) {
    return ReceiptSurface(
      width: 683,
      height: 1173,
      endColor: const Color(0xFFC5C5ED),
      child: Stack(
        children: [
          const Positioned(left: 53, top: 72, child: _PaperAsterisks()),
          Positioned(
            top: 130,
            width: 683,
            child: Row(
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
                const SizedBox(width: 7),
                Text(
                  income || draft ? '0' : '150,000',
                  style: const TextStyle(
                    color: Color(0xFF1B1B1B),
                    fontFamily: 'Amarante',
                    fontSize: 52,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 7),
                SvgPicture.asset(AppAssets.wonDark, width: 36, height: 39),
              ],
            ),
          ),
          Positioned(
            left: 53,
            top: 228,
            child: _FieldRow(
              label: '가맹점 명',
              value: income ? '수입처를 입력하세요' : (draft ? '소비로그' : '아주대학교 카페'),
            ),
          ),
          const Positioned(
            left: 53,
            top: 304,
            child: _FieldRow(label: '결제일시', value: '2026년 8월 19일 오전 10:30'),
          ),
          const Positioned(left: 53, top: 370, child: _PaperAsterisks()),
          const Positioned(
            top: 420,
            width: 683,
            child: Center(child: _AddButton()),
          ),
          Positioned(
            top: 522,
            child: _EditableItems(
              itemCount: income ? 1 : 5,
              zeroAmount: draft || income,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperAsterisks extends StatelessWidget {
  const _PaperAsterisks();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 577,
      height: 50,
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(color: Color(0x801B1B1B), fontSize: 23),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF1B1B1B),
                fontSize: 23,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 25),
          const Icon(Icons.close, color: Color(0x801B1B1B), size: 37),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SvgPicture.asset(AppAssets.addLight, width: 28, height: 28),
    );
  }
}

class _EditableItems extends StatelessWidget {
  const _EditableItems({required this.itemCount, required this.zeroAmount});

  final int itemCount;
  final bool zeroAmount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 683,
      child: Column(
        children: List.generate(
          itemCount,
          (_) => _EditableItem(zeroAmount: zeroAmount),
        ),
      ),
    );
  }
}

class _EditableItem extends StatelessWidget {
  const _EditableItem({required this.zeroAmount});

  final bool zeroAmount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: Stack(
        children: [
          const Positioned(
            left: 49,
            top: 0,
            child: SizedBox(
              width: 585,
              child: Divider(height: 1, thickness: 1, color: Color(0x141B1B1B)),
            ),
          ),
          const Positioned(
            left: 49,
            top: 27,
            child: Text(
              '커피',
              style: TextStyle(
                color: Color(0xFF1B1B1B),
                fontFamily: 'BujangnimNunchi',
                fontSize: 50,
              ),
            ),
          ),
          const Positioned(
            left: 49,
            top: 85,
            child: Text(
              'X 1',
              style: TextStyle(color: Color(0x801B1B1B), fontSize: 23),
            ),
          ),
          Positioned(
            right: 108,
            top: 49,
            child: Row(
              children: [
                Text(
                  zeroAmount ? '0' : '150,000',
                  style: const TextStyle(
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
          const Positioned(right: 39, top: 51, child: _CloseIcon()),
        ],
      ),
    );
  }
}

class _CloseIcon extends StatelessWidget {
  const _CloseIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(AppAssets.closeDark, width: 46, height: 46);
  }
}
