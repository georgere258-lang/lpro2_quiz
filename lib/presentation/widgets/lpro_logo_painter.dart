import 'package:flutter/material.dart';

class LProLogo extends StatelessWidget {
  final double size;
  final double opacity;

  const LProLogo({
    super.key,
    this.size = 200,
    this.opacity = 0.06,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        size: Size(size, size * 0.45),
        painter: _LProPainter(),
      ),
    );
  }
}

class _LProPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final textPaint = Paint()..color = Colors.white;
    final arrowPaint = Paint()..color = const Color(0xFFFF8C42);

    final w = size.width;
    final h = size.height;

    // L
    final lPath = Path()
      ..moveTo(0, 0)
      ..lineTo(h * 0.3, 0)
      ..lineTo(h * 0.3, h * 0.75)
      ..lineTo(w * 0.33, h * 0.75)
      ..lineTo(w * 0.33, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(lPath, textPaint);

    // Arrow ▶
    final arrow = Path()
      ..moveTo(w * 0.14, h * 0.28)
      ..lineTo(w * 0.26, h * 0.5)
      ..lineTo(w * 0.14, h * 0.72)
      ..close();

    canvas.drawPath(arrow, arrowPaint);

    // Pro
    final pro = Path();

    // P
    pro.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.38, h * 0.2, w * 0.08, h * 0.6),
      const Radius.circular(10),
    ));

    pro.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.46, h * 0.2, w * 0.12, h * 0.28),
      const Radius.circular(16),
    ));

    // r
    pro.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.61, h * 0.36, w * 0.06, h * 0.44),
      const Radius.circular(10),
    ));

    // o
    pro.addOval(Rect.fromLTWH(w * 0.7, h * 0.36, w * 0.14, h * 0.44));

    canvas.drawPath(pro, textPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
