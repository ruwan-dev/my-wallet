import 'package:flutter/material.dart';

enum TrackType { blow, splurge, smile, fire, mojo, grow, debt }

class TrackColors {
  static const Color blow = Color(0xFF38B2AC);
  static const Color splurge = Color(0xFFF59E0B);
  static const Color smile = Color(0xFFD946EF);
  static const Color fire = Color(0xFFE05263);
  static const Color mojo = Color(0xFF3949AB);
  static const Color grow = Color(0xFF10B981);
  static const Color debt = Color(0xFFB91C1C);
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
    final double colWidth = screenWidth / 1.8;

    final activeTracks = _getGloballyActiveTracks();

    const double trackSpacing = 52.0;
    const double startY = 35.0;
    // Extra right padding so balance labels near the last dot don't clip
    final double totalWidth = (nodes.length * colWidth) + colWidth;
    final double totalHeight = startY + (activeTracks.length * trackSpacing) + 50.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        width: totalWidth,
        height: totalHeight,
        child: CustomPaint(
          painter: GitGraphPainter(nodes, colWidth, activeTracks),
        ),
      ),
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
  final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr, textAlign: align);
  tp.layout();
  double dx = x;
  if (align == TextAlign.center) dx = x - tp.width / 2;
  if (align == TextAlign.right) dx = x - tp.width;
  tp.paint(canvas, Offset(dx, y));
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

double _trackY(TrackType track, List<TrackType> activeTracks) {
  const double startY = 35.0;
  const double trackSpacing = 44.0;
  final idx = activeTracks.indexOf(track);
  if (idx == -1) return startY;
  return startY + idx * trackSpacing;
}

class GitGraphPainter extends CustomPainter {
  final List<ForecastNode> nodes;
  final double colWidth;
  final List<TrackType> activeTracks;

  GitGraphPainter(this.nodes, this.colWidth, this.activeTracks);

  static const double startY = 35.0;
  static const double trackSpacing = 52.0;
  // How far from left edge the graph starts (room for inline label)
  static const double leftPad = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];

      final double prevX = leftPad + (i * colWidth);
      final double x     = leftPad + ((i + 1) * colWidth);
      final double midX  = (prevX + x) / 2;

      // ── 0. "Today" dots + inline track name label on first column ─────────
      if (i == 0) {
        for (final track in activeTracks) {
          final y     = _trackY(track, activeTracks);
          final color = _getTrackColor(track);

          // dot
          canvas.drawCircle(Offset(prevX, y), 9, Paint()..color = color.withValues(alpha: 0.22));
          canvas.drawCircle(Offset(prevX, y), 5, Paint()..color = color);

          // track name label to the left of the first dot
          // Draw a small pill background then the text
          final labelSpan = TextSpan(
            text: track.name.toUpperCase(),
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
          );
          final ltp = TextPainter(text: labelSpan, textDirection: TextDirection.ltr);
          ltp.layout();
          // place label just before the first dot
          final lx = prevX - ltp.width - 6;
          final ly = y - ltp.height / 2;
          if (lx >= 0) ltp.paint(canvas, Offset(lx, ly));
        }
        // "Today" text below tracks
        final textY = startY + activeTracks.length * trackSpacing + 8;
        _drawText(canvas, 'Today', prevX, textY, const Color(0xFF64748B),
            fontSize: 11, align: TextAlign.center);
      }

      // ── 1. Horizontal track lines ─────────────────────────────────────────
      for (final track in activeTracks) {
        final y = _trackY(track, activeTracks);
        canvas.drawLine(
          Offset(prevX, y),
          Offset(x, y),
          Paint()
            ..color = _getTrackColor(track).withValues(alpha: 0.25)
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke,
        );
      }

      // ── 2. Transfer curves + pill label at curve midpoint ─────────────────
      for (final transfer in node.transfers) {
        final fromY = _trackY(transfer.from, activeTracks);
        final toY   = _trackY(transfer.to, activeTracks);

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

        // Amount pill at midpoint
        final double pillMidY = (fromY + toY) / 2;
        final amountText = transfer.label.replaceAll(RegExp(r'^(Rescue|Cover|Borrow|Sweep):\s*'), '');
        final aSpan = TextSpan(
          text: amountText,
          style: TextStyle(color: transfer.color, fontSize: 10, fontWeight: FontWeight.bold),
        );
        final atp = TextPainter(text: aSpan, textDirection: TextDirection.ltr);
        atp.layout();
        final pillRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(midX, pillMidY - atp.height / 2 - 2),
              width: atp.width + 10,
              height: atp.height + 6),
          const Radius.circular(4),
        );
        canvas.drawRRect(pillRect, Paint()..color = transfer.color.withValues(alpha: 0.12));
        atp.paint(canvas, Offset(midX - atp.width / 2, pillMidY - atp.height - 2));
      }

      // ── 3. End-of-month dots ──────────────────────────────────────────────
      for (final track in activeTracks) {
        final y     = _trackY(track, activeTracks);
        final color = _getTrackColor(track);
        canvas.drawCircle(Offset(x, y), 9, Paint()..color = color.withValues(alpha: 0.22));
        canvas.drawCircle(Offset(x, y), 5, Paint()..color = color);
      }

      // ── 4. Balance labels sitting ON the horizontal track line ───────────
      // Placed at 70% along the segment so they float ON the line itself
      final double labelX = prevX + (x - prevX) * 0.70;

      void drawBal(TrackType track, String balStr) {
        if (!activeTracks.contains(track)) return;
        final y     = _trackY(track, activeTracks);
        final color = _getTrackColor(track);

        final balSpan = TextSpan(
          text: balStr,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
        );
        final btp = TextPainter(text: balSpan, textDirection: TextDirection.ltr);
        btp.layout();

        const double pillH = 16;
        final double pillW = btp.width + 10;

        // Pill sits centered ON the line (vertically centered at y)
        final pillLeft = labelX - pillW / 2;
        final pillTop  = y - pillH / 2;

        // White fill so the line appears to pass through the label neatly
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(pillLeft, pillTop, pillW, pillH),
            const Radius.circular(8),
          ),
          Paint()..color = Colors.white,
        );

        // Colored outline
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(pillLeft, pillTop, pillW, pillH),
            const Radius.circular(8),
          ),
          Paint()
            ..color = color.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );

        btp.paint(canvas, Offset(labelX - btp.width / 2, y - btp.height / 2));
      }

      drawBal(TrackType.smile,   node.smileBalanceStr);
      drawBal(TrackType.splurge, node.splurgeBalanceStr);
      drawBal(TrackType.fire,    node.fireBalanceStr);
      drawBal(TrackType.mojo,    node.mojoBalanceStr);
      drawBal(TrackType.debt,    node.debtBalanceStr);


      // ── 5. Month label below all tracks ───────────────────────────────────
      final double labelY = startY + activeTracks.length * trackSpacing + 8;
      _drawText(canvas, node.monthLabel, x, labelY, const Color(0xFF1E293B),
          fontSize: 12, bold: true, align: TextAlign.center);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
