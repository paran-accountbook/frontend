import 'package:flutter/material.dart';

class ReceiptSurface extends StatelessWidget {
  const ReceiptSurface({
    required this.child,
    super.key,
    this.width = 683,
    this.height = 442,
    this.endColor = const Color(0xFFE4E4FF),
  });

  final Widget child;
  final double width;
  final double height;
  final Color endColor;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const ReceiptClipper(),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, endColor],
          ),
        ),
        child: child,
      ),
    );
  }
}

class ReceiptClipper extends CustomClipper<Path> {
  const ReceiptClipper();

  @override
  Path getClip(Size size) {
    const tooth = 23.0;
    const depth = 16.0;
    final path = Path()..moveTo(0, depth);
    var x = 0.0;
    var down = false;
    while (x < size.width) {
      x = (x + tooth).clamp(0, size.width);
      path.lineTo(x, down ? depth : 0);
      down = !down;
    }
    path.lineTo(size.width, size.height - depth);
    x = size.width;
    down = false;
    while (x > 0) {
      x = (x - tooth).clamp(0, size.width);
      path.lineTo(x, down ? size.height - depth : size.height);
      down = !down;
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant ReceiptClipper oldClipper) => false;
}
