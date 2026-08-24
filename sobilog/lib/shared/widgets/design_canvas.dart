import 'package:flutter/material.dart';

class DesignCanvas extends StatelessWidget {
  const DesignCanvas({
    required this.child,
    super.key,
    this.width = 749,
    this.height = 1628,
  });

  final Widget child;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF121215),
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );
  }
}

class ScrollableDesignCanvas extends StatelessWidget {
  const ScrollableDesignCanvas({
    required this.child,
    super.key,
    this.width = 749,
    this.height = 2404,
  });

  final Widget child;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF121215),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / width;
          final safeTop = MediaQuery.viewPaddingOf(context).top;
          final safeTopInDesign = (safeTop / scale).clamp(0.0, height);
          final scrollExtent = (height - safeTopInDesign) * scale;

          return Padding(
            padding: EdgeInsets.only(top: safeTop),
            child: SingleChildScrollView(
              child: SizedBox(
                width: constraints.maxWidth,
                height: scrollExtent,
                child: Transform.translate(
                  offset: Offset(0, -safeTop),
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.topLeft,
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: width,
                      maxWidth: width,
                      minHeight: height,
                      maxHeight: height,
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
