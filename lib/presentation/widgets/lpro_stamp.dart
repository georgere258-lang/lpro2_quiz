import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LProStamp extends StatelessWidget {
  const LProStamp({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF003D3D), // لون الهيدر
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // السهم الأورانج
              Positioned(
                top: 8,
                right: 10,
                child: CustomPaint(
                  size: const Size(18, 18),
                  painter: _OrangeArrowPainter(),
                ),
              ),

              // L Pro
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'L',
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  Text(
                    'Pro',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'المعلومة بتفرق',
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4FA8A8),
          ),
        ),
      ],
    );
  }
}

class _OrangeArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF8C42) // أورانج اللوجو
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.5);
    path.lineTo(size.width * 0.7, size.height * 0.15);
    path.lineTo(size.width * 0.7, size.height * 0.35);
    path.lineTo(size.width * 0.9, size.height * 0.35);
    path.lineTo(size.width * 0.9, size.height * 0.65);
    path.lineTo(size.width * 0.7, size.height * 0.65);
    path.lineTo(size.width * 0.7, size.height * 0.85);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
