import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';

class ReceiptEntryForm extends StatefulWidget {
  const ReceiptEntryForm({super.key, this.showMemo = false});
  final bool showMemo;
  @override
  State<ReceiptEntryForm> createState() => _ReceiptEntryFormState();
}

class _ReceiptEntryFormState extends State<ReceiptEntryForm> {
  final _quantities = <int>[3, 3, 3];
  int _paymentMethod = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _InfoRow(label: '가맹점 명', value: '아주대학교'),
        const SizedBox(height: 16),
        const _InfoRow(label: '결제일시', value: '2026년 9월 1일 오후 3:20'),
        const SizedBox(height: 16),
        const _InfoRow(label: '카테고리', value: '식비'),
        const SizedBox(height: 25),
        const _Asterisks(),
        const SizedBox(height: 20),
        Row(
          children: List.generate(
            3,
            (index) => Padding(
              padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
              child: GestureDetector(
                onTap: () => setState(() => _paymentMethod = index),
                child: Container(
                  width: index == 2 ? 92 : 79,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _paymentMethod == index
                        ? const Color(0xFFA8A3FF)
                        : AppColors.selected,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.outline, width: 0.5),
                  ),
                  child: Text(
                    const ['현금', '카드', '미지정'][index],
                    style: TextStyle(
                      color: _paymentMethod == index
                          ? const Color(0xFF1B1B1B)
                          : AppColors.text50,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 31),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('품목   3', style: _labelStyle),
            Text(
              '품목 추가 +',
              style: TextStyle(color: Color(0xFFA8A3FF), fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 13),
        ...List.generate(3, _buildItem),
        if (widget.showMemo) ...[
          const SizedBox(height: 20),
          Container(
            width: 354,
            height: 91,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF191A1F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('메모 (선택)', style: _valueStyle),
                SizedBox(height: 8),
                Text(
                  '안녕하세요',
                  style: TextStyle(color: AppColors.text50, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildItem(int index) {
    return Container(
      width: 354,
      height: 72,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x0DE2E2F9))),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('아메리카노', style: _valueStyle),
                SizedBox(height: 8),
                Text(
                  '단가   4,500원   13,500원',
                  style: TextStyle(color: AppColors.text50, fontSize: 12),
                ),
              ],
            ),
          ),
          _RoundControl(
            asset: AppAssets.receiptAddItem,
            onTap: () => setState(() => _quantities[index]++),
          ),
          SizedBox(
            width: 34,
            child: Text(
              _quantities[index].toString(),
              textAlign: TextAlign.center,
              style: _valueStyle,
            ),
          ),
          _RoundControl(
            asset: AppAssets.receiptRemoveItem,
            onTap: () => setState(() {
              if (_quantities[index] > 1) _quantities[index]--;
            }),
          ),
          const SizedBox(width: 6),
          SvgPicture.asset(AppAssets.receiptDeleteItem, width: 24, height: 24),
        ],
      ),
    );
  }
}

const _labelStyle = TextStyle(color: AppColors.text50, fontSize: 14);
const _valueStyle = TextStyle(
  color: AppColors.text,
  fontSize: 14,
  fontWeight: FontWeight.w500,
);

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: _labelStyle),
          Row(
            children: [
              Text(value, style: _valueStyle),
              const SizedBox(width: 6),
              const Text(
                '〉',
                style: TextStyle(color: AppColors.text, fontSize: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Asterisks extends StatelessWidget {
  const _Asterisks();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 354,
      child: Text(
        List.filled(18, '*').join('   '),
        maxLines: 1,
        style: const TextStyle(color: AppColors.text20, fontSize: 11),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({required this.asset, required this.onTap});
  final String asset;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.selected,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.outline, width: 0.5),
        ),
        child: SvgPicture.asset(asset),
      ),
    );
  }
}
