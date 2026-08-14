import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/settings_cubit.dart';
import 'mesh_account_card.dart';

class AnimatedDashboardCard extends StatefulWidget {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final double fixedExpenses;

  const AnimatedDashboardCard({
    super.key,
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.fixedExpenses,
  });

  @override
  State<AnimatedDashboardCard> createState() => _AnimatedDashboardCardState();
}

class _AnimatedDashboardCardState extends State<AnimatedDashboardCard> {
  @override
  Widget build(BuildContext context) {
    final teal = const Color(0xFF50C8C8);
    final totalSpend = widget.totalExpense + widget.fixedExpenses;
    final net = widget.totalIncome - totalSpend;
    final isPositive = net >= 0;

    // Build a simple sparkline from income vs expense ratio
    final List<FlSpot> sparklineSpots = _buildSparkline(
      widget.totalIncome,
      widget.totalExpense,
      widget.fixedExpenses,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: 4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ───────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Balance',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // ── Balance amount ────────────────────────────────────
            Text(
              AppFormatters.formatCurrency(context, widget.totalBalance),
              style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),

            // ── Trend line ────────────────────────────────────────
            if (widget.totalIncome > 0 || widget.totalExpense > 0)
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    size: 14,
                    color: isPositive ? teal : Colors.redAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isPositive
                        ? '+${AppFormatters.formatCurrency(context, net.abs())}'
                        : '-${AppFormatters.formatCurrency(context, net.abs())}',
                    style: TextStyle(
                      color: isPositive ? teal : Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(this month)',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            const SizedBox(height: 8),

            // ── Sparkline ─────────────────────────────────────────
            SizedBox(
              height: 24,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  minX: 0,
                  maxX: (sparklineSpots.length - 1).toDouble(),
                  minY: sparklineSpots.map((e) => e.y).reduce(min) - 10,
                  maxY: sparklineSpots.map((e) => e.y).reduce(max) + 10,
                  lineBarsData: [
                    LineChartBarData(
                      spots: sparklineSpots,
                      isCurved: true,
                      curveSmoothness: 0.4,
                      color: teal,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            teal.withOpacity(0.25),
                            teal.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Income / Expense / Fixed stats ────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF6FAFA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(context, 'Income', widget.totalIncome,
                      Icons.arrow_downward_rounded, teal),
                  Container(width: 1, height: 32, color: Colors.grey.shade200),
                  _buildStatItem(context, 'Expenses', widget.totalExpense,
                      Icons.arrow_upward_rounded, Colors.redAccent.shade100),
                  Container(width: 1, height: 32, color: Colors.grey.shade200),
                  _buildStatItem(context, 'Fixed', widget.fixedExpenses,
                      Icons.push_pin_rounded, Colors.amber.shade300),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, double amount,
      IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppFormatters.formatCurrency(context, amount),
            style: const TextStyle(
              color: Color(0xFF1A1A2E),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  List<FlSpot> _buildSparkline(double income, double expense, double fixed) {
    // Generate a 7-point wave representing income vs spend balance
    if (income == 0 && expense == 0) {
      return [
        const FlSpot(0, 50),
        const FlSpot(1, 52),
        const FlSpot(2, 48),
        const FlSpot(3, 55),
        const FlSpot(4, 50),
        const FlSpot(5, 53),
        const FlSpot(6, 50),
      ];
    }
    final total = income + expense + fixed + 1;
    final mid = total / 2;
    return [
      FlSpot(0, mid * 0.8),
      FlSpot(1, mid * 0.9),
      FlSpot(2, income / total * 100),
      FlSpot(3, mid * 1.05),
      FlSpot(4, (income - expense) / total * 100 + mid),
      FlSpot(5, mid * 0.95),
      FlSpot(6, income / (total + 0.001) * 100),
    ];
  }
}
