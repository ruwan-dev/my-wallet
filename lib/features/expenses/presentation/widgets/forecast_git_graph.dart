import 'package:flutter/material.dart';

enum TrackType { blow, fire, mojo, debt }

class TrackColors {
  static const Color blow = Color(0xFF38B2AC); // Pastel Cyan
  static const Color fire = Color(0xFFE05263); // Soft Red/Orange
  static const Color mojo = Color(0xFF3949AB); // Deep Blue
  static const Color debt = Color(0xFFB91C1C); // Dark Red
}

class ForecastTransfer {
  final TrackType from;
  final TrackType to;
  final double amount;
  final String label;
  final Color color;

  ForecastTransfer(this.from, this.to, this.amount, this.label, this.color);
}

class ForecastNode {
  final String monthLabel;
  final double fireBalance;
  final double mojoBalance;
  final double debtBalance;
  final double allocationAmount; // Direct to fire
  final List<ForecastTransfer> transfers;

  ForecastNode({
    required this.monthLabel,
    required this.fireBalance,
    required this.mojoBalance,
    required this.debtBalance,
    required this.allocationAmount,
    required this.transfers,
  });
}

class ForecastGitGraph extends StatelessWidget {
  final List<ForecastNode> nodes;

  const ForecastGitGraph({super.key, required this.nodes});

  @override
  Widget build(BuildContext context) {
    // 140 height per node + 60 padding at top/bottom
    return SizedBox(
      width: double.infinity,
      height: (nodes.length * 150.0) + 40.0,
      child: CustomPaint(
        painter: GitGraphPainter(nodes),
      ),
    );
  }
}

class GitGraphPainter extends CustomPainter {
  final List<ForecastNode> nodes;
  final double rowHeight = 150.0;
  final double trackSpacing = 40.0;
  final double startX = 30.0;

  GitGraphPainter(this.nodes);

  bool _isTrackActive(TrackType track, ForecastNode node) {
    if (track == TrackType.blow) return true;
    if (track == TrackType.fire) return true;
    if (track == TrackType.mojo && node.mojoBalance != 0) return true;
    if (track == TrackType.debt && node.debtBalance != 0) return true;
    for (var t in node.transfers) {
      if (t.from == track || t.to == track) return true;
    }
    return false;
  }

  double _getTrackX(TrackType track) {
    switch (track) {
      case TrackType.blow: return startX;
      case TrackType.fire: return startX + trackSpacing;
      case TrackType.mojo: return startX + trackSpacing * 2;
      case TrackType.debt: return startX + trackSpacing * 3;
    }
  }

  Color _getTrackColor(TrackType track) {
    switch (track) {
      case TrackType.blow: return TrackColors.blow;
      case TrackType.fire: return TrackColors.fire;
      case TrackType.mojo: return TrackColors.mojo;
      case TrackType.debt: return TrackColors.debt;
    }
  }

  void _drawText(Canvas canvas, String text, double x, double y, Color color, {double fontSize = 12, bool bold = false, TextAlign align = TextAlign.left}) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: align,
    );
    textPainter.layout();
    
    double dx = x;
    if (align == TextAlign.center) dx = x - textPainter.width / 2;
    if (align == TextAlign.right) dx = x - textPainter.width;
    
    textPainter.paint(canvas, Offset(dx, y));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final List<TrackType> allTracks = [TrackType.blow, TrackType.fire, TrackType.mojo, TrackType.debt];

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final double y = i * rowHeight + 100.0; // Y center of the current node
      final double prevY = i == 0 ? y - rowHeight / 1.5 : (i - 1) * rowHeight + 100.0;

      // 1. Draw vertical track lines
      for (final track in allTracks) {
        bool isActiveCurr = _isTrackActive(track, node);
        bool isActivePrev = i == 0 ? false : _isTrackActive(track, nodes[i - 1]);
        
        if (isActiveCurr || isActivePrev) {
          final x = _getTrackX(track);
          final paint = Paint()
            ..color = _getTrackColor(track).withOpacity(0.3)
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke;
            
          double lineStartY = isActivePrev ? prevY : y - rowHeight / 1.5;
          double lineEndY = isActiveCurr ? y : y - rowHeight / 1.5; // End early if it stops
          
          if (lineStartY != lineEndY) {
            canvas.drawLine(Offset(x, lineStartY), Offset(x, lineEndY), paint);
          }
        }
      }

      // 2. Draw Transfer Curves
      for (final transfer in node.transfers) {
        final fromX = _getTrackX(transfer.from);
        final toX = _getTrackX(transfer.to);
        
        final path = Path();
        path.moveTo(fromX, prevY);
        
        // Bezier curve for merging/branching
        path.cubicTo(
          fromX, prevY + (y - prevY) / 2, 
          toX, prevY + (y - prevY) / 2, 
          toX, y
        );

        // Gradient or colored stroke for the transfer line
        final paint = Paint()
          ..color = transfer.color.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
          
        canvas.drawPath(path, paint);

        // Transfer label at the apex
        final midX = (fromX + toX) / 2;
        final midY = (prevY + y) / 2;
        
        // Draw tiny pill background for label readability
        final labelPaint = Paint()..color = Colors.white.withOpacity(0.9);
        final labelRect = Rect.fromCenter(center: Offset(midX, midY), width: 70, height: 18);
        canvas.drawRRect(RRect.fromRectAndRadius(labelRect, const Radius.circular(8)), labelPaint);
        
        _drawText(canvas, transfer.label, midX, midY - 7, transfer.color, fontSize: 10, bold: true, align: TextAlign.center);
      }

      // 3. Draw Nodes (Dots)
      for (final track in allTracks) {
        if (_isTrackActive(track, node)) {
          final x = _getTrackX(track);
          final color = _getTrackColor(track);
          
          // Outer circle
          canvas.drawCircle(Offset(x, y), 8, Paint()..color = color.withOpacity(0.3));
          // Inner solid circle
          canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
        }
      }

      // 4. Draw Texts & Balances
      final textStartX = startX + (trackSpacing * 4) + 10;
      
      // Month Label
      _drawText(canvas, node.monthLabel, textStartX, y - 24, const Color(0xFF1E293B), fontSize: 14, bold: true);
      
      double currentTextY = y;
      
      // Allocation if exists
      if (node.allocationAmount > 0) {
         _drawText(canvas, '+ Income Alloc: ${node.allocationAmount.toStringAsFixed(0)}', textStartX, currentTextY, Colors.blue, fontSize: 11);
         currentTextY += 16;
      }
      
      // Bucket Balances
      if (_isTrackActive(TrackType.fire, node)) {
        _drawText(canvas, 'Fire: ${node.fireBalance.toStringAsFixed(2)}', textStartX, currentTextY, TrackColors.fire, fontSize: 12, bold: true);
        currentTextY += 18;
      }
      if (_isTrackActive(TrackType.mojo, node)) {
        _drawText(canvas, 'Mojo: ${node.mojoBalance.toStringAsFixed(2)}', textStartX, currentTextY, TrackColors.mojo, fontSize: 12, bold: true);
        currentTextY += 18;
      }
      if (_isTrackActive(TrackType.debt, node)) {
        _drawText(canvas, 'Debt: ${node.debtBalance.toStringAsFixed(2)}', textStartX, currentTextY, TrackColors.debt, fontSize: 12, bold: true);
        currentTextY += 18;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
