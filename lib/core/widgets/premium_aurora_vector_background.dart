import 'package:flutter/material.dart';
import 'dart:ui';

class PremiumAuroraVectorBackground extends StatelessWidget {
  final Widget child;

  const PremiumAuroraVectorBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full screen vector art background
        Positioned.fill(
          child: CustomPaint(
            painter: _AuroraVectorPainter(),
          ),
        ),

        // Foreground Content
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}

class _AuroraVectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Base Layer — soft teal-white (matches home page F2F8F7)
    final basePaint = Paint()
      ..color = const Color(0xFFF2F8F7);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), basePaint);

    // 2. Middle Layer — deep teal wave covering top ~80%
    final path1 = Path();
    path1.moveTo(0, 0);
    path1.lineTo(0, h * 0.55);
    path1.quadraticBezierTo(w * 0.45, h * 0.90, w, h * 0.50);
    path1.lineTo(w, 0);
    path1.close();

    final paint1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF3AAFA9), // deeper teal
          Color(0xFF60C5B8), // mid teal/cyan
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.85));

    canvas.drawPath(path1, paint1);

    // 3. Top Layer — bright cyan/teal wave covering top ~55%
    final path2 = Path();
    path2.moveTo(0, 0);
    path2.lineTo(0, h * 0.45);
    path2.quadraticBezierTo(w * 0.5, h * 0.65, w, h * 0.20);
    path2.lineTo(w, 0);
    path2.close();

    final paint2 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF7CDBD4), // light cyan
          Color(0xFF50C8C8), // home page teal accent
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.65));

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
