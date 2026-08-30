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
import '../../../debts/presentation/bloc/debt_cubit.dart';
import '../../../debts/presentation/bloc/debt_state.dart';
import '../../../debts/domain/entities/debt.dart';

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
      body: BlocBuilder<DebtCubit, DebtState>(
        builder: (context, debtState) {
          if (debtState is! DebtLoaded) return const ShimmerTile();
          final activeDebts = debtState.debts.where((d) => d.currentBalance > 0).toList();

          return BlocBuilder<CategoryCubit, CategoryState>(
            builder: (context, catState) {
              if (catState is! CategoryLoaded) return const ShimmerTile();
              
              return BlocBuilder<TransactionCubit, TransactionState>(
                builder: (context, txState) {
                  if (txState is! TransactionLoaded) return const ShimmerTile();
                  
                  return BlocBuilder<CustomBudgetCubit, CustomBudgetState>(
                    builder: (context, budgetState) {
                      final customBudgets = budgetState is CustomBudgetLoaded ? budgetState.budgets : [];

                  final now = DateTime.now();
                  
                  // 1. Calculate All-Time Heal & Mojo Balances (Vaults)
                  double healBalance = 0;
                  double mojoBalance = 0;
                  // We will calculate Smile and Splurge based on the current month's allocation
                  // since they are short-term spending wallets.

                  for (final tx in txState.transactions) {
                    final bucket = _getBucketForTx(tx, catState.categories);
                    if (bucket == BucketType.heal) {
                      healBalance += tx.isIncome ? tx.amount : -tx.amount;
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
                  double healBudget = monthlyIncome * 0.20;
                  double smileBudget = monthlyIncome * 0.10;
                  double splurgeBudget = monthlyIncome * 0.10;
                  if (budgetState is CustomBudgetLoaded) {
                    for (final b in budgetState.budgets) {
                      if (!b.isCompleted) {
                        if (b.bucketType == BucketType.dailyExpenses && b.totalAllocated > 0) customBlowBudget = b.totalAllocated;
                        if (b.bucketType == BucketType.heal && b.totalAllocated > 0) healBudget = b.totalAllocated;
                      }
                    }
                  }

                  // 4. Set Starting Balances for Short-Term Wallets (Month 1)
                  double splurgeBalance = splurgeBudget - currentSplurgeSpent;
                  double smileBalance = smileBudget - currentSmileSpent;
                  double currentHealBalance = healBalance + healBudget;
  
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
                        _buildForecastCards(context, currentHealBalance, mojoBalance, smileBalance, splurgeBalance, month1Sweep, month1Deficit, healBudget, smileBudget, splurgeBudget, actualBlowAllocation, customBlowBudget, activeDebts),
                      ],
                    ),
                  ); // SingleChildScrollView
                },
              ); // CustomBudgetCubit
            },
          ); // TransactionCubit
        },
      ); // CategoryCubit
    },
   ),
  );
 }

  Widget _buildForecastCards(
    BuildContext context,
    double startingHeal,
    double startingMojo,
    double startingSmile,
    double startingSplurge,
    double month1Sweep,
    double month1Deficit,
    double monthlyHealAllocation,
    double monthlySmileAllocation,
    double monthlySplurgeAllocation,
    double actualBlowAllocation,
    double customBlowBudget,
    List<Debt> activeDebts,
  ) {
    String fmt(double v) => AppFormatters.formatCurrency(context, v);
    
    String fmtShort(double v) {
      final sign = v < 0 ? '-' : '';
      final abs  = v.abs();
      if (abs >= 1000000) return '${sign}${(abs / 1000000).toStringAsFixed(1)}M';
      if (abs >= 1000)    return '${sign}${(abs / 1000).toStringAsFixed(1)}k';
      return '$sign${abs.toStringAsFixed(0)}';
    }

    double projHeal    = startingHeal;
    double projMojo    = startingMojo;
    double projSmile   = startingSmile;
    double projSplurge = startingSplurge;
    double projDebt    = 0;

    // Previous balances for change arrows (start = current)
    double prevHeal    = startingHeal;
    double prevMojo    = startingMojo;
    double prevSmile   = startingSmile;
    double prevSplurge = startingSplurge;
    double prevDebt    = 0;

    final now = DateTime.now();
    final List<ForecastMonthCard> cards = [];
    final List<Widget> suggestionWidgets = [];

    for (int i = 0; i < 6; i++) {
      final targetDate = DateTime(now.year, now.month + i, 1);

      double currentBlowRemaining = 0;
      double currentDeficit = 0;
      double blowDisplayBalance = 0;
      
      // 1. Add this month's allocations
      if (i == 0) {
        // Month 0: We use the actual current remaining balances
        currentBlowRemaining = month1Sweep;
        currentDeficit     = month1Deficit;
        blowDisplayBalance = month1Sweep > 0 ? month1Sweep : -month1Deficit;
        // starting balances for Smile, Splurge, Heal are already in projSmile, projSplurge, projHeal.
      } else {
        // Future months: Add the new monthly allocations
        projHeal    += monthlyHealAllocation;
        projSmile   += monthlySmileAllocation;
        projSplurge += monthlySplurgeAllocation;
        
        // For future months, the user wants to see the "initial values" (the full budget allocations)
        blowDisplayBalance = actualBlowAllocation;
        
        // But for the *sweep* at the end of the future month, we predict they will spend their custom budget
        final futureSweep = actualBlowAllocation - customBlowBudget;
        if (futureSweep >= 0) {
          currentBlowRemaining = futureSweep;
        } else {
          currentDeficit = futureSweep.abs();
          currentBlowRemaining = 0;
        }
      }

      // 2. Pay debts due this month
      double currentMonthDebtPaid = 0;
      List<String> currentMonthPaidNames = [];
      
      for (final debt in activeDebts) {
        if (debt.dueDate != null) {
          bool isDueThisMonth = false;
          if (i == 0) {
             if (debt.dueDate!.isBefore(DateTime(now.year, now.month + 1, 1))) {
                isDueThisMonth = true;
             }
          } else {
             if (debt.dueDate!.year == targetDate.year && debt.dueDate!.month == targetDate.month) {
                isDueThisMonth = true;
             }
          }

          if (isDueThisMonth) {
            currentMonthDebtPaid += debt.currentBalance;
            currentMonthPaidNames.add(debt.name);
          }
        }
      }

      projHeal -= currentMonthDebtPaid;

      // 3. Cover negative buckets (Blow Deficit and Heal Debt Payments)
      bool usedSmile   = false;
      bool usedSplurge = false;
      bool usedMojo    = false;
      double debtAdded = 0;
      
      List<String> blowCoverages = [];
      List<String> healCoverages = [];

      // A. Cover Blow Deficit
      if (currentDeficit > 0) {
        double missing = currentDeficit;
        if (missing > 0 && projSmile > 0) {
          final pull = projSmile >= missing ? missing : projSmile;
          projSmile -= pull;
          missing   -= pull;
          usedSmile  = true;
          blowCoverages.add('Covered by Smile (+${fmtShort(pull)})');
        }
        if (missing > 0 && projSplurge > 0) {
          final pull = projSplurge >= missing ? missing : projSplurge;
          projSplurge -= pull;
          missing     -= pull;
          usedSplurge  = true;
          blowCoverages.add('Covered by Splurge (+${fmtShort(pull)})');
        }
        if (missing > 0 && projMojo > 0) {
          final pull = projMojo >= missing ? missing : projMojo;
          projMojo -= pull;
          missing  -= pull;
          usedMojo  = true;
          blowCoverages.add('Covered by Mojo (+${fmtShort(pull)})');
        }
        if (missing > 0) {
          projDebt += missing;
          debtAdded += missing;
          blowCoverages.add('Added to Debt (+${fmtShort(missing)})');
        }
      }

      // B. Cover Heal (if they paid more debt than they had in Heal)
      if (projHeal < 0) {
        double missing = projHeal.abs();
        if (missing > 0 && projSmile > 0) {
          final pull = projSmile >= missing ? missing : projSmile;
          projSmile -= pull;
          missing   -= pull;
          usedSmile  = true;
          healCoverages.add('Covered by Smile (+${fmtShort(pull)})');
        }
        if (missing > 0 && projSplurge > 0) {
          final pull = projSplurge >= missing ? missing : projSplurge;
          projSplurge -= pull;
          missing     -= pull;
          usedSplurge  = true;
          healCoverages.add('Covered by Splurge (+${fmtShort(pull)})');
        }
        if (missing > 0 && projMojo > 0) {
          final pull = projMojo >= missing ? missing : projMojo;
          projMojo -= pull;
          missing  -= pull;
          usedMojo  = true;
          healCoverages.add('Covered by Mojo (+${fmtShort(pull)})');
        }
        if (missing > 0) {
          projDebt += missing;
          debtAdded += missing;
          healCoverages.add('Added to Debt (+${fmtShort(missing)})');
        }
        projHeal = 0;
      }

      if (projMojo < 0) {
        debtAdded += projMojo.abs();
        projDebt += projMojo.abs();
        projMojo  = 0;
      }

      // 4. Calculate what will be swept at the end of THIS month
      double totalSweepToHeal = currentBlowRemaining + projSmile + projSplurge;

      String? sweepBreakdown;
      if (totalSweepToHeal > 0) {
        List<String> parts = [];
        if (currentBlowRemaining > 0) parts.add(fmtShort(currentBlowRemaining));
        if (projSmile > 0) parts.add(fmtShort(projSmile));
        if (projSplurge > 0) parts.add(fmtShort(projSplurge));
        
        if (parts.length > 1) {
          sweepBreakdown = '${parts.join(" + ")} = ${fmtShort(totalSweepToHeal)}';
        }
      }

      // 5. Record the card state BEFORE the sweep happens
      final ForecastHealth health;
      final String healthMsg;
      if (debtAdded > 0 || usedMojo) {
        health    = ForecastHealth.danger;
        healthMsg = usedMojo ? 'Emergency fund used!' : 'Going into debt!';
      } else if (usedSmile || usedSplurge) {
        health    = ForecastHealth.warning;
        healthMsg = 'Savings helping cover costs';
      } else if (currentDeficit > 0) {
        health    = ForecastHealth.warning;
        healthMsg = 'Slight overspend covered';
      } else {
        health    = ForecastHealth.safe;
        healthMsg = currentBlowRemaining > 0 ? 'On track · saving surplus' : 'On track';
      }

      final buckets = <BucketSnapshot>[
        BucketSnapshot(name: 'Blow', bucketType: BucketType.dailyExpenses, color: const Color(0xFF38B2AC), icon: Icons.shopping_cart, balance: blowDisplayBalance, change: 0, coverages: blowCoverages),
        BucketSnapshot(name: 'Heal', bucketType: BucketType.heal, color: const Color(0xFFE05263), icon: Icons.medical_services, balance: projHeal, change: projHeal - prevHeal, coverages: healCoverages),
        if (projSmile != 0 || prevSmile != 0)
          BucketSnapshot(name: 'Smile', bucketType: BucketType.smile, color: const Color(0xFFD946EF), icon: Icons.sentiment_satisfied, balance: projSmile, change: projSmile - prevSmile),
        if (projSplurge != 0 || prevSplurge != 0)
          BucketSnapshot(name: 'Splurge', bucketType: BucketType.splurge, color: const Color(0xFFF59E0B), icon: Icons.celebration, balance: projSplurge, change: projSplurge - prevSplurge),
        if (projMojo != 0 || prevMojo != 0)
          BucketSnapshot(name: 'Mojo', bucketType: BucketType.mojo, color: const Color(0xFF3949AB), icon: Icons.shield, balance: projMojo, change: projMojo - prevMojo),
        if (projDebt != 0 || prevDebt != 0)
          BucketSnapshot(name: 'Debt', bucketType: BucketType.none, color: const Color(0xFFB91C1C), icon: Icons.credit_card, balance: projDebt, change: projDebt - prevDebt),
      ];

      cards.add(ForecastMonthCard(
        monthLabel:    i == 0 ? 'End of ${DateFormat('MMM yyyy').format(targetDate)}' : DateFormat('MMM yyyy').format(targetDate),
        isCurrentMonth: i == 0,
        health:        health,
        healthMessage: healthMsg,
        buckets:       buckets,
        sweepAmount:   totalSweepToHeal, // Display the TOTAL swept to Heal
        sweepBreakdown: sweepBreakdown,
        deficitAmount: currentDeficit,
        usedSmile:     usedSmile,
        usedSplurge:   usedSplurge,
        usedMojo:      usedMojo,
        debtAdded:     debtAdded,
        debtPaidAmount: currentMonthDebtPaid,
        paidDebtNames:  currentMonthPaidNames,
      ));

      // Update previous balances for next iteration display
      prevHeal    = projHeal;
      prevMojo    = projMojo;
      prevSmile   = projSmile;
      prevSplurge = projSplurge;
      prevDebt    = projDebt;

      if (i == 0) {
        double totalDebtBalance = activeDebts.fold(0.0, (sum, d) => sum + d.currentBalance);
        
        // Suggestion 1: Sweep Surplus to Debt
        if (totalSweepToHeal > 0 && totalDebtBalance > 0) {
           final targetDebt = activeDebts.firstWhere((d) => d.currentBalance > 0, orElse: () => activeDebts.first);
           suggestionWidgets.add(_buildSuggestionCard(
             icon: Icons.lightbulb_circle,
             color: Colors.amber.shade700,
             title: 'Accelerate Debt Payoff',
             message: 'You have ${fmt(totalSweepToHeal)} sweeping to Heal this month. Consider using it to pay off your ${targetDebt.name} faster and save on interest!',
           ));
        }

        // Suggestion 2: Overspent
        if (currentDeficit > 0) {
           suggestionWidgets.add(_buildSuggestionCard(
             icon: Icons.warning_rounded,
             color: Colors.red.shade600,
             title: 'Blow Overspent',
             message: 'You overspent your daily expenses by ${fmt(currentDeficit)}. Try to cut back next month so your savings can grow.',
           ));
        }
        
        // Suggestion 3: Emergency Fund Used
        if (usedMojo) {
           suggestionWidgets.add(_buildSuggestionCard(
             icon: Icons.shield,
             color: Colors.blue.shade700,
             title: 'Emergency Fund Used',
             message: 'You had to dip into Mojo to cover your deficit. Prioritize rebuilding your emergency fund next month!',
           ));
        }
      }

      // 6. Execute the Sweep: EVERYTHING leftover goes to Heal for NEXT month
      projHeal += totalSweepToHeal;
      projSmile = 0;
      projSplurge = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (suggestionWidgets.isNotEmpty) ...[
          const Text('Insights & Suggestions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          ...suggestionWidgets,
          const SizedBox(height: 24),
          const Text('6-Month Forecast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
        ],
        ForecastCardList(cards: cards, fmt: fmt),
      ],
    );
  }

  Widget _buildSuggestionCard({required IconData icon, required Color color, required String title, required String message}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(message, style: TextStyle(color: Colors.black87, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

