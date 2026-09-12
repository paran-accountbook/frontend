import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';

class LedgerDetailScreen extends StatelessWidget {
  const LedgerDetailScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            Positioned(
              right: 24,
              top: 50,
              height: 36,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.text20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  '더치페이 하기',
                  style: TextStyle(color: AppColors.text, fontSize: 12),
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 112,
              width: 354,
              height: 622,
              child: _ReceiptDetail(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: SvgPicture.asset(
            AppAssets.homeReceiptCompact,
            fit: BoxFit.fill,
          ),
        ),
        const Positioned(
          left: 17,
          right: 17,
          top: 30,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('총 ', style: _darkLabel),
                  Text('40,500', style: _darkAmount),
                  SizedBox(width: 4),
                  Text('원', style: _darkLabel),
                ],
              ),
              SizedBox(height: 20),
              _DarkAsterisks(),
              SizedBox(height: 16),
              _DetailRow(label: '가맹점 명', value: '아주대학교 카페'),
              _DetailRow(label: '결제일시', value: '2026년 9월 1일 오후 3:20'),
              _DetailRow(label: '카테고리', value: '식비'),
              _DetailRow(label: '결제수단', value: '현금'),
              SizedBox(height: 10),
              _DarkAsterisks(),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('품목   3', style: _darkMuted),
                  Text(
                    '수정  〉',
                    style: TextStyle(color: AppColors.main, fontSize: 12),
                  ),
                ],
              ),
              SizedBox(height: 8),
              _DetailItem(name: '아메리카노', quantity: 3),
              _DetailItem(name: '카페라떼', quantity: 1),
              _DetailItem(name: '아메리카노', quantity: 3),
              SizedBox(height: 8),
              _DarkAsterisks(),
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('소비사진  1', style: _darkMuted),
              ),
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: _PhotoPlaceholder(),
              ),
              SizedBox(height: 10),
              _DarkAsterisks(),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('메모', style: _darkMuted),
                  Text('과제하다가 친구랑 마심', style: _darkLabel),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _darkLabel = TextStyle(
  color: Color(0xFF1B1B1B),
  fontSize: 12,
  fontWeight: FontWeight.w500,
);
const _darkMuted = TextStyle(color: Color(0x80121215), fontSize: 12);
const _darkAmount = TextStyle(
  color: Color(0xFF1B1B1B),
  fontFamily: 'Amarante',
  fontSize: 28,
);

class _DarkAsterisks extends StatelessWidget {
  const _DarkAsterisks();
  @override
  Widget build(BuildContext context) => Text(
    List.filled(18, '*').join('   '),
    maxLines: 1,
    style: const TextStyle(color: Color(0x33121215), fontSize: 10),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: _darkMuted),
        Text(value, style: _darkLabel),
      ],
    ),
  );
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.name, required this.quantity});
  final String name;
  final int quantity;
  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0x0D121215))),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: _darkLabel),
              const SizedBox(height: 5),
              const Text('단가   4,500원    13,500원', style: _darkMuted),
            ],
          ),
        ),
        Text('$quantity개', style: _darkLabel),
      ],
    ),
  );
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
    width: 50,
    height: 50,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.image, color: AppColors.main, size: 24),
  );
}
