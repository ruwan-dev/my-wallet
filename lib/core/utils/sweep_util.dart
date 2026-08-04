import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../bloc/settings_cubit.dart';
import '../constants/app_constants.dart';
import '../utils/formatters.dart';
import '../../features/expenses/domain/entities/category.dart';
import '../../features/expenses/domain/entities/transaction.dart';
import '../../features/expenses/presentation/bloc/category_cubit.dart';
import '../../features/expenses/presentation/bloc/category_state.dart';
import '../../features/expenses/presentation/bloc/transaction_cubit.dart';
import '../../features/expenses/presentation/bloc/transaction_state.dart';

class SweepUtil {
  static Future<void> checkAndTriggerAutoSweep(
    BuildContext context, {
    bool force = false,
  }) async {
    try {
      final settings = context.read<SettingsCubit>().state;
      final paydayDate = settings.paydayDate;
      
      final prefs = await SharedPreferences.getInstance();
      final lastSweepMonth = prefs.getString(AppConstants.lastSweepMonthKey);
      
      final now = DateTime.now();
      
      // Only sweep on or after the payday date, unless forced
      if (!force && now.day < paydayDate) {
        return;
      }
      
      // Format: YYYY-MM
      final currentMonthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      if (!force && lastSweepMonth == currentMonthStr) {
        return; // Already swept this cycle
      }

      // Calculate total Daily Expenses balance up to the start of this payday
      // We look at all transactions BEFORE this current payday to find the leftover balance.
      // If forced, we just calculate based on now.
      final sweepCutoffDate = force ? now : DateTime(now.year, now.month, paydayDate);
      
      final txCubit = context.read<TransactionCubit>();
      if (txCubit.state is! TransactionLoaded) return;
      final allTransactions = (txCubit.state as TransactionLoaded).transactions;
      
      final previousTxs = allTransactions.where((tx) => tx.date.isBefore(sweepCutoffDate)).toList();
      
      if (previousTxs.isEmpty) {
        if (!force) await prefs.setString(AppConstants.lastSweepMonthKey, currentMonthStr);
        if (force && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No transactions to sweep.')),
          );
        }
        return;
      }

      double totalIncome = 0;
      double spentDailyExpenses = 0;

      final catCubit = context.read<CategoryCubit>();
      if (catCubit.state is! CategoryLoaded) return;
      final categories = (catCubit.state as CategoryLoaded).categories;

      for (final tx in previousTxs) {
        if (tx.isIncome) {
          totalIncome += tx.amount;
        } else {
          final category = categories.firstWhere(
            (c) => c.id == tx.categoryId,
            orElse: () => categories.first,
          );

          BucketType bucket = tx.bucketType ?? category.bucketType;
          if (tx.bucketType == null && tx.subCategory != null && category.subcategoryBuckets.containsKey(tx.subCategory)) {
            bucket = category.subcategoryBuckets[tx.subCategory]!;
          }

          if (bucket == BucketType.dailyExpenses) {
            spentDailyExpenses += tx.amount;
          }
        }
      }

      final dailyExpensesBalance = (totalIncome * 0.60) - spentDailyExpenses;

      if (dailyExpensesBalance > 0) {
        // Find Mojo category to assign the sweep expense
        final mojoCategory = categories.firstWhere(
          (c) => c.bucketType == BucketType.mojo,
          orElse: () => categories.first,
        );

        // Create Sweep Transaction (Expense with negative amount to add to Mojo balance)
        final sweepTx = TransactionEntity(
          id: const Uuid().v4(),
          accountId: 'default', // Using default/first account
          userId: 'temp', // TransactionCubit overrides this
          title: 'Auto-Sweep: Payday Leftovers',
          amount: -dailyExpensesBalance, // NEGATIVE expense adds to bucket balance
          categoryId: mojoCategory.id,
          categoryName: mojoCategory.name,
          date: sweepCutoffDate, // On Payday
          isIncome: false,
          note: 'Swept leftover Daily Expenses funds to Mojo on Payday',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          bucketType: BucketType.mojo,
        );

        await context.read<TransactionCubit>().addTransaction(sweepTx);

        // Show UI Alert
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Payday! We swept ${AppFormatters.formatCurrency(context, dailyExpensesBalance)} of leftover cash into your Mojo bucket!'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else if (force && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No leftover Daily Expenses funds to sweep.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Save flag
      if (!force) {
        await prefs.setString(AppConstants.lastSweepMonthKey, currentMonthStr);
      }
      
    } catch (e) {
      debugPrint('Error executing auto sweep: $e');
    }
  }
}
