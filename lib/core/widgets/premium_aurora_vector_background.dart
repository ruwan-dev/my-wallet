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

    // 1. Base Layer (Bottom-most, fills the screen)
    // The image has a soft violet/purple base.
    final basePaint = Paint()
      ..color = const Color(0xFF9270F3); // Soft Violet
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), basePaint);

    // 2. Middle Layer (Covers top ~80% with a curved bottom)
    final path1 = Path();
    path1.moveTo(0, 0);
    path1.lineTo(0, h * 0.55); // Starts halfway down the left side
    // Curves down to ~85% in the middle, then up to ~65% on the right side
    path1.quadraticBezierTo(w * 0.45, h * 0.90, w, h * 0.50);
    path1.lineTo(w, 0);
    path1.close();

    final paint1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFDF8BEA), // Soft Pink
          Color(0xFFB17BE8), // Blend to Purple
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.85));
      
    canvas.drawPath(path1, paint1);

    // 3. Top Layer (Covers top ~55% with a curved bottom)
    final path2 = Path();
    path2.moveTo(0, 0);
    path2.lineTo(0, h * 0.45); // Starts 45% down the left side
    // Curves down to ~60% in the middle, then up to ~30% on the right side
    path2.quadraticBezierTo(w * 0.5, h * 0.65, w, h * 0.20);
    path2.lineTo(w, 0);
    path2.close();

    final paint2 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE89EE2), // Light Pink
          Color(0xFFCE88E6), // Blend to mid Pink
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.65));
      
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
