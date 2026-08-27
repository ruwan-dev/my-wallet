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
    // 140 height per node
    return SizedBox(
      width: double.infinity,
      height: (nodes.length * 140.0) + 20.0,
      child: CustomPaint(
        painter: GitGraphPainter(nodes),
      ),
    );
  }
}

class GitGraphPainter extends CustomPainter {
  final List<ForecastNode> nodes;
  final double rowHeight = 140.0;
  final double trackSpacing = 35.0; // Squeeze slightly to fit more tracks
  final double startX = 30.0;

  GitGraphPainter(this.nodes);

  List<TrackType> _getGloballyActiveTracks() {
    Set<TrackType> active = {TrackType.blow, TrackType.fire}; // Base tracks always active
    
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

  double _getTrackX(TrackType track, List<TrackType> activeTracks) {
    int index = activeTracks.indexOf(track);
    if (index == -1) return startX;
    return startX + (index * trackSpacing);
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
      final double y = (i * rowHeight) + (rowHeight / 2); // Exact vertical center of this row
      final double prevY = i == 0 ? y - (rowHeight / 1.5) : ((i - 1) * rowHeight) + (rowHeight / 2);

      // 1. Draw continuous vertical track lines
      for (final track in activeTracks) {
        final x = _getTrackX(track, activeTracks);
        final paint = Paint()
          ..color = _getTrackColor(track).withOpacity(0.3)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
          
        double lineStartY = prevY;
        double lineEndY = y;
        
        // Draw continuously from top to bottom
        canvas.drawLine(Offset(x, lineStartY), Offset(x, lineEndY), paint);
      }

      // 2. Draw Transfer Curves
      for (final transfer in node.transfers) {
        final fromX = _getTrackX(transfer.from, activeTracks);
        final toX = _getTrackX(transfer.to, activeTracks);
        
        final path = Path();
        path.moveTo(fromX, prevY);
        
        // Single thick Bezier curve branching OUT and merging INTO the target track
        path.cubicTo(
          fromX, prevY + (y - prevY) / 2, 
          toX, prevY + (y - prevY) / 2, 
          toX, y
        );

        // Colored stroke for the transfer line
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
      for (final track in activeTracks) {
        final x = _getTrackX(track, activeTracks);
        final color = _getTrackColor(track);
        
        // Outer circle
        canvas.drawCircle(Offset(x, y), 8, Paint()..color = color.withOpacity(0.3));
        // Inner solid circle
        canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
      }

      // 4. Draw Texts & Balances
      final textStartX = startX + (activeTracks.length * trackSpacing) + 10;
      
      // Calculate total block height to vertically center it around y
      int lineCount = 1; // Month Label
      if (node.allocationAmount > 0) lineCount++;
      if (activeTracks.contains(TrackType.fire)) lineCount++;
      if (activeTracks.contains(TrackType.mojo)) lineCount++;
      if (activeTracks.contains(TrackType.debt)) lineCount++;
      
      // month label is 14pt (takes ~16px height), other lines are 12pt (take ~14px height), plus spacing
      double totalHeight = 16.0 + ((lineCount - 1) * 18.0);
      double currentTextY = y - (totalHeight / 2);
      
      // Month Label
      _drawText(canvas, node.monthLabel, textStartX, currentTextY, const Color(0xFF1E293B), fontSize: 14, bold: true);
      currentTextY += 18;
      
      // Allocation if exists
      if (node.allocationAmount > 0) {
         _drawText(canvas, '+ Income Alloc: ${node.allocationAmountStr}', textStartX, currentTextY, Colors.blue, fontSize: 11);
         currentTextY += 18;
      }
      
      // Bucket Balances
      if (activeTracks.contains(TrackType.fire)) {
        _drawText(canvas, 'Fire: ${node.fireBalanceStr}', textStartX, currentTextY, TrackColors.fire, fontSize: 12, bold: true);
        currentTextY += 18;
      }
      if (activeTracks.contains(TrackType.mojo)) {
        _drawText(canvas, 'Mojo: ${node.mojoBalanceStr}', textStartX, currentTextY, TrackColors.mojo, fontSize: 12, bold: true);
        currentTextY += 18;
      }
      if (activeTracks.contains(TrackType.debt)) {
        _drawText(canvas, 'Debt: ${node.debtBalanceStr}', textStartX, currentTextY, TrackColors.debt, fontSize: 12, bold: true);
        currentTextY += 18;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
