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
  final double deficitAmount;   // Blow overspent, pulled from Fire
  final bool usedSmile;
  final bool usedSplurge;
  final bool usedMojo;
  final double debtAdded;

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
  });
}

// ─── Widget ──────────────────────────────────────────────────────────────────

class ForecastCardList extends StatelessWidget {
  final List<ForecastMonthCard> cards;
  final String Function(double) fmt;

  const ForecastCardList({super.key, required this.cards, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 430, // Increased height to fit cards + shadows
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none, // Allow shadows to overflow
        padding: const EdgeInsets.only(bottom: 30, top: 8, left: 4, right: 4),
        physics: const BouncingScrollPhysics(),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _MonthCard(card: cards[i], fmt: fmt, fmtShort: _fmtShort),
      ),
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
      ForecastHealth.safe    => (const Color(0xFF16A34A), Icons.check_circle_rounded,    const Color(0xFFDCFCE7)),
      ForecastHealth.warning => (const Color(0xFFD97706), Icons.warning_amber_rounded,   const Color(0xFFFEF3C7)),
      ForecastHealth.danger  => (const Color(0xFFDC2626), Icons.error_rounded,           const Color(0xFFFFE4E4)),
    };

    return Container(
      width: 270,
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
          if (card.sweepAmount > 0 || card.deficitAmount > 0 || card.usedSmile || card.usedSplurge || card.usedMojo || card.debtAdded > 0)
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
                    _EventRow('💸 Swept to Fire', fmt(card.sweepAmount), const Color(0xFF38B2AC)),
                  if (card.deficitAmount > 0)
                    _EventRow('⚡ Blow Overspent', '-${fmt(card.deficitAmount)}', const Color(0xFFE05263)),
                  if (card.usedSmile)
                    _EventRow('😊 Smile helped Fire', '', const Color(0xFFD946EF)),
                  if (card.usedSplurge)
                    _EventRow('🎉 Splurge helped Fire', '', const Color(0xFFF59E0B)),
                  if (card.usedMojo)
                    _EventRow('🛡️ Mojo covered deficit', '', const Color(0xFF3949AB)),
                  if (card.debtAdded > 0)
                    _EventRow('⚠️ Debt added', fmt(card.debtAdded), const Color(0xFFB91C1C)),
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
    final isUp        = b.change >= 0;
    final changeColor = isUp ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final changeIcon  = isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
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

          // Balance — takes all remaining space, right-aligned, NEVER wraps
          Expanded(
            child: Text(
              fmt(b.balance),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: balColor),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 4),

          // Change indicator — arrow + abbreviated amount, fixed width so it never pushes balance
          SizedBox(
            width: 44,
            child: b.change != 0
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(changeIcon, size: 9, color: changeColor),
                      const SizedBox(width: 1),
                      Flexible(
                        child: Text(
                          fmtShort(b.change.abs()),
                          style: TextStyle(fontSize: 9, color: changeColor, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: Text(
                      '-',
                      style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ),
          ),
        ],
      ),
     ),
    );
  }
}


