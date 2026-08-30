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
  final String? sweepBreakdown; // e.g. "37k + 10k + 1.7k = 48.7k"
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
    this.sweepBreakdown,
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
                    _EventRow('Swept to Heal', card.sweepBreakdown ?? fmt(card.sweepAmount), const Color(0xFF38B2AC)),
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
