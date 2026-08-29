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
  final double allocationAmount;
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

class ForecastGitGraph extends StatelessWidget {
  final List<ForecastNode> nodes;

  const ForecastGitGraph({super.key, required this.nodes});

  List<TrackType> _getGloballyActiveTracks() {
    Set<TrackType> active = {TrackType.blow, TrackType.fire, TrackType.mojo};

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
    final double fixedLeftWidth = 75.0;
    final double scrollableWidth = screenWidth - fixedLeftWidth;
    final double colWidth = scrollableWidth / 1.8;

    final activeTracks = _getGloballyActiveTracks();

    final double startPadding = 15.0;
    final double totalWidth = startPadding + (nodes.length * colWidth) + (colWidth / 2);
    // Height: just enough for lines + month label + a little breathing room
    final double trackSpacing = 44.0;
    final double startY = 35.0;
    final double totalHeight = startY + (activeTracks.length * trackSpacing) + 60.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FIXED LEFT LABELS (track names only)
        SizedBox(
          width: fixedLeftWidth,
          height: totalHeight,
          child: CustomPaint(
            painter: FixedLabelsPainter(activeTracks, trackSpacing, startY),
          ),
        ),

        // SCROLLABLE GRAPH
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: totalWidth,
              height: totalHeight,
              child: CustomPaint(
                painter: GitGraphPainter(nodes, colWidth, activeTracks, trackSpacing, startY),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void _drawText(Canvas canvas, String text, double x, double y, Color color,
    {double fontSize = 11, bool bold = false, TextAlign align = TextAlign.left}) {
  final textSpan = TextSpan(
    text: text,
    style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal),
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

double _getTrackY(TrackType track, List<TrackType> activeTracks, double trackSpacing, double startY) {
  int index = activeTracks.indexOf(track);
  if (index == -1) return startY;
  return startY + (index * trackSpacing);
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

// Fixed left column: only track name labels
class FixedLabelsPainter extends CustomPainter {
  final List<TrackType> activeTracks;
  final double trackSpacing;
  final double startY;

  FixedLabelsPainter(this.activeTracks, this.trackSpacing, this.startY);

  @override
  void paint(Canvas canvas, Size size) {
    for (final track in activeTracks) {
      final y = _getTrackY(track, activeTracks, trackSpacing, startY);
      final color = _getTrackColor(track);
      _drawText(canvas, track.name.toUpperCase(), 0, y - 7, color,
          fontSize: 10, bold: true, align: TextAlign.left);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Scrolling graph painter — NO bottom table, amounts shown ON the curves
class GitGraphPainter extends CustomPainter {
  final List<ForecastNode> nodes;
  final double colWidth;
  final List<TrackType> activeTracks;
  final double trackSpacing;
  final double startY;

  GitGraphPainter(this.nodes, this.colWidth, this.activeTracks, this.trackSpacing, this.startY);

  @override
  void paint(Canvas canvas, Size size) {
    const double startPadding = 15.0;

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];

      final double prevX = i == 0 ? startPadding : startPadding + (i * colWidth);
      final double x = startPadding + ((i + 1) * colWidth);
      final double midX = (prevX + x) / 2;

      // 0. "Today" starting dots on first column
      if (i == 0) {
        for (final track in activeTracks) {
          final y = _getTrackY(track, activeTracks, trackSpacing, startY);
          final color = _getTrackColor(track);
          canvas.drawCircle(Offset(prevX, y), 9, Paint()..color = color.withValues(alpha: 0.25));
          canvas.drawCircle(Offset(prevX, y), 5, Paint()..color = color);
        }
        final textY = startY + (activeTracks.length * trackSpacing) + 8;
        _drawText(canvas, 'Today', prevX, textY, const Color(0xFF64748B),
            fontSize: 11, bold: false, align: TextAlign.center);
      }

      // 1. Horizontal track lines
      for (final track in activeTracks) {
        final y = _getTrackY(track, activeTracks, trackSpacing, startY);
        canvas.drawLine(
          Offset(prevX, y),
          Offset(x, y),
          Paint()
            ..color = _getTrackColor(track).withValues(alpha: 0.25)
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke,
        );
      }

      // 2. Transfer curves + label ON the midpoint of each curve
      for (final transfer in node.transfers) {
        final fromY = _getTrackY(transfer.from, activeTracks, trackSpacing, startY);
        final toY = _getTrackY(transfer.to, activeTracks, trackSpacing, startY);

        final path = Path()
          ..moveTo(prevX, fromY)
          ..cubicTo(midX, fromY, midX, toY, x, toY);

        canvas.drawPath(
          path,
          Paint()
            ..color = transfer.color.withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );

        // Amount label drawn at the peak of the curve (midX, midY)
        final double midY = (fromY + toY) / 2;
        // Strip prefix tokens like "+", "-", "Rescue: " etc and show clean amount
        final String amountText = transfer.label
            .replaceAll(RegExp(r'^(Rescue|Cover|Borrow|Sweep):\s*'), '');

        // Small pill background
        final textSpan = TextSpan(
          text: amountText,
          style: TextStyle(
              color: transfer.color, fontSize: 10, fontWeight: FontWeight.bold),
        );
        final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
        tp.layout();
        final pillRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(midX, midY - tp.height / 2 - 2),
              width: tp.width + 10,
              height: tp.height + 6),
          const Radius.circular(4),
        );
        canvas.drawRRect(pillRect,
            Paint()..color = transfer.color.withValues(alpha: 0.12));
        tp.paint(canvas, Offset(midX - tp.width / 2, midY - tp.height - 2));
      }

      // 3. End-of-month dots
      for (final track in activeTracks) {
        final y = _getTrackY(track, activeTracks, trackSpacing, startY);
        final color = _getTrackColor(track);
        canvas.drawCircle(Offset(x, y), 9, Paint()..color = color.withValues(alpha: 0.25));
        canvas.drawCircle(Offset(x, y), 5, Paint()..color = color);
      }

      // 4. Balance labels drawn ABOVE each dot (right side of dot, slight offset)
      // We show the balance of each track ABOVE its own line at x
      _drawBalanceNearDot(canvas, node, x, activeTracks);

      // 5. Month label below all tracks
      final double labelY = startY + (activeTracks.length * trackSpacing) + 8;
      _drawText(canvas, node.monthLabel, x, labelY, const Color(0xFF1E293B),
          fontSize: 12, bold: true, align: TextAlign.center);
    }
  }

  void _drawBalanceNearDot(
      Canvas canvas, ForecastNode node, double x, List<TrackType> activeTracks) {
    // Draw the balance amount just to the right of each dot (small, subtle)
    void drawBal(TrackType track, String balStr) {
      if (!activeTracks.contains(track)) return;
      final y = _getTrackY(track, activeTracks, trackSpacing, startY);
      final color = _getTrackColor(track);
      _drawText(canvas, balStr, x + 12, y - 8, color,
          fontSize: 10, bold: false, align: TextAlign.left);
    }

    drawBal(TrackType.smile, node.smileBalanceStr);
    drawBal(TrackType.splurge, node.splurgeBalanceStr);
    drawBal(TrackType.fire, node.fireBalanceStr);
    drawBal(TrackType.mojo, node.mojoBalanceStr);
    drawBal(TrackType.debt, node.debtBalanceStr);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
