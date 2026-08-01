import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import 'mesh_account_card.dart';

class AnimatedDashboardCard extends StatefulWidget {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final double fixedExpenses;

  const AnimatedDashboardCard({
    super.key,
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.fixedExpenses,
  });

  @override
  State<AnimatedDashboardCard> createState() => _AnimatedDashboardCardState();
}

class _AnimatedDashboardCardState extends State<AnimatedDashboardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Smooth, slow fluid movement
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double total = widget.totalIncome + widget.totalExpense;
    double incomeRatio = total == 0 ? 0.5 : widget.totalIncome / total;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // 1. Fluid Animated Background (Income/Expense Ratio)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _FluidPainter(
                      animationValue: _controller.value,
                      incomeRatio: incomeRatio,
                    ),
                  );
                },
              ),
            ),

            // 2. Glassmorphism Blur
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: const SizedBox.shrink(),
              ),
            ),

            // 3. Glassy curves overlay (matching the Account Cards)
            Positioned.fill(
              child: CustomPaint(
                painter: GlassCurvePainter(),
              ),
            ),

            // 4. Foreground UI
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppFormatters.formatCurrency(widget.totalBalance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      height: 1.1,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))
                      ]
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _CardStat(
                          icon: Icons.arrow_downward_rounded,
                          label: 'Income',
                          value: AppFormatters.formatCurrency(widget.totalIncome),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      Expanded(
                        child: _CardStat(
                          icon: Icons.arrow_upward_rounded,
                          label: 'Expenses',
                          value: AppFormatters.formatCurrency(widget.totalExpense),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      Expanded(
                        child: _CardStat(
                          icon: Icons.lock_outline_rounded,
                          label: 'Fixed',
                          value: AppFormatters.formatCurrency(widget.fixedExpenses),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CardStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    shadows: [
                      Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1)),
                    ],
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FluidPainter extends CustomPainter {
  final double animationValue;
  final double incomeRatio;

  _FluidPainter({
    required this.animationValue,
    required this.incomeRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double t = animationValue * 2 * pi;
    final double w = size.width;
    final double h = size.height;

    // Map the ratio so the clash point moves horizontally
    final double mappedRatio = 0.1 + (incomeRatio * 0.8);
    final double clashX = w * mappedRatio;
    
    // How much the wave leans diagonally
    final double lean = w * 0.15;

    // Background color (Premium Deep Indigo)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF1E1B4B),
    );

    // Cyan/Teal fluid layers (left side - Income)
    _drawFluidPath(
      canvas: canvas,
      size: size,
      clashX: clashX,
      lean: lean,
      t: t,
      isRightSide: false,
      phaseOffset: 0.0,
      amplitude: 25,
      colors: [const Color(0x660891B2), const Color(0x9906B6D4)],
    );
    _drawFluidPath(
      canvas: canvas,
      size: size,
      clashX: clashX,
      lean: lean,
      t: t,
      isRightSide: false,
      phaseOffset: 1.2,
      amplitude: 35,
      colors: [const Color(0x6622D3EE), const Color(0x8067E8F9)],
    );
    _drawFluidPath(
      canvas: canvas,
      size: size,
      clashX: clashX,
      lean: lean,
      t: t,
      isRightSide: false,
      phaseOffset: 2.4,
      amplitude: 45,
      colors: [const Color(0x33FFFFFF), const Color(0x4DA5F3FC)],
    );

    // Fuchsia/Magenta fluid layers (right side - Expenses)
    _drawFluidPath(
      canvas: canvas,
      size: size,
      clashX: clashX,
      lean: lean,
      t: t,
      isRightSide: true,
      phaseOffset: 3.0,
      amplitude: 30,
      colors: [const Color(0x66A21CAF), const Color(0x99C026D3)],
    );
    _drawFluidPath(
      canvas: canvas,
      size: size,
      clashX: clashX,
      lean: lean,
      t: t,
      isRightSide: true,
      phaseOffset: 4.5,
      amplitude: 40,
      colors: [const Color(0x66D946EF), const Color(0x80E879F9)],
    );
    _drawFluidPath(
      canvas: canvas,
      size: size,
      clashX: clashX,
      lean: lean,
      t: t,
      isRightSide: true,
      phaseOffset: 5.5,
      amplitude: 50,
      colors: [const Color(0x33FFFFFF), const Color(0x4DF0ABFC)],
    );
  }

  void _drawFluidPath({
    required Canvas canvas,
    required Size size,
    required double clashX,
    required double lean,
    required double t,
    required bool isRightSide,
    required double phaseOffset,
    required double amplitude,
    required List<Color> colors,
  }) {
    final double w = size.width;
    final double h = size.height;

    // Calculate top and bottom points of the vertical boundary
    final double topX = clashX - lean + sin(t + phaseOffset) * amplitude;
    final double bottomX = clashX + lean + cos(t + phaseOffset) * amplitude;

    // Control points for the bezier curve to create a wavy "S" shape (vertically)
    final double cp1Y = h * 0.33;
    final double cp1X = clashX + cos(t + phaseOffset + pi / 3) * amplitude * 1.5;

    final double cp2Y = h * 0.66;
    final double cp2X = clashX + sin(t + phaseOffset - pi / 3) * amplitude * 1.5;

    final Path path = Path();
    if (isRightSide) {
      path.moveTo(w, 0);
      path.lineTo(topX, 0);
      path.cubicTo(cp1X, cp1Y, cp2X, cp2Y, bottomX, h);
      path.lineTo(w, h);
    } else {
      path.moveTo(0, 0);
      path.lineTo(topX, 0);
      path.cubicTo(cp1X, cp1Y, cp2X, cp2Y, bottomX, h);
      path.lineTo(0, h);
    }
    path.close();
    
    // Gradient fill
    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: isRightSide ? Alignment.centerLeft : Alignment.centerRight,
        end: isRightSide ? Alignment.centerRight : Alignment.centerLeft,
        colors: colors,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
      
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _FluidPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.incomeRatio != incomeRatio;
  }
}
