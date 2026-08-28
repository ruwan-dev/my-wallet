import 'package:flutter/material.dart';

enum TrackType { blow, splurge, smile, fire, mojo, grow, debt }

class TrackColors {
  static const Color blow = Color(0xFF38B2AC); // Pastel Cyan
  static const Color splurge = Color(0xFFF59E0B); // Amber
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
  final double smileBalance;
  final String smileBalanceStr;
  final double splurgeBalance;
  final String splurgeBalanceStr;
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
    required this.smileBalance,
    required this.smileBalanceStr,
    required this.splurgeBalance,
    required this.splurgeBalanceStr,
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

class ActiveTableRows {
  final bool hasAllocation;
  final bool hasSweep;
  final bool hasDeficit;
  final bool hasSmileRescue;
  final bool hasSplurgeRescue;
  final bool hasMojoCover;
  final bool hasDebtBorrow;
  
  ActiveTableRows({
    required this.hasAllocation,
    required this.hasSweep,
    required this.hasDeficit,
    required this.hasSmileRescue,
    required this.hasSplurgeRescue,
    required this.hasMojoCover,
    required this.hasDebtBorrow,
  });
  
  factory ActiveTableRows.fromNodes(List<ForecastNode> nodes) {
    bool alloc = false, sweep = false, deficit = false;
    bool smile = false, splurge = false, mojo = false, debt = false;
    
    for (final node in nodes) {
      if (node.allocationAmount > 0) alloc = true;
      for (final t in node.transfers) {
        if (t.from == TrackType.blow && t.to == TrackType.fire) sweep = true;
        if (t.from == TrackType.fire && t.to == TrackType.blow) deficit = true;
        if (t.from == TrackType.smile && t.to == TrackType.fire) smile = true;
        if (t.from == TrackType.splurge && t.to == TrackType.fire) splurge = true;
        if (t.from == TrackType.mojo && t.to == TrackType.fire) mojo = true;
        if (t.from == TrackType.debt && t.to == TrackType.mojo) debt = true;
      }
    }
    return ActiveTableRows(
      hasAllocation: alloc, hasSweep: sweep, hasDeficit: deficit,
      hasSmileRescue: smile, hasSplurgeRescue: splurge,
      hasMojoCover: mojo, hasDebtBorrow: debt
    );
  }
}

class ForecastGitGraph extends StatelessWidget {
  final List<ForecastNode> nodes;

  const ForecastGitGraph({super.key, required this.nodes});

  List<TrackType> _getGloballyActiveTracks() {
    Set<TrackType> active = {TrackType.blow, TrackType.fire, TrackType.mojo}; // Base tracks always active
    
    for (final node in nodes) {
      if (node.smileBalance != 0) active.add(TrackType.smile);
      if (node.splurgeBalance != 0) active.add(TrackType.splurge);
      if (node.mojoBalance != 0) active.add(TrackType.mojo);
      if (node.debtBalance != 0) active.add(TrackType.debt);
      for (final t in node.transfers) {
        active.add(t.from);
        active.add(t.to);
      }
    }
    
    final all = [TrackType.blow, TrackType.splurge, TrackType.smile, TrackType.fire, TrackType.mojo, TrackType.grow, TrackType.debt];
    return all.where((t) => active.contains(t)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double fixedLeftWidth = 85.0;
    final double scrollableWidth = screenWidth - fixedLeftWidth;
    final double colWidth = scrollableWidth / 1.8; // show nearly 2 columns
    
    final activeTracks = _getGloballyActiveTracks();
    final activeRows = ActiveTableRows.fromNodes(nodes);

    final double startPadding = 15.0;
    final double totalWidth = startPadding + (nodes.length * colWidth) + (colWidth / 2);
    final double totalHeight = 550.0; // Plenty of room for dynamic table

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FIXED LEFT LABELS
        SizedBox(
          width: fixedLeftWidth,
          height: totalHeight,
          child: CustomPaint(
            painter: FixedLabelsPainter(activeTracks, activeRows),
          ),
        ),
        
        // SCROLLABLE GRAPH & AMOUNTS
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: totalWidth,
              height: totalHeight,
              child: CustomPaint(
                painter: GitGraphPainter(nodes, colWidth, activeTracks, activeRows),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Shared Math / Utils
const double _trackSpacing = 28.0; 
const double _startY = 30.0;

double _getTrackY(TrackType track, List<TrackType> activeTracks) {
  int index = activeTracks.indexOf(track);
  if (index == -1) return _startY;
  return _startY + (index * _trackSpacing);
}

Color _getTrackColor(TrackType track) {
  switch (track) {
    case TrackType.blow: return TrackColors.blow;
    case TrackType.splurge: return TrackColors.splurge;
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

// Fixed Labels Painter
class FixedLabelsPainter extends CustomPainter {
  final List<TrackType> activeTracks;
  final ActiveTableRows activeRows;
  FixedLabelsPainter(this.activeTracks, this.activeRows);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Track Names (aligned with the horizontal lines)
    for (final track in activeTracks) {
      final y = _getTrackY(track, activeTracks);
      final color = _getTrackColor(track);
      _drawText(canvas, track.name.toUpperCase(), 0, y - 6, color, fontSize: 10, bold: true, align: TextAlign.left);
    }
    
    // 2. Draw Table Rows
    double tableStartY = _startY + (activeTracks.length * _trackSpacing) + 50;
    double currentTextY = tableStartY;

    // Transactions
    if (activeRows.hasAllocation) {
      _drawText(canvas, 'Alloc:', 0, currentTextY, Colors.blue, fontSize: 11, bold: true, align: TextAlign.left);
      currentTextY += 18;
    }
    if (activeRows.hasSweep) {
      _drawText(canvas, 'Sweep:', 0, currentTextY, TrackColors.blow, fontSize: 11, bold: true, align: TextAlign.left);
      currentTextY += 18;
    }
    if (activeRows.hasDeficit) {
      _drawText(canvas, 'Deficit:', 0, currentTextY, TrackColors.fire, fontSize: 11, bold: true, align: TextAlign.left);
      currentTextY += 18;
    }
    if (activeRows.hasSmileRescue) {
      _drawText(canvas, 'Smile Cover:', 0, currentTextY, TrackColors.smile, fontSize: 11, bold: true, align: TextAlign.left);
      currentTextY += 18;
    }
    if (activeRows.hasSplurgeRescue) {
      _drawText(canvas, 'Splurge Cover:', 0, currentTextY, TrackColors.splurge, fontSize: 11, bold: true, align: TextAlign.left);
      currentTextY += 18;
    }
    if (activeRows.hasMojoCover) {
      _drawText(canvas, 'Mojo Cover:', 0, currentTextY, TrackColors.mojo, fontSize: 11, bold: true, align: TextAlign.left);
      currentTextY += 18;
    }
    if (activeRows.hasDebtBorrow) {
      _drawText(canvas, 'Debt Borrow:', 0, currentTextY, TrackColors.debt, fontSize: 11, bold: true, align: TextAlign.left);
      currentTextY += 18;
    }

    currentTextY += 10; // gap before balances

    // Balances
    if (activeTracks.contains(TrackType.smile)) {
      _drawText(canvas, 'Smile Bal:', 0, currentTextY, TrackColors.smile, fontSize: 12, bold: true, align: TextAlign.left);
      currentTextY += 18;
    }
    if (activeTracks.contains(TrackType.splurge)) {
      _drawText(canvas, 'Splurge Bal:', 0, currentTextY, TrackColors.splurge, fontSize: 12, bold: true, align: TextAlign.left);
      currentTextY += 18;
    }
    if (activeTracks.contains(TrackType.fire)) {
      _drawText(canvas, 'Fire Bal:', 0, currentTextY, TrackColors.fire, fontSize: 12, bold: true, align: TextAlign.left);
      currentTextY += 18;
    }
    if (activeTracks.contains(TrackType.mojo)) {
      _drawText(canvas, 'Mojo Bal:', 0, currentTextY, TrackColors.mojo, fontSize: 12, bold: true, align: TextAlign.left);
      currentTextY += 18;
    }
    if (activeTracks.contains(TrackType.debt)) {
      _drawText(canvas, 'Debt Bal:', 0, currentTextY, TrackColors.debt, fontSize: 12, bold: true, align: TextAlign.left);
      currentTextY += 18;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Scrolling Graph Painter
class GitGraphPainter extends CustomPainter {
  final List<ForecastNode> nodes;
  final double colWidth;
  final List<TrackType> activeTracks;
  final ActiveTableRows activeRows;

  GitGraphPainter(this.nodes, this.colWidth, this.activeTracks, this.activeRows);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      
      final double startPadding = 15.0;
      final double prevX = i == 0 ? startPadding : startPadding + (i * colWidth);
      final double x = startPadding + ((i + 1) * colWidth);

      // 0. Draw the "Today" starting dots
      if (i == 0) {
        for (final track in activeTracks) {
          final y = _getTrackY(track, activeTracks);
          final color = _getTrackColor(track);
          canvas.drawCircle(Offset(prevX, y), 8, Paint()..color = color.withValues(alpha: 0.3));
          canvas.drawCircle(Offset(prevX, y), 4, Paint()..color = color);
        }
        double textStartY = _startY + (activeTracks.length * _trackSpacing) + 25;
        _drawText(canvas, 'Today', prevX, textStartY, const Color(0xFF1E293B), fontSize: 13, bold: true, align: TextAlign.center);
      }

      // 1. Draw continuous horizontal track lines
      for (final track in activeTracks) {
        final y = _getTrackY(track, activeTracks);
        final paint = Paint()
          ..color = _getTrackColor(track).withValues(alpha: 0.3)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
          
        canvas.drawLine(Offset(prevX, y), Offset(x, y), paint);
      }

      // 2. Draw Transfer Curves
      for (final transfer in node.transfers) {
        final fromY = _getTrackY(transfer.from, activeTracks);
        final toY = _getTrackY(transfer.to, activeTracks);
        
        final path = Path();
        path.moveTo(prevX, fromY);
        
        path.cubicTo(
          prevX + (x - prevX) / 2, fromY, 
          prevX + (x - prevX) / 2, toY, 
          x, toY
        );

        final paint = Paint()
          ..color = transfer.color.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
          
        canvas.drawPath(path, paint);
      }

      // 3. Draw Nodes (Dots)
      for (final track in activeTracks) {
        final y = _getTrackY(track, activeTracks);
        final color = _getTrackColor(track);
        
        canvas.drawCircle(Offset(x, y), 8, Paint()..color = color.withValues(alpha: 0.3));
        canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
      }

      // 4. Draw Table Rows (Numbers ONLY)
      double tableStartY = _startY + (activeTracks.length * _trackSpacing) + 50;
      double currentTextY = tableStartY;
      
      // Month Label goes ABOVE the table
      _drawText(canvas, node.monthLabel, x, tableStartY - 25, const Color(0xFF1E293B), fontSize: 13, bold: true, align: TextAlign.center);

      // Helper to strip "Cover:", "Rescue:", etc from label
      String? _getTransferLabel(TrackType from, TrackType to) {
        for (final t in node.transfers) {
          if (t.from == from && t.to == to) {
            return t.label.replaceAll(RegExp(r'^(Rescue|Cover|Borrow):\s*'), '');
          }
        }
        return null;
      }

      // Transactions
      if (activeRows.hasAllocation) {
        _drawText(canvas, node.allocationAmount > 0 ? node.allocationAmountStr : '-', x, currentTextY, Colors.blue, fontSize: 11, align: TextAlign.center);
        currentTextY += 18;
      }
      if (activeRows.hasSweep) {
        String? val = _getTransferLabel(TrackType.blow, TrackType.fire);
        _drawText(canvas, val ?? '-', x, currentTextY, TrackColors.blow, fontSize: 11, align: TextAlign.center);
        currentTextY += 18;
      }
      if (activeRows.hasDeficit) {
        String? val = _getTransferLabel(TrackType.fire, TrackType.blow);
        _drawText(canvas, val ?? '-', x, currentTextY, TrackColors.fire, fontSize: 11, align: TextAlign.center);
        currentTextY += 18;
      }
      if (activeRows.hasSmileRescue) {
        String? val = _getTransferLabel(TrackType.smile, TrackType.fire);
        _drawText(canvas, val ?? '-', x, currentTextY, TrackColors.smile, fontSize: 11, align: TextAlign.center);
        currentTextY += 18;
      }
      if (activeRows.hasSplurgeRescue) {
        String? val = _getTransferLabel(TrackType.splurge, TrackType.fire);
        _drawText(canvas, val ?? '-', x, currentTextY, TrackColors.splurge, fontSize: 11, align: TextAlign.center);
        currentTextY += 18;
      }
      if (activeRows.hasMojoCover) {
        String? val = _getTransferLabel(TrackType.mojo, TrackType.fire);
        _drawText(canvas, val ?? '-', x, currentTextY, TrackColors.mojo, fontSize: 11, align: TextAlign.center);
        currentTextY += 18;
      }
      if (activeRows.hasDebtBorrow) {
        String? val = _getTransferLabel(TrackType.debt, TrackType.mojo);
        _drawText(canvas, val ?? '-', x, currentTextY, TrackColors.debt, fontSize: 11, align: TextAlign.center);
        currentTextY += 18;
      }

      currentTextY += 10; // gap before balances

      // Balances
      if (activeTracks.contains(TrackType.smile)) {
        _drawText(canvas, node.smileBalanceStr, x, currentTextY, TrackColors.smile, fontSize: 12, bold: true, align: TextAlign.center);
        currentTextY += 18;
      }
      if (activeTracks.contains(TrackType.splurge)) {
        _drawText(canvas, node.splurgeBalanceStr, x, currentTextY, TrackColors.splurge, fontSize: 12, bold: true, align: TextAlign.center);
        currentTextY += 18;
      }
      if (activeTracks.contains(TrackType.fire)) {
        _drawText(canvas, node.fireBalanceStr, x, currentTextY, TrackColors.fire, fontSize: 12, bold: true, align: TextAlign.center);
        currentTextY += 18;
      }
      if (activeTracks.contains(TrackType.mojo)) {
        _drawText(canvas, node.mojoBalanceStr, x, currentTextY, TrackColors.mojo, fontSize: 12, bold: true, align: TextAlign.center);
        currentTextY += 18;
      }
      if (activeTracks.contains(TrackType.debt)) {
        _drawText(canvas, node.debtBalanceStr, x, currentTextY, TrackColors.debt, fontSize: 12, bold: true, align: TextAlign.center);
        currentTextY += 18;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
