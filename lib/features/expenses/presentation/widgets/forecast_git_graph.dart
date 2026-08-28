import 'package:flutter/material.dart';

enum TrackType { blow, smile, fire, mojo, grow, debt }

class TrackColors {
  static const Color blow = Color(0xFF38B2AC); // Pastel Cyan
  static const Color smile = Color(0xFFD946EF); // Fuchsia/Pink
  static const Color fire = Color(0xFFE05263); // Soft Red/Orange
  static const Color mojo = Color(0xFF3949AB); // Deep Blue
  static const Color grow = Color(0xFF10B981); // Emerald Green
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
  final String fireBalanceStr;
  final double mojoBalance;
  final String mojoBalanceStr;
  final double debtBalance;
  final String debtBalanceStr;
  final double allocationAmount; // Direct to fire
  final String allocationAmountStr;
  final List<ForecastTransfer> transfers;

  ForecastNode({
    required this.monthLabel,
    required this.fireBalance,
    required this.fireBalanceStr,
    required this.mojoBalance,
    required this.mojoBalanceStr,
    required this.debtBalance,
    required this.debtBalanceStr,
    required this.allocationAmount,
    required this.allocationAmountStr,
    required this.transfers,
  });
}

class ForecastGitGraph extends StatelessWidget {
  final List<ForecastNode> nodes;

  const ForecastGitGraph({super.key, required this.nodes});

  @override
  Widget build(BuildContext context) {
    // Show precisely two months on the screen at a time
    final double screenWidth = MediaQuery.of(context).size.width;
    final double colWidth = screenWidth / 2.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        width: (nodes.length * colWidth),
        height: 280.0,
        child: CustomPaint(
          painter: GitGraphPainter(nodes, colWidth),
        ),
      ),
    );
  }
}

class GitGraphPainter extends CustomPainter {
  final List<ForecastNode> nodes;
  final double colWidth;
  
  final double trackSpacing = 28.0; 
  final double startY = 30.0;

  GitGraphPainter(this.nodes, this.colWidth);

  List<TrackType> _getGloballyActiveTracks() {
    Set<TrackType> active = {TrackType.blow, TrackType.fire, TrackType.mojo}; // Base tracks always active
    
    for (final node in nodes) {
      if (node.mojoBalance != 0) active.add(TrackType.mojo);
      if (node.debtBalance != 0) active.add(TrackType.debt);
      for (final t in node.transfers) {
        active.add(t.from);
        active.add(t.to);
      }
    }
    
    // Sort them in the standard order
    final all = [TrackType.blow, TrackType.smile, TrackType.fire, TrackType.mojo, TrackType.grow, TrackType.debt];
    return all.where((t) => active.contains(t)).toList();
  }

  double _getTrackY(TrackType track, List<TrackType> activeTracks) {
    int index = activeTracks.indexOf(track);
    if (index == -1) return startY;
    return startY + (index * trackSpacing);
  }

  Color _getTrackColor(TrackType track) {
    switch (track) {
      case TrackType.blow: return TrackColors.blow;
      case TrackType.smile: return TrackColors.smile;
      case TrackType.fire: return TrackColors.fire;
      case TrackType.mojo: return TrackColors.mojo;
      case TrackType.grow: return TrackColors.grow;
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
    final List<TrackType> activeTracks = _getGloballyActiveTracks();

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      
      final double x = (i * colWidth) + (colWidth / 2); // Exact horizontal center of this col
      final double prevX = i == 0 ? x - (colWidth / 1.5) : ((i - 1) * colWidth) + (colWidth / 2);

      // 1. Draw continuous horizontal track lines
      for (final track in activeTracks) {
        final y = _getTrackY(track, activeTracks);
        final paint = Paint()
          ..color = _getTrackColor(track).withValues(alpha: 0.3)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
          
        // Draw continuously from left to right
        canvas.drawLine(Offset(prevX, y), Offset(x, y), paint);
      }

      // 2. Draw Transfer Curves
      for (final transfer in node.transfers) {
        final fromY = _getTrackY(transfer.from, activeTracks);
        final toY = _getTrackY(transfer.to, activeTracks);
        
        final path = Path();
        path.moveTo(prevX, fromY);
        
        // Single thick Bezier curve branching OUT and merging INTO the target track horizontally
        path.cubicTo(
          prevX + (x - prevX) / 2, fromY, 
          prevX + (x - prevX) / 2, toY, 
          x, toY
        );

        // Colored stroke for the transfer line
        final paint = Paint()
          ..color = transfer.color.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
          
        canvas.drawPath(path, paint);

        // Transfer label at the apex
        final midX = (prevX + x) / 2;
        final midY = (fromY + toY) / 2;
        
        // Draw tiny pill background for label readability
        final labelPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
        final labelRect = Rect.fromCenter(center: Offset(midX, midY), width: 70, height: 18);
        canvas.drawRRect(RRect.fromRectAndRadius(labelRect, const Radius.circular(8)), labelPaint);
        
        _drawText(canvas, transfer.label, midX, midY - 7, transfer.color, fontSize: 10, bold: true, align: TextAlign.center);
      }

      // 3. Draw Nodes (Dots)
      for (final track in activeTracks) {
        final y = _getTrackY(track, activeTracks);
        final color = _getTrackColor(track);
        
        // Outer circle
        canvas.drawCircle(Offset(x, y), 8, Paint()..color = color.withValues(alpha: 0.3));
        // Inner solid circle
        canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
      }

      // 4. Draw Texts & Balances BELOW the tracks
      double textStartY = startY + (activeTracks.length * trackSpacing) + 20;
      double currentTextY = textStartY;
      
      // Month Label
      _drawText(canvas, node.monthLabel, x, currentTextY, const Color(0xFF1E293B), fontSize: 13, bold: true, align: TextAlign.center);
      currentTextY += 20;
      
      // Allocation if exists
      if (node.allocationAmount > 0) {
         _drawText(canvas, '+ Income Alloc: ${node.allocationAmountStr}', x, currentTextY, Colors.blue, fontSize: 11, align: TextAlign.center);
         currentTextY += 18;
      }
      
      // Bucket Balances
      if (activeTracks.contains(TrackType.fire)) {
        _drawText(canvas, 'Fire: ${node.fireBalanceStr}', x, currentTextY, TrackColors.fire, fontSize: 12, bold: true, align: TextAlign.center);
        currentTextY += 18;
      }
      if (activeTracks.contains(TrackType.mojo)) {
        _drawText(canvas, 'Mojo: ${node.mojoBalanceStr}', x, currentTextY, TrackColors.mojo, fontSize: 12, bold: true, align: TextAlign.center);
        currentTextY += 18;
      }
      if (activeTracks.contains(TrackType.debt)) {
        _drawText(canvas, 'Debt: ${node.debtBalanceStr}', x, currentTextY, TrackColors.debt, fontSize: 12, bold: true, align: TextAlign.center);
        currentTextY += 18;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
