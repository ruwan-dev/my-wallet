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
import '../widgets/forecast_card_list.dart';

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
                  
                  // 1. Calculate All-Time Fire & Mojo Balances (Vaults)
                  double fireBalance = 0;
                  double mojoBalance = 0;
                  // We will calculate Smile and Splurge based on the current month's allocation
                  // since they are short-term spending wallets.

                  for (final tx in txState.transactions) {
                    final bucket = _getBucketForTx(tx, catState.categories);
                    if (bucket == BucketType.fire) {
                      fireBalance += tx.isIncome ? tx.amount : -tx.amount;
                    } else if (bucket == BucketType.mojo) {
                      mojoBalance += tx.isIncome ? tx.amount : -tx.amount;
                    } 
                  }

                  // 2. Calculate Current Month Income and Spending for Short-Term Buckets
                  double monthlyIncome = 0;
                  double currentBlowSpent = 0;
                  double currentSplurgeSpent = 0;
                  double currentSmileSpent = 0;

                  for (final tx in txState.transactions) {
                    if (tx.date.year == now.year && tx.date.month == now.month) {
                      if (tx.isIncome) {
                        monthlyIncome += tx.amount;
                      } else {
                        final bucket = _getBucketForTx(tx, catState.categories);
                        if (bucket == BucketType.dailyExpenses) {
                          currentBlowSpent += tx.amount;
                        } else if (bucket == BucketType.splurge) {
                          currentSplurgeSpent += tx.amount;
                        } else if (bucket == BucketType.smile) {
                          currentSmileSpent += tx.amount;
                        }
                      }
                    }
                  }

                  // 3. Get Budgets
                  double actualBlowAllocation = monthlyIncome * 0.60;
                  double customBlowBudget = actualBlowAllocation;
                  double fireBudget = monthlyIncome * 0.20;
                  double smileBudget = monthlyIncome * 0.10;
                  double splurgeBudget = monthlyIncome * 0.10;
                  if (budgetState is CustomBudgetLoaded) {
                    for (final b in budgetState.budgets) {
                      if (!b.isCompleted) {
                        if (b.bucketType == BucketType.dailyExpenses && b.totalAllocated > 0) customBlowBudget = b.totalAllocated;
                        if (b.bucketType == BucketType.fire && b.totalAllocated > 0) fireBudget = b.totalAllocated;
                      }
                    }
                  }

                  // 4. Set Starting Balances for Short-Term Wallets (Month 1)
                  double splurgeBalance = splurgeBudget - currentSplurgeSpent;
                  double smileBalance = smileBudget - currentSmileSpent;

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
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Forecast Cards only
                        _buildForecastCards(context, fireBalance, mojoBalance, smileBalance, splurgeBalance, month1Sweep, month1Deficit, fireBudget, smileBudget, splurgeBudget, actualBlowAllocation, customBlowBudget),
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

  Widget _buildForecastCards(
    BuildContext context,
    double startingFire,
    double startingMojo,
    double startingSmile,
    double startingSplurge,
    double month1Sweep,
    double month1Deficit,
    double monthlyFireAllocation,
    double monthlySmileAllocation,
    double monthlySplurgeAllocation,
    double actualBlowAllocation,
    double customBlowBudget,
  ) {
    String fmt(double v) => AppFormatters.formatCurrency(context, v);

    double projFire    = startingFire;
    double projMojo    = startingMojo;
    double projSmile   = startingSmile;
    double projSplurge = startingSplurge;
    double projDebt    = 0;

    // Previous balances for change arrows (start = current)
    double prevFire    = startingFire;
    double prevMojo    = startingMojo;
    double prevSmile   = startingSmile;
    double prevSplurge = startingSplurge;
    double prevDebt    = 0;

    final now = DateTime.now();
    final List<ForecastMonthCard> cards = [];

    for (int i = 0; i < 6; i++) {
      final targetDate = DateTime(now.year, now.month + i, 1);

      double sweep   = 0;
      double deficit = 0;
      double fireAlloc   = 0;
      double smileAlloc  = 0;
      double splurgeAlloc = 0;

      if (i == 0) {
        sweep   = month1Sweep;
        deficit = month1Deficit;
      } else {
        final futureSweep = actualBlowAllocation - customBlowBudget;
        if (futureSweep >= 0) {
          sweep = futureSweep;
        } else {
          deficit = futureSweep.abs();
        }
        fireAlloc    = monthlyFireAllocation;
        smileAlloc   = monthlySmileAllocation;
        splurgeAlloc = monthlySplurgeAllocation;
      }

      projFire    += sweep + fireAlloc - deficit;
      projSmile   += smileAlloc;
      projSplurge += splurgeAlloc;

      bool usedSmile   = false;
      bool usedSplurge = false;
      bool usedMojo    = false;

      if (projFire < 0) {
        double missing = projFire.abs();
        if (projSmile > 0) {
          final pull = projSmile >= missing ? missing : projSmile;
          projSmile -= pull;
          missing   -= pull;
          usedSmile  = true;
        }
        if (missing > 0 && projSplurge > 0) {
          final pull = projSplurge >= missing ? missing : projSplurge;
          projSplurge -= pull;
          missing     -= pull;
          usedSplurge  = true;
        }
        if (missing > 0) {
          projMojo -= missing;
          usedMojo  = true;
        }
        projFire = 0;
      }

      double debtAdded = 0;
      if (projMojo < 0) {
        debtAdded = projMojo.abs();
        projDebt += debtAdded;
        projMojo  = 0;
      }

      // Health status
      final ForecastHealth health;
      final String healthMsg;
      if (debtAdded > 0 || usedMojo) {
        health    = ForecastHealth.danger;
        healthMsg = usedMojo ? 'Emergency fund used!' : 'Going into debt!';
      } else if (usedSmile || usedSplurge) {
        health    = ForecastHealth.warning;
        healthMsg = 'Savings helping cover costs';
      } else if (deficit > 0) {
        health    = ForecastHealth.warning;
        healthMsg = 'Slight overspend covered';
      } else {
        health    = ForecastHealth.safe;
        healthMsg = sweep > 0 ? 'On track · saving surplus' : 'On track';
      }

      // Calculate Blow balance for the card
      double blowBalance = 0;
      if (i == 0) {
        blowBalance = sweep > 0 ? sweep : -deficit;
      } else {
        blowBalance = customBlowBudget > 0 ? customBlowBudget : actualBlowAllocation;
      }

      // Bucket rows (only show non-zero buckets or if it's Blow)
      final buckets = <BucketSnapshot>[
        BucketSnapshot(name: 'Blow', bucketType: BucketType.dailyExpenses, color: const Color(0xFF38B2AC), icon: Icons.shopping_cart, balance: blowBalance, change: 0),
        if (projFire != 0 || prevFire != 0)
          BucketSnapshot(name: 'Fire', bucketType: BucketType.fire, color: const Color(0xFFE05263), icon: Icons.local_fire_department, balance: projFire, change: projFire - prevFire),
        if (projSmile != 0 || prevSmile != 0)
          BucketSnapshot(name: 'Smile', bucketType: BucketType.smile, color: const Color(0xFFD946EF), icon: Icons.sentiment_satisfied, balance: projSmile, change: projSmile - prevSmile),
        if (projSplurge != 0 || prevSplurge != 0)
          BucketSnapshot(name: 'Splurge', bucketType: BucketType.splurge, color: const Color(0xFFF59E0B), icon: Icons.celebration, balance: projSplurge, change: projSplurge - prevSplurge),
        if (projMojo != 0 || prevMojo != 0)
          BucketSnapshot(name: 'Mojo', bucketType: BucketType.mojo, color: const Color(0xFF3949AB), icon: Icons.shield, balance: projMojo, change: projMojo - prevMojo),
        if (projDebt != 0 || prevDebt != 0)
          BucketSnapshot(name: 'Debt', bucketType: BucketType.none, color: const Color(0xFFB91C1C), icon: Icons.credit_card, balance: projDebt, change: projDebt - prevDebt), // Or whatever bucketType debt should have
      ];

      cards.add(ForecastMonthCard(
        monthLabel:    i == 0 ? 'End of ${DateFormat('MMM yyyy').format(targetDate)}' : DateFormat('MMM yyyy').format(targetDate),
        isCurrentMonth: i == 0,
        health:        health,
        healthMessage: healthMsg,
        buckets:       buckets,
        sweepAmount:   sweep,
        deficitAmount: deficit,
        usedSmile:     usedSmile,
        usedSplurge:   usedSplurge,
        usedMojo:      usedMojo,
        debtAdded:     debtAdded,
      ));

      // Update previous balances for next iteration
      prevFire    = projFire;
      prevMojo    = projMojo;
      prevSmile   = projSmile;
      prevSplurge = projSplurge;
      prevDebt    = projDebt;
    }

    return ForecastCardList(cards: cards, fmt: fmt);
  }
}

