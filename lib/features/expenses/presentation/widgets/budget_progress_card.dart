import 'package:flutter/material.dart';
import '../bloc/budget_state.dart';

class BudgetProgressCard extends StatelessWidget {
  final BudgetProgressSummary summary;

  const BudgetProgressCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final progress = summary.progressPercentage;
    final isWarning = progress >= 0.9;
    final isExceeded = progress >= 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                summary.budget.categoryName,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Rs ${summary.budget.limitAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress > 1.0 ? 1.0 : progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFF1F5F9), // Slate 100
              valueColor: AlwaysStoppedAnimation<Color>(
                isWarning ? const Color(0xFFF43F5E) : const Color(0xFF10B981), // Soft Coral vs Soft Emerald
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: Rs ${summary.totalSpent.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                isExceeded
                    ? 'Exceeded by Rs ${(summary.totalSpent - summary.budget.limitAmount).toStringAsFixed(2)}'
                    : 'Left: Rs ${summary.remainingAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isWarning ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
