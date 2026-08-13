import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/settings_cubit.dart';
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
    final settings = context.watch<SettingsCubit>().state;
    int nodeCount = (widget.totalBalance / settings.nodeDivisor).toInt();
    nodeCount = nodeCount.clamp(0, 150);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20), // Uniform radius
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1).withOpacity(0.85), // Soft deep purple/indigo
            const Color(0xFF8B5CF6).withOpacity(0.85), // Royal lavender
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: ConnectedNodesPainter(
                    color: Colors.white.withOpacity(0.4),
                    seed: widget.totalBalance.toInt(),
                    nodeCount: nodeCount,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text(
                  'Total Balance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.formatCurrency(context, widget.totalBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('Income', widget.totalIncome, Icons.arrow_downward_rounded, const Color(0xFF0EA5E9)),
                      Container(width: 1, height: 32, color: Colors.white.withOpacity(0.2)),
                      _buildStatItem('Expenses', widget.totalExpense, Icons.arrow_upward_rounded, const Color(0xFF9333EA)),
                      Container(width: 1, height: 32, color: Colors.white.withOpacity(0.2)),
                      _buildStatItem('Fixed', widget.fixedExpenses, Icons.push_pin_rounded, Colors.white.withOpacity(0.8)),
                    ],
                  ),
                ),
              ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double amount, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppFormatters.formatCurrency(context, amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
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
