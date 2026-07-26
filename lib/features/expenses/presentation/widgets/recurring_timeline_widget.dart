import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';

class RecurringBranchEvent {
  final DateTime expectedDate;
  final DateTime? actualDate;
  final double amount;
  final bool isPaid;
  final String statusText;
  final Color statusColor;

  const RecurringBranchEvent({
    required this.expectedDate,
    this.actualDate,
    this.amount = 0.0,
    this.isPaid = false,
    required this.statusText,
    required this.statusColor,
  });
}

class RecurringTimelineWidget extends StatelessWidget {
  final List<RecurringBranchEvent> events;
  final double rowHeight;

  const RecurringTimelineWidget({
    super.key,
    required this.events,
    this.rowHeight = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Canvas Drawing the Git-Branch Lines
            Positioned.fill(
              child: CustomPaint(
                painter: _GitBranchTimelinePainter(
                  events: events,
                  rowHeight: rowHeight,
                ),
              ),
            ),
            // Foreground Content Layout
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(events.length, (index) {
                final event = events[index];
                
                bool isDivergent = event.actualDate != null && 
                  (event.statusText.toLowerCase().contains('early') || 
                   event.statusText.toLowerCase().contains('late'));
                
                return Container(
                  height: rowHeight,
                  padding: EdgeInsets.only(
                    left: isDivergent ? 110.0 : 70.0, // Indent based on whether node is on trunk or branch
                    right: 16.0,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Expected: ${AppFormatters.formatDate(event.expectedDate)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                          ),
                          if (event.amount > 0)
                            Text(
                              AppFormatters.formatCurrency(event.amount),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (event.actualDate != null)
                            Text('Paid: ${AppFormatters.formatDate(event.actualDate!)}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))
                          else
                            const Text('Scheduled', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: event.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              event.statusText,
                              style: TextStyle(color: event.statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _GitBranchTimelinePainter extends CustomPainter {
  final List<RecurringBranchEvent> events;
  final double rowHeight;

  _GitBranchTimelinePainter({
    required this.events,
    required this.rowHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double trunkX = 30.0;
    final double branchX = 80.0; // The X coordinate for divergent branches

    final trunkPaint = Paint()
      ..color = const Color(0xFFE2E8F0) // slate-200
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // 1. Draw the theoretical schedule Trunk Line from top to bottom
    // We stop at the last element's Y center
    final lastY = ((events.length - 1) * rowHeight) + (rowHeight / 2);
    final firstY = rowHeight / 2;
    if (events.length > 1) {
      canvas.drawLine(Offset(trunkX, firstY), Offset(trunkX, lastY), trunkPaint);
    }

    // 2. Draw lines for Actual Payments (branches and merges)
    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      final y = (i * rowHeight) + (rowHeight / 2);

      if (event.isPaid) {
        final branchPaint = Paint()
          ..color = event.statusColor
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        bool isDivergent = event.actualDate != null && 
                  (event.statusText.toLowerCase().contains('early') || 
                   event.statusText.toLowerCase().contains('late'));

        if (isDivergent) {
          final path = Path();
          
          double startY = i == 0 ? 0 : y - (rowHeight / 2);
          double endY = i == events.length - 1 ? size.height : y + (rowHeight / 2);

          // Start from trunk
          path.moveTo(trunkX, startY);
          
          // Curve out to branch node
          path.cubicTo(
            trunkX, startY + 15,
            branchX, y - 15,
            branchX, y,
          );
          
          // Curve back to trunk if it's not the very last event
          if (i != events.length - 1) {
            path.cubicTo(
              branchX, y + 15,
              trunkX, endY - 15,
              trunkX, endY,
            );
          }

          canvas.drawPath(path, branchPaint);
        } else {
          // On time: draw the colored line directly OVER the trunk for this segment
          double startY = i == 0 ? y : y - (rowHeight / 2);
          double endY = i == events.length - 1 ? y : y + (rowHeight / 2);
          canvas.drawLine(Offset(trunkX, startY), Offset(trunkX, endY), branchPaint);
        }
      }
    }

    // 3. Draw Nodes (Dots) on top of lines
    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      final y = (i * rowHeight) + (rowHeight / 2);

      bool isDivergent = event.isPaid && event.actualDate != null && 
                  (event.statusText.toLowerCase().contains('early') || 
                   event.statusText.toLowerCase().contains('late'));

      // Draw the Scheduled trunk dot (small, grey)
      final trunkDotPaint = Paint()
        ..color = const Color(0xFFCBD5E1) // slate-300
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(trunkX, y), 5, trunkDotPaint);

      // Draw the Actual Payment dot (colored)
      if (event.isPaid) {
        final double nodeX = isDivergent ? branchX : trunkX;

        // Outer colored ring
        final nodeOuterPaint = Paint()
          ..color = event.statusColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(nodeX, y), 8, nodeOuterPaint);

        // Inner white circle
        final nodeInnerPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(nodeX, y), 4, nodeInnerPaint);
      } else {
        // Pending Payment: Draw a hollow colored ring over the trunk dot
        final pendingPaint = Paint()
          ..color = event.statusColor
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(trunkX, y), 7, pendingPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GitBranchTimelinePainter oldDelegate) {
    return oldDelegate.events != events || oldDelegate.rowHeight != rowHeight;
  }
}
