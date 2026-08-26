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
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Canvas Drawing the Timeline
            Positioned.fill(
              child: CustomPaint(
                painter: _StraightTimelinePainter(
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
                
                return Container(
                  height: rowHeight,
                  padding: const EdgeInsets.only(
                    left: 60.0,
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
                              AppFormatters.formatCurrency(context, event.amount),
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
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
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

class _StraightTimelinePainter extends CustomPainter {
  final List<RecurringBranchEvent> events;
  final double rowHeight;

  _StraightTimelinePainter({
    required this.events,
    required this.rowHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double trunkX = 30.0;

    final trunkPaint = Paint()
      ..color = const Color(0xFFE2E8F0) // slate-200
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // 1. Draw the theoretical schedule Trunk Line from top to bottom
    final lastY = ((events.length - 1) * rowHeight) + (rowHeight / 2);
    final firstY = rowHeight / 2;
    if (events.length > 1) {
      canvas.drawLine(Offset(trunkX, firstY), Offset(trunkX, lastY), trunkPaint);
    }

    // 2. Draw lines for Actual Payments straight down the trunk
    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      final y = (i * rowHeight) + (rowHeight / 2);

      if (event.isPaid) {
        final branchPaint = Paint()
          ..color = event.statusColor
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        double startY = i == 0 ? y : y - (rowHeight / 2);
        double endY = i == events.length - 1 ? y : y + (rowHeight / 2);
        canvas.drawLine(Offset(trunkX, startY), Offset(trunkX, endY), branchPaint);
      }
    }

    // 3. Draw Nodes (Dots) strictly on the single line
    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      final y = (i * rowHeight) + (rowHeight / 2);

      // Base dot
      final trunkDotPaint = Paint()
        ..color = const Color(0xFFCBD5E1) // slate-300
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(trunkX, y), 5, trunkDotPaint);


    }
  }

  @override
  bool shouldRepaint(covariant _StraightTimelinePainter oldDelegate) {
    return oldDelegate.events != events || oldDelegate.rowHeight != rowHeight;
  }
}
