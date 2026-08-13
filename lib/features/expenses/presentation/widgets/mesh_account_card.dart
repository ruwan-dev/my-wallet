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
    final baseColor = Color(account.colorValue);

    return Container(
      width: 170, // Slightly narrower
      height: 95, // Decreased height

      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(baseColor.withOpacity(0.15), Colors.white.withOpacity(0.9)),
            Color.alphaBlend(baseColor.withOpacity(0.25), Colors.white.withOpacity(0.85)),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Extremely soft, diffused shadow
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/account-transactions', extra: account),
            child: Stack(
              children: [
            // Connected Nodes Background
            Positioned.fill(
              child: CustomPaint(
                painter: ConnectedNodesPainter(
                  color: baseColor.withOpacity(0.35), // Colored nodes over pastel
                  seed: account.id.hashCode,
                ),
              ),
            ),
            
            // Card Content
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Chip icon
                      Icon(Icons.memory, color: baseColor.withOpacity(0.9), size: 20),
                      
                      // Account type label
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: baseColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: baseColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          account.type == AccountType.asset ? 'Debit' : 'Credit',
                          style: TextStyle(
                            color: baseColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    account.name,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.formatCurrency(context, account.balance.abs()),
                    style: const TextStyle(
                      color: Color(0xFF1E293B), // Dark Slate
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.0),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // First wavy line
    final path1 = Path();
    path1.moveTo(-20, h * 0.4);
    path1.quadraticBezierTo(w * 0.4, h * 0.6, w + 20, h * 0.2);
    canvas.drawPath(path1, paint);

    // Second wavy line
    final paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.0),
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path2 = Path();
    path2.moveTo(w * 0.2, h + 20);
    path2.quadraticBezierTo(w * 0.6, h * 0.4, w + 20, h * 0.7);
    canvas.drawPath(path2, paint2);
  }

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

    // Generate nodes
    final int numNodes = nodeCount;
    final List<Offset> nodes = [];
    for (int i = 0; i < numNodes; i++) {
      nodes.add(Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      ));
    }

    // Draw lines between close nodes
    final double maxDistance = 70.0;
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final double dist = (nodes[i] - nodes[j]).distance;
        if (dist < maxDistance) {
          // Opacity based on distance
          final double lineOpacity = (1.0 - (dist / maxDistance)) * 0.15;
          final linePaint = Paint()
            ..color = color.withOpacity(lineOpacity)
            ..strokeWidth = 1.0;
          canvas.drawLine(nodes[i], nodes[j], linePaint);
        }
      }
    }

    // Draw dots
    for (final node in nodes) {
      canvas.drawCircle(node, 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ConnectedNodesPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.seed != seed || oldDelegate.nodeCount != nodeCount;
  }
}
