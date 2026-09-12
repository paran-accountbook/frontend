import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/design_canvas.dart';
import '../../../shared/widgets/gradient_action_button.dart';
import '../../home/presentation/home_screen.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key, this.onAgreed});

  final VoidCallback? onAgreed;

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  final _selected = List.filled(5, false);

  void _agree() {
    if (widget.onAgreed case final callback?) {
      callback();
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        child: ColoredBox(
          color: AppColors.background,
          child: Stack(
            children: [
              const Positioned(
                left: 46,
                top: 214,
                child: Text(
                  '약관동의',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 50,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Positioned(
                left: 46,
                top: 299,
                width: 633,
                child: Text(
                  '소비로그를 사용하기 위해서\n아래 약관의 동의가 필요합니다',
                  style: TextStyle(
                    color: AppColors.text80,
                    fontSize: 30,
                    height: 1.35,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 839,
                width: 749,
                child: Column(
                  children: List.generate(5, (index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: index == 4 ? 0 : 14),
                      child: _TermsRow(
                        selected: _selected[index],
                        onPressed: () {
                          setState(() => _selected[index] = !_selected[index]);
                        },
                      ),
                    );
                  }),
                ),
              ),
              Positioned(
                left: 58,
                top: 1466,
                child: GradientActionButton(label: '동의합니다', onPressed: _agree),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({required this.selected, required this.onPressed});

  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: 749,
        height: 87,
        child: Stack(
          children: [
            Positioned(
              left: 46,
              top: 21.5,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? AppColors.main : AppColors.selected,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.text30),
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 30)
                    : null,
              ),
            ),
            const Positioned(
              left: 109,
              top: 23,
              child: Text(
                '예시',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              right: 52,
              top: 26.5,
              width: 34,
              height: 20,
              child: RotatedBox(
                quarterTurns: 3,
                child: SvgPicture.asset(AppAssets.arrowDown),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
