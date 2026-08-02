import 'dart:ui';
import 'package:flutter/material.dart';

class PremiumAuroraBackground extends StatelessWidget {
  final Widget child;

  const PremiumAuroraBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Base background color
    final baseColor = isDark 
        ? const Color(0xFF0F172A) // Soft Dark Slate
        : const Color(0xFFF8FAFC); // Very Soft Off-White

    // Intense, highly saturated origin colors
    final colorBlue = isDark 
        ? const Color(0xFF0078FF) 
        : const Color(0xFF0088FF); // Deep Sky Blue
    final colorLavender = isDark 
        ? const Color(0xFF9D4EDD) 
        : const Color(0xFFB100E8); // Vibrant Lavender

    return Stack(
      children: [
        // 1. Solid Base Background
        Container(color: baseColor),

        // 2. Intense Blue Origin at Bottom-Left
        Positioned(
          bottom: -200,
          left: -200,
          child: Container(
            width: 1000,
            height: 1000,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorBlue, // Solid, intense center
                  colorBlue.withOpacity(0.6), // Holds strength midway
                  colorBlue.withOpacity(0.0), // Fades out at the edge
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // 3. Vibrant Lavender Origin offset slightly for blending
        Positioned(
          bottom: -100,
          left: 150,
          child: Container(
            width: 900,
            height: 900,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorLavender,
                  colorLavender.withOpacity(0.6),
                  colorLavender.withOpacity(0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // 4. Heavy blur to melt the intense colors into a smooth aurora
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),

        // 5. Foreground Content
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}
