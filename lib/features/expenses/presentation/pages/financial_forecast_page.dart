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

class SimulatedTransfer {
  final int monthIndex;
  final BucketType fromBucket;
  final BucketType toBucket;
  final double amount;

  SimulatedTransfer({
    required this.monthIndex,
    required this.fromBucket,
    required this.toBucket,
    required this.amount,
  });
}

class FinancialForecastPage extends StatefulWidget {
  const FinancialForecastPage({super.key});

  @override
  State<FinancialForecastPage> createState() => _FinancialForecastPageState();
}

class _FinancialForecastPageState extends State<FinancialForecastPage> {
  List<SimulatedTransfer> simulatedTransfers = [];

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
                  // We will calculate Smile and Enjoy based on the current month's allocation
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
                  double currentLivingSpent = 0;
                  double currentEnjoySpent = 0;
                  double currentSmileSpent = 0;

                  for (final tx in txState.transactions) {
                    if (tx.date.year == now.year && tx.date.month == now.month) {
                      if (tx.isIncome) {
                        monthlyIncome += tx.amount;
                      } else {
                        final bucket = _getBucketForTx(tx, catState.categories);
                        if (bucket == BucketType.dailyExpenses) {
                          currentLivingSpent += tx.amount;
                        } else if (bucket == BucketType.enjoy) {
                          currentEnjoySpent += tx.amount;
                        } else if (bucket == BucketType.smile) {
                          currentSmileSpent += tx.amount;
                        }
                      }
                    }
                  }

                  // 3. Get Budgets
                  double actualLivingAllocation = monthlyIncome * 0.60;
                  double customLivingBudget = actualLivingAllocation;
                  double healBudget = monthlyIncome * 0.20;
                  double smileBudget = monthlyIncome * 0.10;
                  double enjoyBudget = monthlyIncome * 0.10;
                  if (budgetState is CustomBudgetLoaded) {
                    for (final b in budgetState.budgets) {
                      if (!b.isCompleted) {
                        if (b.bucketType == BucketType.dailyExpenses && b.totalAllocated > 0) customLivingBudget = b.totalAllocated;
                        if (b.bucketType == BucketType.heal && b.totalAllocated > 0) healBudget = b.totalAllocated;
                      }
                    }
                  }

                  // 4. Set Starting Balances for Short-Term Wallets (Month 1)
                  double enjoyBalance = enjoyBudget - currentEnjoySpent;
                  double smileBalance = smileBudget - currentSmileSpent;
                  double currentHealBalance = healBalance + healBudget;
  
                  // 4. Calculate Month 1 Actuals (Sweep / Deficit)
                  double remainingCash = actualLivingAllocation - currentLivingSpent;
                  double month1Sweep = 0;
                  double month1Deficit = 0;
                  
                  if (remainingCash > 0) {
                    month1Sweep = remainingCash;
                  } else {
                    month1Deficit = remainingCash.abs();
                  }

                  // Budget configuration warning (UI only, does not deduct from Month 1 if unspent)
                  double budgetConfigDeficit = 0;
                  if (customLivingBudget > actualLivingAllocation) {
                    budgetConfigDeficit = customLivingBudget - actualLivingAllocation;
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Forecast Cards only
                        _buildForecastCards(context, currentHealBalance, mojoBalance, smileBalance, enjoyBalance, month1Sweep, month1Deficit, healBudget, smileBudget, enjoyBudget, actualLivingAllocation, customLivingBudget, activeDebts),
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
    double startingEnjoy,
    double month1Sweep,
    double month1Deficit,
    double monthlyHealAllocation,
    double monthlySmileAllocation,
    double monthlyEnjoyAllocation,
    double actualLivingAllocation,
    double customLivingBudget,
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
    double projEnjoy = startingEnjoy;
    double projDebt    = 0;

    // Previous balances for change arrows (start = current)
    double prevHeal    = startingHeal;
    double prevMojo    = startingMojo;
    double prevSmile   = startingSmile;
    double prevEnjoy = startingEnjoy;
    double prevDebt    = 0;

    final now = DateTime.now();
    final List<ForecastMonthCard> cards = [];
    final List<Widget> suggestionWidgets = [];

    for (int i = 0; i < 6; i++) {
      final targetDate = DateTime(now.year, now.month + i, 1);

      double currentLivingRemaining = 0;
      double currentDeficit = 0;
      double livingDisplayBalance = 0;
      
      // 1. Add this month's allocations
      if (i == 0) {
        // Month 0: We use the actual current remaining balances
        currentLivingRemaining = month1Sweep;
        currentDeficit     = month1Deficit;
        livingDisplayBalance = month1Sweep > 0 ? month1Sweep : -month1Deficit;
        // starting balances for Smile, Enjoy, Heal are already in projSmile, projEnjoy, projHeal.
      } else {
        // Future months: Add the new monthly allocations
        projHeal    += monthlyHealAllocation;
        projSmile   += monthlySmileAllocation;
        projEnjoy += monthlyEnjoyAllocation;
        
        // For future months, the user wants to see the "initial values" (the full budget allocations)
        livingDisplayBalance = actualLivingAllocation;
        
        // But for the *sweep* at the end of the future month, we predict they will spend their custom budget
        final futureSweep = actualLivingAllocation - customLivingBudget;
        if (futureSweep >= 0) {
          currentLivingRemaining = futureSweep;
        } else {
          currentDeficit = futureSweep.abs();
          currentLivingRemaining = 0;
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

      // 3. Apply Simulated Manual Transfers for this month
      List<BucketType> livingCoveredBy = [];
      List<BucketType> healCoveredBy = [];
      List<BucketType> smileCoveredBy = [];
      List<BucketType> enjoyCoveredBy = [];
      List<BucketType> mojoCoveredBy = [];
      
      final monthTransfers = simulatedTransfers.where((t) => t.monthIndex == i);
      for (final t in monthTransfers) {
        // Subtract from source
        if (t.fromBucket == BucketType.dailyExpenses) currentLivingRemaining -= t.amount;
        if (t.fromBucket == BucketType.smile) projSmile -= t.amount;
        if (t.fromBucket == BucketType.enjoy) projEnjoy -= t.amount;
        if (t.fromBucket == BucketType.heal) projHeal -= t.amount;
        if (t.fromBucket == BucketType.mojo) projMojo -= t.amount;
        
        // Add to destination
        if (t.toBucket == BucketType.dailyExpenses) {
           currentDeficit -= t.amount;
           livingDisplayBalance += t.amount;
           if (currentDeficit < 0) {
             currentLivingRemaining += currentDeficit.abs();
             currentDeficit = 0;
           }
           livingCoveredBy.add(t.fromBucket);
        } else if (t.toBucket == BucketType.heal) {
           projHeal += t.amount;
           healCoveredBy.add(t.fromBucket);
        } else if (t.toBucket == BucketType.smile) {
           projSmile += t.amount;
           smileCoveredBy.add(t.fromBucket);
        } else if (t.toBucket == BucketType.enjoy) {
           projEnjoy += t.amount;
           enjoyCoveredBy.add(t.fromBucket);
        } else if (t.toBucket == BucketType.mojo) {
           projMojo += t.amount;
           mojoCoveredBy.add(t.fromBucket);
        }
      }

      // Check for unresolved deficits
      bool hasUnresolvedDeficits = currentDeficit > 0 || projHeal < 0 || projSmile < 0 || projEnjoy < 0 || projMojo < 0;

      // Track uncovered deficits to pass to the UI
      double uncoveredLivingDeficit = currentDeficit > 0 ? currentDeficit : 0;
      double uncoveredHealDeficit = projHeal < 0 ? projHeal.abs() : 0;
      double uncoveredSmileDeficit = projSmile < 0 ? projSmile.abs() : 0;
      double uncoveredEnjoyDeficit = projEnjoy < 0 ? projEnjoy.abs() : 0;
      double uncoveredMojoDeficit = projMojo < 0 ? projMojo.abs() : 0;

      double debtAdded = 0;

      // 4. Calculate what will be swept at the end of THIS month
      // We only sweep if there are NO unresolved deficits
      double totalSweepToHeal = 0;
      String? sweepBreakdown;
      
      if (!hasUnresolvedDeficits) {
        totalSweepToHeal = currentLivingRemaining + projSmile + projEnjoy;
        if (totalSweepToHeal > 0) {
          List<String> parts = [];
          if (currentLivingRemaining > 0) parts.add(fmtShort(currentLivingRemaining));
          if (projSmile > 0) parts.add(fmtShort(projSmile));
          if (projEnjoy > 0) parts.add(fmtShort(projEnjoy));
          
          if (parts.length > 1) {
            sweepBreakdown = '${parts.join(" + ")} = ${fmtShort(totalSweepToHeal)}';
          }
        }
      } else {
        // If there ARE unresolved deficits, the simulation assumes you go into debt at the end of the month
        if (currentDeficit > 0) { projDebt += currentDeficit; debtAdded += currentDeficit; }
        if (projHeal < 0) { projDebt += projHeal.abs(); debtAdded += projHeal.abs(); projHeal = 0; }
        if (projSmile < 0) { projDebt += projSmile.abs(); debtAdded += projSmile.abs(); projSmile = 0; }
        if (projEnjoy < 0) { projDebt += projEnjoy.abs(); debtAdded += projEnjoy.abs(); projEnjoy = 0; }
        if (projMojo < 0) { projDebt += projMojo.abs(); debtAdded += projMojo.abs(); projMojo = 0; }
      }

      // 5. Record the card state BEFORE the sweep happens
      final ForecastHealth health;
      final String healthMsg;
      
      bool usedMojo = livingCoveredBy.contains(BucketType.mojo) || healCoveredBy.contains(BucketType.mojo) ||
                      smileCoveredBy.contains(BucketType.mojo) || enjoyCoveredBy.contains(BucketType.mojo);
      bool usedSavings = livingCoveredBy.contains(BucketType.smile) || livingCoveredBy.contains(BucketType.enjoy) ||
                         healCoveredBy.contains(BucketType.smile) || healCoveredBy.contains(BucketType.enjoy);

      if (debtAdded > 0 || usedMojo || hasUnresolvedDeficits) {
        health    = ForecastHealth.danger;
        if (uncoveredLivingDeficit > 0) {
          healthMsg = 'Living overspent!';
        } else if (hasUnresolvedDeficits) {
          healthMsg = 'Resolve deficits!';
        } else if (usedMojo) {
          healthMsg = 'Emergency fund used!';
        } else {
          healthMsg = 'Going into debt!';
        }
      } else if (usedSavings) {
        health    = ForecastHealth.warning;
        healthMsg = 'Savings helping cover costs';
      } else {
        health    = ForecastHealth.safe;
        healthMsg = currentLivingRemaining > 0 ? 'On track · saving surplus' : 'On track';
      }

      final buckets = <BucketSnapshot>[
        BucketSnapshot(name: 'Living', bucketType: BucketType.dailyExpenses, color: const Color(0xFF38B2AC), icon: Icons.shopping_cart, balance: livingDisplayBalance, change: 0),
        BucketSnapshot(name: 'Heal', bucketType: BucketType.heal, color: const Color(0xFFE05263), icon: Icons.medical_services, balance: projHeal, change: projHeal - prevHeal),
        if (projSmile != 0 || prevSmile != 0)
          BucketSnapshot(name: 'Smile', bucketType: BucketType.smile, color: const Color(0xFFD946EF), icon: Icons.sentiment_satisfied, balance: projSmile, change: projSmile - prevSmile),
        if (projEnjoy != 0 || prevEnjoy != 0)
          BucketSnapshot(name: 'Enjoy', bucketType: BucketType.enjoy, color: const Color(0xFFF59E0B), icon: Icons.celebration, balance: projEnjoy, change: projEnjoy - prevEnjoy),
        if (projMojo != 0 || prevMojo != 0)
          BucketSnapshot(name: 'Mojo', bucketType: BucketType.mojo, color: const Color(0xFF3949AB), icon: Icons.shield, balance: projMojo, change: projMojo - prevMojo),
        if (projDebt != 0 || prevDebt != 0)
          BucketSnapshot(name: 'Debt', bucketType: BucketType.none, color: const Color(0xFFB91C1C), icon: Icons.credit_card, balance: projDebt, change: projDebt - prevDebt),
      ];

      List<ArrowEvent> arrows = [];
      for (var type in livingCoveredBy) {
        int fromIdx = buckets.indexWhere((b) => b.bucketType == type);
        int toIdx = buckets.indexWhere((b) => b.bucketType == BucketType.dailyExpenses);
        if (fromIdx != -1 && toIdx != -1) arrows.add(ArrowEvent(fromIdx, toIdx, const Color(0xFF38B2AC)));
      }
      for (var type in healCoveredBy) {
        int fromIdx = buckets.indexWhere((b) => b.bucketType == type);
        int toIdx = buckets.indexWhere((b) => b.bucketType == BucketType.heal);
        if (fromIdx != -1 && toIdx != -1) arrows.add(ArrowEvent(fromIdx, toIdx, const Color(0xFF38B2AC)));
      }
      for (var type in smileCoveredBy) {
        int fromIdx = buckets.indexWhere((b) => b.bucketType == type);
        int toIdx = buckets.indexWhere((b) => b.bucketType == BucketType.smile);
        if (fromIdx != -1 && toIdx != -1) arrows.add(ArrowEvent(fromIdx, toIdx, const Color(0xFF38B2AC)));
      }
      for (var type in enjoyCoveredBy) {
        int fromIdx = buckets.indexWhere((b) => b.bucketType == type);
        int toIdx = buckets.indexWhere((b) => b.bucketType == BucketType.enjoy);
        if (fromIdx != -1 && toIdx != -1) arrows.add(ArrowEvent(fromIdx, toIdx, const Color(0xFF38B2AC)));
      }
      for (var type in mojoCoveredBy) {
        int fromIdx = buckets.indexWhere((b) => b.bucketType == type);
        int toIdx = buckets.indexWhere((b) => b.bucketType == BucketType.mojo);
        if (fromIdx != -1 && toIdx != -1) arrows.add(ArrowEvent(fromIdx, toIdx, const Color(0xFF38B2AC)));
      }

      cards.add(ForecastMonthCard(
        monthIndex: i,
        monthLabel:    i == 0 ? 'End of ${DateFormat('MMM yyyy').format(targetDate)}' : DateFormat('MMM yyyy').format(targetDate),
        isCurrentMonth: i == 0,
        health:        health,
        healthMessage: healthMsg,
        buckets:       buckets,
        arrows:        arrows,
        sweepAmount:   totalSweepToHeal,
        sweepBreakdown: sweepBreakdown,
        hasUnresolvedDeficits: hasUnresolvedDeficits,
        uncoveredLivingDeficit: uncoveredLivingDeficit,
        uncoveredHealDeficit: uncoveredHealDeficit,
        uncoveredSmileDeficit: uncoveredSmileDeficit,
        uncoveredEnjoyDeficit: uncoveredEnjoyDeficit,
        uncoveredMojoDeficit: uncoveredMojoDeficit,
        debtAdded:     debtAdded,
        debtPaidAmount: currentMonthDebtPaid,
        paidDebtNames:  currentMonthPaidNames,
        availableLiving: currentLivingRemaining,
        availableSmile: projSmile > 0 ? projSmile : 0,
        availableEnjoy: projEnjoy > 0 ? projEnjoy : 0,
        availableHeal: projHeal > 0 ? projHeal : 0,
        availableMojo: projMojo > 0 ? projMojo : 0,
        onSimulateTransfer: (from, to, amount) {
          setState(() {
            simulatedTransfers.add(SimulatedTransfer(
              monthIndex: i,
              fromBucket: from,
              toBucket: to,
              amount: amount,
            ));
          });
        },
      ));

      // Update previous balances for next iteration display
      prevHeal    = projHeal;
      prevMojo    = projMojo;
      prevSmile   = projSmile;
      prevEnjoy = projEnjoy;
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
             title: 'Living Overspent',
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
      projEnjoy = 0;
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

