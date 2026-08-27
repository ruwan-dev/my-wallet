import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/formatters.dart';
import '../bloc/transaction_cubit.dart';
import '../bloc/transaction_state.dart';
import '../bloc/category_cubit.dart';
import '../bloc/category_state.dart';
import '../../../budgets/presentation/bloc/custom_budget_cubit.dart';
import '../../../budgets/presentation/bloc/custom_budget_state.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/category.dart';
import '../widgets/shimmer_tile.dart';
import '../widgets/forecast_git_graph.dart';

class FinancialForecastPage extends StatelessWidget {
  const FinancialForecastPage({super.key});

  BucketType _getBucketForTx(TransactionEntity tx, List<Category> categories) {
    if (tx.bucketType != null) return tx.bucketType!;
    final cat = categories.firstWhere(
      (c) => c.id == tx.categoryId,
      orElse: () => const Category(id: '', name: 'Unknown', icon: '', color: Colors.grey, isIncome: false, subcategories: []),
    );
    if (tx.subCategory != null && cat.subcategoryBuckets.containsKey(tx.subCategory)) {
      return cat.subcategoryBuckets[tx.subCategory]!;
    }
    return cat.bucketType;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Bucket Forecast', style: theme.textTheme.titleMedium?.copyWith(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<CategoryCubit, CategoryState>(
        builder: (context, catState) {
          if (catState is! CategoryLoaded) return const ShimmerTile();
          
          return BlocBuilder<TransactionCubit, TransactionState>(
            builder: (context, txState) {
              if (txState is! TransactionLoaded) return const ShimmerTile();
              
              return BlocBuilder<CustomBudgetCubit, CustomBudgetState>(
                builder: (context, budgetState) {
                  final customBudgets = budgetState is CustomBudgetLoaded ? budgetState.budgets : [];

                  final now = DateTime.now();
                  
                  // 1. Calculate All-Time Fire & Mojo Balances
                  double fireBalance = 0;
                  double mojoBalance = 0;
                  for (final tx in txState.transactions) {
                    final bucket = _getBucketForTx(tx, catState.categories);
                    if (bucket == BucketType.fire) {
                      fireBalance += tx.isIncome ? tx.amount : -tx.amount;
                    } else if (bucket == BucketType.mojo) {
                      mojoBalance += tx.isIncome ? tx.amount : -tx.amount;
                    }
                  }

                  // 2. Calculate Current Month Income and Blow Spent
                  double monthlyIncome = 0;
                  double currentBlowSpent = 0;

                  for (final tx in txState.transactions) {
                    // Check if the transaction belongs to the current month and year
                    if (tx.date.year == now.year && tx.date.month == now.month) {
                      if (tx.isIncome) {
                        // Add to this month's income
                        monthlyIncome += tx.amount;
                      } else {
                        // Add to this month's Blow spent (if applicable)
                        final bucket = _getBucketForTx(tx, catState.categories);
                        if (bucket == BucketType.dailyExpenses) {
                          currentBlowSpent += tx.amount;
                        }
                      }
                    }
                  }

                  // 3. Get Budgets
                  double actualBlowAllocation = monthlyIncome * 0.60;
                  double customBlowBudget = actualBlowAllocation;
                  double fireBudget = monthlyIncome * 0.20;
                  if (budgetState is CustomBudgetLoaded) {
                    for (final b in budgetState.budgets) {
                      if (!b.isCompleted) {
                        if (b.bucketType == BucketType.dailyExpenses && b.totalAllocated > 0) customBlowBudget = b.totalAllocated;
                        if (b.bucketType == BucketType.fire && b.totalAllocated > 0) fireBudget = b.totalAllocated;
                      }
                    }
                  }

                  // 4. Calculate Month 1 Actuals (Sweep / Deficit)
                  double remainingCash = actualBlowAllocation - currentBlowSpent;
                  double month1Sweep = 0;
                  double month1Deficit = 0;
                  
                  if (remainingCash > 0) {
                    month1Sweep = remainingCash;
                  } else {
                    month1Deficit = remainingCash.abs();
                  }

                  // Budget configuration warning (UI only, does not deduct from Month 1 if unspent)
                  double budgetConfigDeficit = 0;
                  if (customBlowBudget > actualBlowAllocation) {
                    budgetConfigDeficit = customBlowBudget - actualBlowAllocation;
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Summary Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/forecast_bg.png'),
                              fit: BoxFit.cover,
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.work_outline, color: Color(0xFF1E293B), size: 20),
                                  const SizedBox(width: 8),
                                  Text('Current Blow (Daily) Status', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildBreakdownRow(context, 'Actual 60% Allocation', actualBlowAllocation, const Color(0xFF1E293B)),
                              const SizedBox(height: 8),
                              _buildBreakdownRow(context, 'Custom Budget Limit', customBlowBudget, const Color(0xFF1E293B)),
                              if (budgetConfigDeficit > 0) ...[
                                const SizedBox(height: 8),
                                _buildBreakdownRow(context, 'Budget Config Warning', budgetConfigDeficit, Colors.orange),
                              ],
                              const SizedBox(height: 8),
                              _buildBreakdownRow(context, 'Spent So Far', currentBlowSpent, const Color(0xFFB91C1C)),
                              const SizedBox(height: 12),
                              const Divider(endIndent: 120),
                              const SizedBox(height: 12),
                              if (month1Sweep > 0)
                                Text(
                                  'Available to Sweep: ${AppFormatters.formatCurrency(context, month1Sweep)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF166534)),
                                )
                              else if (month1Deficit > 0)
                                Text(
                                  'Actual Overspend: -${AppFormatters.formatCurrency(context, month1Deficit)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFB91C1C)),
                                )
                              else
                                Text(
                                  'Available to Sweep: ${AppFormatters.formatCurrency(context, 0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF166534)),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text('6-Month Bucket Projection', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                        const SizedBox(height: 16),
                        _buildGitGraph(context, fireBalance, mojoBalance, month1Sweep, month1Deficit, fireBudget, actualBlowAllocation, customBlowBudget),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBreakdownRow(BuildContext context, String label, double amount, Color amountColor) {
    return SizedBox(
      width: 310,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          Text(
            AppFormatters.formatCurrency(context, amount),
            style: TextStyle(fontWeight: FontWeight.bold, color: amountColor),
          ),
        ],
      ),
    );
  }

  Widget _buildGitGraph(BuildContext context, double startingFire, double startingMojo, double month1Sweep, double month1Deficit, double monthlyFireAllocation, double actualBlowAllocation, double customBlowBudget) {
    List<ForecastNode> graphNodes = [];
    double projectedFire = startingFire;
    double projectedMojo = startingMojo;
    double projectedDebt = 0;
    final now = DateTime.now();

    for (int i = 0; i < 6; i++) {
      final targetDate = DateTime(now.year, now.month + i, 1);
      
      double sweepAmount = 0;
      double allocationAmount = 0;
      double deficitAmount = 0;
      
      if (i == 0) {
        // Month 1 strictly uses current actuals
        sweepAmount = month1Sweep;
        allocationAmount = 0; // Already handled by actuals inside the month
        deficitAmount = month1Deficit;
      } else {
        // Future months base their sweep on the difference between actual income and planned budget
        double futureSweep = actualBlowAllocation - customBlowBudget;
        if (futureSweep < 0) {
          deficitAmount = futureSweep.abs();
          sweepAmount = 0;
        } else {
          sweepAmount = futureSweep;
          deficitAmount = 0;
        }
        allocationAmount = monthlyFireAllocation;
      }
      
      List<ForecastTransfer> transfers = [];

      if (sweepAmount > 0) {
        transfers.add(ForecastTransfer(TrackType.blow, TrackType.fire, sweepAmount, '+${AppFormatters.formatCurrency(context, sweepAmount)}', TrackColors.blow));
      }
      
      if (deficitAmount > 0) {
        // Pulling money FROM fire TO blow
        transfers.add(ForecastTransfer(TrackType.fire, TrackType.blow, deficitAmount, '-${AppFormatters.formatCurrency(context, deficitAmount)}', TrackColors.fire));
      }

      double totalFireAddition = sweepAmount + allocationAmount - deficitAmount;
      projectedFire += totalFireAddition;
      
      if (projectedFire < 0) {
        double fireDrain = projectedFire.abs();
        transfers.add(ForecastTransfer(TrackType.mojo, TrackType.fire, fireDrain, 'Cover: ${AppFormatters.formatCurrency(context, fireDrain)}', TrackColors.mojo));
        projectedMojo += projectedFire; // Drain Mojo
        projectedFire = 0;
      }
      if (projectedMojo < 0) {
        double mojoDrain = projectedMojo.abs();
        transfers.add(ForecastTransfer(TrackType.debt, TrackType.mojo, mojoDrain, 'Borrow: ${AppFormatters.formatCurrency(context, mojoDrain)}', TrackColors.debt));
        projectedDebt += projectedMojo;
        projectedMojo = 0;
      }

      graphNodes.add(ForecastNode(
        monthLabel: i == 0 ? 'End of ${DateFormat('MMM yyyy').format(targetDate)}' : DateFormat('MMMM yyyy').format(targetDate),
        fireBalance: projectedFire,
        fireBalanceStr: AppFormatters.formatCurrency(context, projectedFire),
        mojoBalance: projectedMojo,
        mojoBalanceStr: AppFormatters.formatCurrency(context, projectedMojo),
        debtBalance: projectedDebt,
        debtBalanceStr: AppFormatters.formatCurrency(context, projectedDebt),
        allocationAmount: allocationAmount,
        allocationAmountStr: '+${AppFormatters.formatCurrency(context, allocationAmount)}',
        transfers: transfers,
      ));
    }
    return ForecastGitGraph(nodes: graphNodes);
  }
}