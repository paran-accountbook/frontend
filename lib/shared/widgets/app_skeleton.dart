import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Shared skeleton treatment based on the Figma loading-state specification.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({required this.child, super.key});

  final Widget child;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) => ShaderMask(
      // srcIn applies the gradient alpha to the opaque placeholder. srcATop
      // would preserve the placeholder's alpha and make 10–20% colors appear
      // effectively opaque.
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [AppColors.text10, AppColors.text20, AppColors.text10],
        stops: const [0, .5, 1],
        transform: _SlidingGradientTransform(_controller.value),
      ).createShader(bounds),
      child: child,
    ),
  );
}

class AppSkeletonBox extends StatelessWidget {
  const AppSkeletonBox({
    required this.width,
    required this.height,
    this.radius = 5,
    this.shape = BoxShape.rectangle,
    super.key,
  });

  final double width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.text,
      shape: shape,
      borderRadius: shape == BoxShape.rectangle
          ? BorderRadius.circular(radius)
          : null,
    ),
  );
}

class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({this.rows = 3, this.rowGap = 16, super.key});

  final int rows;
  final double rowGap;

  @override
  Widget build(BuildContext context) => AppSkeleton(
    child: Column(
      children: List.generate(
        rows,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == rows - 1 ? 0 : rowGap),
          child: const SizedBox(
            width: 354,
            height: 56,
            child: Row(
              children: [
                AppSkeletonBox(width: 27, height: 19),
                SizedBox(width: 10),
                AppSkeletonBox(width: 26, height: 26, shape: BoxShape.circle),
                SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeletonBox(width: 111, height: 17),
                    SizedBox(height: 9),
                    AppSkeletonBox(width: 58, height: 14),
                  ],
                ),
                Spacer(),
                AppSkeletonBox(width: 60, height: 24),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class AppSkeletonReceipt extends StatelessWidget {
  const AppSkeletonReceipt({this.height = 622, super.key});

  final double height;

  @override
  Widget build(BuildContext context) => AppSkeleton(
    child: SizedBox(
      width: 354,
      height: height,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child: AppSkeletonBox(width: 128, height: 30),
          ),
          SizedBox(height: 24),
          AppSkeletonBox(width: 354, height: 7),
          SizedBox(height: 24),
          _SkeletonReceiptRow(labelWidth: 54, valueWidth: 108),
          SizedBox(height: 18),
          _SkeletonReceiptRow(labelWidth: 54, valueWidth: 156),
          SizedBox(height: 18),
          _SkeletonReceiptRow(labelWidth: 54, valueWidth: 72),
          SizedBox(height: 18),
          _SkeletonReceiptRow(labelWidth: 54, valueWidth: 64),
          SizedBox(height: 24),
          AppSkeletonBox(width: 354, height: 7),
          SizedBox(height: 24),
          AppSkeletonBox(width: 72, height: 17),
          SizedBox(height: 18),
          AppSkeletonList(rows: 3),
        ],
      ),
    ),
  );
}

class _SkeletonReceiptRow extends StatelessWidget {
  const _SkeletonReceiptRow({
    required this.labelWidth,
    required this.valueWidth,
  });

  final double labelWidth;
  final double valueWidth;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      AppSkeletonBox(width: labelWidth, height: 14),
      AppSkeletonBox(width: valueWidth, height: 14),
    ],
  );
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.progress);

  final double progress;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (progress * 2 - 1), 0, 0);
}
