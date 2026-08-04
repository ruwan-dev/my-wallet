import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/formatters.dart';
import '../bloc/monthly_budget_cubit.dart';
import '../bloc/monthly_budget_state.dart';
import '../bloc/transaction_cubit.dart';
import '../bloc/transaction_state.dart';
import '../bloc/category_cubit.dart';
import '../bloc/category_state.dart';
import '../../domain/entities/monthly_budget.dart';

class MonthlyBudgetProgressCard extends StatelessWidget {
  final int month;
  final int year;

  const MonthlyBudgetProgressCard({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MonthlyBudgetCubit, MonthlyBudgetState>(
      builder: (context, budgetState) {
        if (budgetState is MonthlyBudgetLoaded && budgetState.budget != null) {
          final budget = budgetState.budget!;
          return BlocBuilder<TransactionCubit, TransactionState>(
            builder: (context, txState) {
              double totalSpent = 0.0;
              Map<String, double> categorySpent = {};

              if (txState is TransactionLoaded) {
                for (final tx in txState.transactions) {
                  if (!tx.isIncome && tx.date.month == month && tx.date.year == year) {
                    totalSpent += tx.amount;
                    categorySpent[tx.categoryId] = (categorySpent[tx.categoryId] ?? 0) + tx.amount;
                  }
                }
              }

              return _buildCard(context, budget, totalSpent, categorySpent);
            },
          );
        } else if (budgetState is MonthlyBudgetLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return const SizedBox.shrink(); // No budget set yet
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    MonthlyBudgetEntity budget,
    double totalSpent,
    Map<String, double> categorySpent,
  ) {
    final theme = Theme.of(context);
    final isTotalOver = totalSpent > budget.totalBudgetLimit;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly Budget',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${AppFormatters.formatCurrency(context, totalSpent)} / ${AppFormatters.formatCurrency(context, budget.totalBudgetLimit)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isTotalOver ? theme.colorScheme.error : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ProgressBar(spent: totalSpent, limit: budget.totalBudgetLimit),
                const SizedBox(height: 24),
                Text(
                  'Category Budgets',
                  style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                BlocBuilder<CategoryCubit, CategoryState>(
                  builder: (context, catState) {
                    if (catState is CategoryLoaded) {
                      final categories = catState.categories;
                      return Column(
                        children: budget.categoryLimits.entries.map((entry) {
                          final limit = entry.value;
                          final spent = categorySpent[entry.key] ?? 0.0;
                          final cat = categories.firstWhere((c) => c.id == entry.key);
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              children: [
                                Text(cat.icon, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(cat.name, style: theme.textTheme.bodySmall),
                                          Text(
                                            '${AppFormatters.formatCurrency(context, spent)} / ${AppFormatters.formatCurrency(context, limit)}',
                                            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      _ProgressBar(spent: spent, limit: limit),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double spent;
  final double limit;

  const _ProgressBar({required this.spent, required this.limit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    
    Color progressColor;
    if (ratio < 0.7) {
      progressColor = const Color(0xFF10B981); // Green
    } else if (ratio < 0.9) {
      progressColor = const Color(0xFFF59E0B); // Amber
    } else {
      progressColor = const Color(0xFFEF4444); // Red
    }

    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: ratio,
        child: Container(
          decoration: BoxDecoration(
            color: progressColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
