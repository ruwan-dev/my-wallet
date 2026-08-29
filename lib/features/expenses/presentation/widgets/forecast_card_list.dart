import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';

import 'package:go_router/go_router.dart';

// ─── Data model ─────────────────────────────────────────────────────────────


enum ForecastHealth { safe, warning, danger }

class BucketSnapshot {
  final String name;
  final BucketType bucketType;
  final Color color;
  final IconData icon;
  final double balance;
  final double change; // vs previous month

  const BucketSnapshot({
    required this.name,
    required this.bucketType,
    required this.color,
    required this.icon,
    required this.balance,
    required this.change,
  });
}

class ForecastMonthCard {
  final String monthLabel;
  final bool isCurrentMonth;
  final ForecastHealth health;
  final String healthMessage;
  final List<BucketSnapshot> buckets;
  final double sweepAmount;     // surplus from Blow → Fire
  final double deficitAmount;   // Blow overspent, pulled from Heal
  final bool usedSmile;
  final bool usedSplurge;
  final bool usedMojo;
  final double debtAdded;
  final double debtPaidAmount;
  final List<String> paidDebtNames;

  const ForecastMonthCard({
    required this.monthLabel,
    required this.isCurrentMonth,
    required this.health,
    required this.healthMessage,
    required this.buckets,
    required this.sweepAmount,
    required this.deficitAmount,
    required this.usedSmile,
    required this.usedSplurge,
    required this.usedMojo,
    required this.debtAdded,
    this.debtPaidAmount = 0,
    this.paidDebtNames = const [],
  });
}

// ─── Widget ──────────────────────────────────────────────────────────────────

class ForecastCardList extends StatefulWidget {
  final List<ForecastMonthCard> cards;
  final String Function(double) fmt;

  const ForecastCardList({super.key, required this.cards, required this.fmt});

  @override
  State<ForecastCardList> createState() => _ForecastCardListState();
}

class _ForecastCardListState extends State<ForecastCardList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    // Draw arrows, pause 800ms, reset and repeat forever
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _controller.forward(from: 0);
        });
      }
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 430,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(bottom: 30, top: 8, left: 4, right: 4),
            physics: const BouncingScrollPhysics(),
            itemCount: widget.cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final cardWidget = _MonthCard(
                  card: widget.cards[i], fmt: widget.fmt, fmtShort: _fmtShort);
              
              if (i == 0) return cardWidget;

              const double gap = 12;
              const double bleed = 120.0;
              const double canvasW = gap + bleed * 2;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  cardWidget,
                  // Draw the lines overflowing to the left from this card
                  // This ensures the lines paint ON TOP of both the left and right cards
                  Positioned(
                    left: -gap - bleed,
                    top: 0,
                    bottom: 0,
                    width: canvasW,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _SweepArrowsPainter(
                          leftCard: widget.cards[i - 1],
                          rightCard: widget.cards[i],
                          progress: _progress.value,
                          bleed: bleed,
                          gap: gap,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SweepArrowsPainter extends CustomPainter {
  final ForecastMonthCard leftCard;
  final ForecastMonthCard rightCard;
  final double progress;
  final double bleed;   // px the canvas overlaps INTO each card
  final double gap;     // gap between cards (the SizedBox width)

  _SweepArrowsPainter({
    required this.leftCard,
    required this.rightCard,
    required this.progress,
    this.bleed = 120.0,
    this.gap   = 12.0,
  });

  // ── Precise layout constants derived from the card's Flutter padding/font values ──
  //  ListView top padding: 8
  //  Header container padding(v:12): 12 + title(~16) + gap(6) + desc(~24) + gap(8) + badge(~21) + 12 = 99
  //  Bucket section padding(v:8, top only): +8
  //  Total Y to first bucket row top: 8 + 99 + 8 = 115
  //  Each BucketRow padding(v:5) + content max(dot8, text14) = 24px per row
  static const double _listTopPad   = 8.0;
  static const double _headerH      = 99.0;
  static const double _bucketTopPad = 8.0;
  static const double _rowH         = 24.0;

  double _rowCY(int index) {
    final sectionTop = _listTopPad + _headerH + _bucketTopPad;
    return sectionTop + index * _rowH + _rowH / 2;
  }

  // Canvas geometry (all X values are in canvas coordinates):
  //   canvas left (x=0)  = bleed px INSIDE the left card's right region
  //   right card starts  = bleed + gap
  // Left card amounts end ~14px from its right edge. We start at 18px from its right edge.
  // Right card Heal dot is ~22px from its left edge. We end at 18px from its left edge (just touching the dot).
  double get _startX => bleed - 18;          // near right edge of left card's amounts
  double get _tipX   => bleed + gap + 18;    // touching the Heal dot in right card

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final rightHealIndex =
        rightCard.buckets.indexWhere((b) => b.bucketType == BucketType.heal);
    if (rightHealIndex == -1) return;

    final destY = _rowCY(rightHealIndex);

    for (int i = 0; i < leftCard.buckets.length; i++) {
      final b = leftCard.buckets[i];
      final shouldDraw = b.balance > 0 &&
          (b.bucketType == BucketType.dailyExpenses ||
           b.bucketType == BucketType.smile ||
           b.bucketType == BucketType.splurge ||
           b.bucketType == BucketType.heal);
      if (!shouldDraw) continue;

      final startY = _rowCY(i);
      final color  = b.color.withValues(alpha: 0.85);

      _drawAnimatedArrow(canvas, size, startY, destY, color);
    }
  }

  void _drawAnimatedArrow(
      Canvas canvas, Size size, double startY, double destY, Color color) {
    final x0 = _startX;
    final x3 = _tipX;
    // Bezier bends through the gap in the middle of the canvas
    final mid = size.width / 2;

    final fullPath = Path()
      ..moveTo(x0, startY)
      ..cubicTo(mid, startY, mid, destY, x3, destY);

    final metric = fullPath.computeMetrics().first;
    final animLen = metric.length * progress;
    if (animLen <= 0) return;

    final partial = metric.extractPath(0, animLen);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(partial, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SweepArrowsPainter old) =>
      old.progress != progress;
}

/// Abbreviates large numbers: 38552 → "38.6k", 1200000 → "1.2M"
String _fmtShort(double v) {
  final sign = v < 0 ? '-' : '';
  final abs  = v.abs();
  if (abs >= 1000000) return '${sign}${(abs / 1000000).toStringAsFixed(1)}M';
  if (abs >= 1000)    return '${sign}${(abs / 1000).toStringAsFixed(1)}k';
  return '$sign${abs.toStringAsFixed(0)}';
}

// ─── Single month card ───────────────────────────────────────────────────────

class _MonthCard extends StatelessWidget {
  final ForecastMonthCard card;
  final String Function(double) fmt;
  final String Function(double) fmtShort;

  const _MonthCard({required this.card, required this.fmt, required this.fmtShort});

  @override
  Widget build(BuildContext context) {
    final (healthColor, healthIcon, healthBg) = switch (card.health) {
      ForecastHealth.safe    => (const Color(0xFF38B2AC), Icons.check_circle_rounded,    const Color(0xFF38B2AC).withValues(alpha: 0.15)),
      ForecastHealth.warning => (const Color(0xFFD97706), Icons.warning_amber_rounded,   const Color(0xFFFEF3C7)),
      ForecastHealth.danger  => (const Color(0xFFDC2626), Icons.error_rounded,           const Color(0xFFFFE4E4)),
    };

    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: card.isCurrentMonth ? const Color(0xFF38B2AC) : Colors.grey.shade200,
          width: card.isCurrentMonth ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: card.isCurrentMonth
                  ? const Color(0xFF38B2AC).withValues(alpha: 0.08)
                  : Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (card.isCurrentMonth)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38B2AC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('NOW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    Expanded(
                      child: Text(
                        card.monthLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  card.isCurrentMonth
                      ? 'Based on your current behaviour, these will be your balances.'
                      : 'If you stick to your budget, these will be your balances.',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600, height: 1.2),
                ),
                const SizedBox(height: 8),
                // Health badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: healthBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(healthIcon, size: 13, color: healthColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          card.healthMessage,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: healthColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bucket rows ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: [
                  ...card.buckets.map((b) => _BucketRow(b: b, fmt: fmt, fmtShort: fmtShort)),
                ],
              ),
            ),
          ),

          // ── Footer: events ──
          if (card.sweepAmount > 0 || card.deficitAmount > 0 || card.usedSmile || card.usedSplurge || card.usedMojo || card.debtAdded > 0 || card.debtPaidAmount > 0)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(19)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 6),
                  if (card.sweepAmount > 0)
                    _EventRow('Swept to Heal', fmt(card.sweepAmount), const Color(0xFF38B2AC)),
                  if (card.deficitAmount > 0)
                    _EventRow('Blow Overspent', '-${fmt(card.deficitAmount)}', const Color(0xFFE05263)),
                  if (card.usedSmile)
                    _EventRow('Smile helped Heal', '', const Color(0xFFD946EF)),
                  if (card.usedSplurge)
                    _EventRow('Splurge helped Heal', '', const Color(0xFFF59E0B)),
                  if (card.usedMojo)
                    _EventRow('Mojo covered deficit', '', const Color(0xFF3949AB)),
                  if (card.debtAdded > 0)
                    _EventRow('Debt added', fmt(card.debtAdded), const Color(0xFFB91C1C)),
                  if (card.debtPaidAmount > 0)
                    _EventRow('Paid: ${card.paidDebtNames.join(", ")}', '-${fmt(card.debtPaidAmount)}', const Color(0xFFE05263)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Widget _EventRow(String label, String value, Color color) => Padding(
  padding: const EdgeInsets.only(bottom: 3),
  child: Row(
    children: [
      Expanded(child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500))),
      if (value.isNotEmpty)
        Text(value, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    ],
  ),
);

class _BucketRow extends StatelessWidget {
  final BucketSnapshot b;
  final String Function(double) fmt;
  final String Function(double) fmtShort;

  const _BucketRow({required this.b, required this.fmt, required this.fmtShort});

  @override
  Widget build(BuildContext context) {
    
    
    
    final balColor    = b.balance < 0 ? const Color(0xFFDC2626) : const Color(0xFF1E293B);

    return InkWell(
      onTap: () {
        context.push('/bucket-transactions', extra: b.bucketType);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Color dot
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: b.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),

          // Bucket name — fixed narrow width
          SizedBox(
            width: 48,
            child: Text(
              b.name,
              style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Balance — takes all remaining space, left-aligned so the Rs symbol lines up
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Text(
                fmt(b.balance),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: balColor),
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

        ],
        ),
      ),
    );
  }
}
