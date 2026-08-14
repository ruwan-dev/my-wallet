import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/account.dart';
import '../../../../core/utils/formatters.dart';

class MeshAccountCard extends StatelessWidget {
  final AccountEntity account;

  const MeshAccountCard({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final teal = const Color(0xFF50C8C8);
    final baseColor = Color(account.colorValue);

    return GestureDetector(
      onTap: () => context.push('/account-transactions', extra: account),
      child: Container(
        width: 110,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              spreadRadius: 4,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teal circle icon with $ symbol
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: teal.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: teal.withOpacity(0.3), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '\$',
                    style: TextStyle(
                      color: teal,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                AppFormatters.formatCurrency(context, account.balance.abs()),
                style: const TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                account.name.toUpperCase(),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MeshBlob extends StatelessWidget {
  final Color color;
  final double size;

  const MeshBlob({super.key, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        shape: BoxShape.circle,
      ),
    );
  }
}

class GlassCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ConnectedNodesPainter extends CustomPainter {
  final Color color;
  final int seed;
  final int nodeCount;

  ConnectedNodesPainter({required this.color, required this.seed, this.nodeCount = 12});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed);
    final dotPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final int numNodes = nodeCount;
    final List<Offset> nodes = [];
    for (int i = 0; i < numNodes; i++) {
      nodes.add(Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      ));
    }

    final double maxDistance = 70.0;
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final double dist = (nodes[i] - nodes[j]).distance;
        if (dist < maxDistance) {
          final double lineOpacity = (1.0 - (dist / maxDistance)) * 0.15;
          final linePaint = Paint()
            ..color = color.withOpacity(lineOpacity)
            ..strokeWidth = 1.0;
          canvas.drawLine(nodes[i], nodes[j], linePaint);
        }
      }
    }

    for (final node in nodes) {
      canvas.drawCircle(node, 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ConnectedNodesPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.seed != seed ||
        oldDelegate.nodeCount != nodeCount;
  }
}
