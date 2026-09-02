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
  final List<String> coverages;

  const BucketSnapshot({
    required this.name,
    required this.bucketType,
    required this.color,
    required this.icon,
    required this.balance,
    required this.change,
    this.coverages = const [],
  });
}

class ArrowEvent {
  final int fromIndex;
  final int toIndex;
  final Color color;
  const ArrowEvent(this.fromIndex, this.toIndex, this.color);
}

class ForecastMonthCard {
  final int monthIndex;
  final String monthLabel;
  final bool isCurrentMonth;
  final ForecastHealth health;
  final String healthMessage;
  final List<BucketSnapshot> buckets;
  final List<ArrowEvent> arrows;
  
  // End-of-month events
  final double sweepAmount;
  final String? sweepBreakdown;
  final bool hasUnresolvedDeficits;
  final double uncoveredLivingDeficit;
  final double uncoveredHealDeficit;
  final double uncoveredSmileDeficit;
  final double uncoveredEnjoyDeficit;
  final double uncoveredMojoDeficit;
  final double debtAdded;
  final double debtPaidAmount;
  final List<String> paidDebtNames;

  // Available for manual transfer
  final double availableLiving;
  final double availableSmile;
  final double availableEnjoy;
  final double availableHeal;
  final double availableMojo;

  // Callback
  final void Function(BucketType from, BucketType to, double amount)? onSimulateTransfer;

  const ForecastMonthCard({
    required this.monthIndex,
    required this.monthLabel,
    required this.isCurrentMonth,
    required this.health,
    required this.healthMessage,
    required this.buckets,
    this.arrows = const [],
    this.sweepAmount = 0,
    this.sweepBreakdown,
    this.hasUnresolvedDeficits = false,
    this.uncoveredLivingDeficit = 0,
    this.uncoveredHealDeficit = 0,
    this.uncoveredSmileDeficit = 0,
    this.uncoveredEnjoyDeficit = 0,
    this.uncoveredMojoDeficit = 0,
    this.debtAdded = 0,
    this.debtPaidAmount = 0,
    this.paidDebtNames = const [],
    this.availableLiving = 0,
    this.availableSmile = 0,
    this.availableEnjoy = 0,
    this.availableHeal = 0,
    this.availableMojo = 0,
    this.onSimulateTransfer,
  });
}

// ─── Widget ──────────────────────────────────────────────────────────────────

class ForecastCardList extends StatelessWidget {
  final List<ForecastMonthCard> cards;
  final String Function(double) fmt;

  const ForecastCardList({super.key, required this.cards, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 30, top: 8),
      itemCount: cards.length,
      separatorBuilder: (_, i) {
        if (cards[i].sweepAmount <= 0) return const SizedBox(height: 16);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.arrow_downward_rounded, color: Color(0xFF38B2AC), size: 28),
                const SizedBox(height: 4),
                const Text('Sweeps to next month', style: TextStyle(color: Color(0xFF38B2AC), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
      itemBuilder: (context, i) {
        return _MonthCard(card: cards[i], fmt: fmt, fmtShort: _fmtShort);
      },
    );
  }
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: card.isCurrentMonth ? const Color(0xFF38B2AC) : Colors.grey.shade200,
          width: card.isCurrentMonth ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: card.isCurrentMonth ? const Color(0xFF38B2AC).withValues(alpha: 0.05) : Colors.transparent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (card.isCurrentMonth)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38B2AC),
                          borderRadius: BorderRadius.circular(4),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Stack(
              children: [
                Column(
                  children: [
                    ...card.buckets.map((b) => _BucketRow(b: b, fmt: fmt, fmtShort: fmtShort)),
                  ],
                ),
                Positioned.fill(
                  child: _AnimatedArrowsOverlay(
                    arrows: card.arrows,
                    bucketsCount: card.buckets.length,
                  ),
                ),
              ],
            ),
          ),

          // ── Manual Coverage Action Buttons ──
          if (card.uncoveredLivingDeficit > 0)
            _buildManualCoverageButtons(BucketType.dailyExpenses, card.uncoveredLivingDeficit),
          if (card.uncoveredSmileDeficit > 0)
            _buildManualCoverageButtons(BucketType.smile, card.uncoveredSmileDeficit),
          if (card.uncoveredEnjoyDeficit > 0)
            _buildManualCoverageButtons(BucketType.enjoy, card.uncoveredEnjoyDeficit),
          if (card.uncoveredMojoDeficit > 0)
            _buildManualCoverageButtons(BucketType.mojo, card.uncoveredMojoDeficit),
          if (card.uncoveredHealDeficit > 0)
            _buildManualCoverageButtons(BucketType.heal, card.uncoveredHealDeficit),

          // ── Footer: events ──
          if (card.hasUnresolvedDeficits || card.sweepAmount > 0 || card.debtAdded > 0 || card.debtPaidAmount > 0)
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
                  
                  if (card.hasUnresolvedDeficits)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.lock, size: 14, color: Colors.orange.shade700),
                          const SizedBox(width: 6),
                          Text('Resolve deficits to calculate final sweep', style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else if (card.sweepAmount > 0)
                    _EventRow('Swept to Heal', card.sweepBreakdown ?? fmt(card.sweepAmount), const Color(0xFF38B2AC)),
                  
                  if (card.uncoveredLivingDeficit > 0)
                    _EventRow('Living Overspent', '-${fmt(card.uncoveredLivingDeficit)}', const Color(0xFFE05263)),
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

  Widget _buildManualCoverageButtons(BucketType toBucket, double deficit) {
    if (card.availableLiving <= 0 && card.availableSmile <= 0 && card.availableEnjoy <= 0 && card.availableHeal <= 0 && card.availableMojo <= 0) return const SizedBox();
    
    String toName = switch(toBucket) {
      BucketType.dailyExpenses => 'Living',
      BucketType.smile => 'Smile',
      BucketType.enjoy => 'Enjoy',
      BucketType.mojo => 'Mojo',
      BucketType.heal => 'Heal',
      _ => 'Unknown'
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('Cover $toName deficit:', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE05263))),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (toBucket != BucketType.dailyExpenses && card.availableLiving > 0) _buildCoverBtn('Living', BucketType.dailyExpenses, toBucket, deficit, card.availableLiving),
              if (toBucket != BucketType.smile && card.availableSmile > 0) _buildCoverBtn('Smile', BucketType.smile, toBucket, deficit, card.availableSmile),
              if (toBucket != BucketType.enjoy && card.availableEnjoy > 0) _buildCoverBtn('Enjoy', BucketType.enjoy, toBucket, deficit, card.availableEnjoy),
              if (toBucket != BucketType.mojo && card.availableMojo > 0) _buildCoverBtn('Mojo', BucketType.mojo, toBucket, deficit, card.availableMojo),
              if (toBucket != BucketType.heal && card.availableHeal > 0) _buildCoverBtn('Heal', BucketType.heal, toBucket, deficit, card.availableHeal),
            ],
          )
        ],
      )
    );
  }

  Widget _buildCoverBtn(String name, BucketType fromBucket, BucketType toBucket, double deficit, double available) {
    final amount = available >= deficit ? deficit : available;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        minimumSize: const Size(0, 28),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: () {
        card.onSimulateTransfer?.call(fromBucket, toBucket, amount);
      },
      child: Text('Cover from $name', style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
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
        ),
        if (b.coverages.isNotEmpty)
          ...b.coverages.map((cov) => Padding(
                padding: const EdgeInsets.only(left: 28, bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.subdirectory_arrow_right_rounded, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        cov,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}
class _AnimatedArrowsOverlay extends StatefulWidget {
  final List<ArrowEvent> arrows;
  final int bucketsCount;
  const _AnimatedArrowsOverlay({required this.arrows, required this.bucketsCount});
  @override
  State<_AnimatedArrowsOverlay> createState() => _AnimatedArrowsOverlayState();
}

class _AnimatedArrowsOverlayState extends State<_AnimatedArrowsOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.arrows.isEmpty) return const SizedBox();
    return CustomPaint(
      painter: _TransferArrowsPainter(
        arrows: widget.arrows,
        bucketsCount: widget.bucketsCount,
        animation: _ctrl,
      ),
    );
  }
}

class _TransferArrowsPainter extends CustomPainter {
  final List<ArrowEvent> arrows;
  final int bucketsCount;
  final Animation<double> animation;

  _TransferArrowsPainter({required this.arrows, required this.bucketsCount, required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (arrows.isEmpty || bucketsCount == 0) return;

    final rowHeight = size.height / bucketsCount;
    final rightX = size.width - 45;
    
    // In case there are multiple arrows to the same target, stagger their rightX slightly
    // to avoid overlapping perfectly. We can group by toIndex.
    final Map<int, int> arrowsToTarget = {};
    
    for (var i = 0; i < arrows.length; i++) {
      final arrow = arrows[i];
      final targetIdx = arrow.toIndex;
      final staggerIndex = arrowsToTarget[targetIdx] ?? 0;
      arrowsToTarget[targetIdx] = staggerIndex + 1;
      
      final currentRightX = rightX + (staggerIndex * 8); // stagger vertically/horizontally
      
      final startY = (arrow.fromIndex * rowHeight) + (rowHeight / 2);
      final currentEndY = (arrow.toIndex * rowHeight) + (rowHeight / 2) + (staggerIndex * 8);
      
      final path = Path();
      // start at donor (near balance)
      path.moveTo(rightX - 35, startY);
      // go right
      path.lineTo(currentRightX, startY);
      // go up (or down)
      path.lineTo(currentRightX, currentEndY);
      // go left to recipient
      path.lineTo(rightX - 35, currentEndY);

      final pms = path.computeMetrics().toList();
      if (pms.isEmpty) continue;
      final pm = pms.first;
      
      final paint = Paint()
        ..color = arrow.color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
        
      // Draw animated solid line
      final distance = pm.length * animation.value;
      final animatedPath = pm.extractPath(0, distance);
      canvas.drawPath(animatedPath, paint);
      
      // Draw arrowhead at the current tip of the animation
      final tangent = pm.getTangentForOffset(distance);
      if (tangent != null) {
        final arrowPaint = Paint()
          ..color = arrow.color
          ..style = PaintingStyle.fill;
          
        canvas.save();
        canvas.translate(tangent.position.dx, tangent.position.dy);
        canvas.rotate(tangent.vector.direction);
        
        final arrowPath = Path();
        arrowPath.moveTo(0, 0); // Tip
        arrowPath.lineTo(-8, -4); // Top back
        arrowPath.lineTo(-8, 4); // Bottom back
        arrowPath.close();
        canvas.drawPath(arrowPath, arrowPaint);
        
        canvas.restore();
      }

    }
  }

  @override
  bool shouldRepaint(covariant _TransferArrowsPainter oldDelegate) => true;
}
