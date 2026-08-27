import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/custom_budget.dart';
import '../bloc/custom_budget_cubit.dart';
import '../bloc/custom_budget_state.dart';
import '../../../expenses/presentation/bloc/transaction_cubit.dart';
import '../../../expenses/presentation/bloc/transaction_state.dart';
import '../../../expenses/domain/entities/transaction.dart';
import 'create_custom_budget_page.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/shimmer_tile.dart';
import '../../../../features/expenses/domain/entities/category.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/category_icon.dart';
import '../../../../core/bloc/settings_cubit.dart';
import 'dart:typed_data';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../../expenses/presentation/bloc/account_cubit.dart';
import '../../../expenses/presentation/bloc/account_state.dart';
import '../../../expenses/domain/entities/account.dart';

class BudgetDetailsPage extends StatefulWidget {
  final String budgetId;

  const BudgetDetailsPage({super.key, required this.budgetId});

  @override
  State<BudgetDetailsPage> createState() => _BudgetDetailsPageState();
}

class _BudgetDetailsPageState extends State<BudgetDetailsPage> {
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<CustomBudgetCubit, CustomBudgetState>(
      builder: (context, state) {
        if (state is CustomBudgetLoaded) {
          final budgetIndex = state.budgets.indexWhere((b) => b.id == widget.budgetId);
          if (budgetIndex == -1) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(title: const Text('Budget Not Found')),
              body: const Center(child: Text('This budget no longer exists.')),
            );
          }

          final budget = state.budgets[budgetIndex];
          
          final txState = context.watch<TransactionCubit>().state;
          final transactions = txState is TransactionLoaded ? txState.transactions : <TransactionEntity>[];
          final dynamicTotalSpent = budget.calculateDynamicTotalSpent(transactions);

          final spentProgress = budget.totalAllocated > 0 
              ? (dynamicTotalSpent / budget.totalAllocated).clamp(0.0, 1.0) 
              : 0.0;
          final isTotalOverBudget = budget.totalAllocated > 0 && dynamicTotalSpent > budget.totalAllocated;

          // 1. Fixed Expenses Total
          final fixedTotal = budget.items.where((i) => i.isMonthlyFixed).fold(0.0, (sum, i) => sum + i.allocatedAmount);

          // 2. Bucket Account Balance
          final settings = context.watch<SettingsCubit>().state;
          final accState = context.watch<AccountCubit>().state;
          final accounts = accState is AccountLoaded ? accState.accounts : <AccountEntity>[];

          String bucketKey = 'blow';
          switch (budget.bucketType) {
            case BucketType.dailyExpenses: bucketKey = 'blow'; break;
            case BucketType.smile: bucketKey = 'smile'; break;
            case BucketType.fire: bucketKey = 'fire'; break;
            case BucketType.mojo: bucketKey = 'mojo'; break;
            case BucketType.grow: bucketKey = 'grow'; break;
            default: break;
          }

          final linkedAccountId = settings.bucketAccountLinks[bucketKey];
          double linkedAccountBalance = 0.0;
          if (linkedAccountId != null) {
            try {
              final acc = accounts.firstWhere((a) => a.id == linkedAccountId);
              linkedAccountBalance = acc.balance;
            } catch (_) {}
          }

            return Scaffold(
              backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(budget.title),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                if (budget.isCompleted)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: Chip(
                        label: Text('Completed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        backgroundColor: Colors.green,
                        labelStyle: TextStyle(color: Colors.white),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.black87),
                    tooltip: 'Edit Budget',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateCustomBudgetPage(existingBudget: budget),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.black87),
                    tooltip: 'Mark as Completed',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Mark as Completed?'),
                          content: const Text('Are you sure you want to mark this budget as completed? It will be moved to History.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Complete', style: TextStyle(color: Colors.green))),
                          ],
                        ),
                      );
                      
                      if (confirm == true) {
                        if (context.mounted) {
                          context.read<CustomBudgetCubit>().markBudgetAsCompleted(widget.budgetId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Budget marked as completed!')),
                          );
                          Navigator.pop(context);
                        }
                      }
                    },
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.black87),
                  tooltip: 'Delete Budget',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Budget?'),
                        content: const Text('Are you sure you want to delete this budget?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      if (context.mounted) {
                        context.read<CustomBudgetCubit>().deleteBudget(widget.budgetId);
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.black87),
                  tooltip: 'Share Budget',
                  onPressed: () async {
                    try {
                      final Uint8List? imageBytes = await _screenshotController.capture(
                        pixelRatio: 2.0,
                        delay: const Duration(milliseconds: 100),
                      );
                      if (imageBytes != null) {
                        final xFile = XFile.fromData(
                          imageBytes, 
                          mimeType: 'image/png', 
                          name: '${budget.title.replaceAll(' ', '_')}_budget.png'
                        );
                        await Share.shareXFiles(
                          [xFile],
                          text: 'Check out my budget: ${budget.title}',
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to share budget.')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            body: Screenshot(
              controller: _screenshotController,
              child: ColoredBox(
                color: theme.scaffoldBackgroundColor,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Budget Overview', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            Builder(
                              builder: (context) {
                                IconData icon = Icons.circle;
                                Color color = const Color(0xFF38B2AC);
                                String bucketName = 'Blow';
                                switch (budget.bucketType) {
                                  case BucketType.dailyExpenses: bucketName = 'Blow'; icon = Icons.work_outline; color = const Color(0xFF38B2AC); break;
                                  case BucketType.smile: bucketName = 'Smile'; icon = Icons.flight_takeoff; color = const Color(0xFF34D399); break;
                                  case BucketType.fire: bucketName = 'Fire'; icon = Icons.local_fire_department; color = const Color(0xFFF87171); break;
                                  case BucketType.mojo: bucketName = 'Mojo'; icon = Icons.security; color = const Color(0xFFEAB308); break;
                                  case BucketType.grow: bucketName = 'Grow'; icon = Icons.eco; color = const Color(0xFF60A5FA); break;
                                  default: break;
                                }
                                if (budget.bucketType == BucketType.none) return const SizedBox.shrink();

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: color.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(icon, color: color, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        bucketName,
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        _buildRow('Total Budget', AppFormatters.formatCurrency(context, budget.totalAllocated)),
                        _buildRow('Total Spent', AppFormatters.formatCurrency(context, dynamicTotalSpent)),
                        _buildRow(
                          'Remaining', 
                          AppFormatters.formatCurrency(context, budget.totalAllocated - dynamicTotalSpent), 
                          isBold: true,
                          color: isTotalOverBudget ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                        
                        if (fixedTotal > 0 || linkedAccountId != null) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          if (fixedTotal > 0)
                            _buildRow('Fixed Bills', AppFormatters.formatCurrency(context, fixedTotal)),
                          if (linkedAccountId != null)
                            Builder(
                              builder: (context) {
                                String bucketName = 'Blow';
                                switch (budget.bucketType) {
                                  case BucketType.dailyExpenses: bucketName = 'Blow'; break;
                                  case BucketType.smile: bucketName = 'Smile'; break;
                                  case BucketType.fire: bucketName = 'Fire'; break;
                                  case BucketType.mojo: bucketName = 'Mojo'; break;
                                  case BucketType.grow: bucketName = 'Grow'; break;
                                  default: break;
                                }
                                return _buildRow('$bucketName Account Balance', AppFormatters.formatCurrency(context, linkedAccountBalance));
                              }
                            ),
                        ],

                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: spentProgress,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          color: isTotalOverBudget ? Colors.red.shade700 : theme.colorScheme.primary,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Text('Checklist', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: budget.items.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      final item = budget.items[index];
                      final itemSpent = budget.calculateItemSpent(item, transactions);
                      final isOverBudget = item.allocatedAmount > 0 && itemSpent > item.allocatedAmount;
                      final isCompleted = (item.allocatedAmount > 0 && itemSpent >= item.allocatedAmount) || item.isCompleted;

                      return Container(
                        decoration: BoxDecoration(
                          color: isOverBudget 
                              ? Colors.cyan.shade700.withValues(alpha: 0.1)
                              : isCompleted 
                                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isOverBudget
                                ? Colors.cyan.shade700.withValues(alpha: 0.5)
                                : isCompleted 
                                    ? theme.colorScheme.primary.withValues(alpha: 0.5) 
                                    : Colors.transparent,
                          )
                        ),
                        child: ListTile(
                          title: Row(
                            children: [
                              if (item.categoryIcon != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: CategoryIcon(iconStr: item.categoryIcon!, size: 18, color: Colors.black),
                                ),
                              Expanded(
                                child: Text(
                                  item.subcategory != null 
                                      ? '${item.title} (${item.subcategory})' 
                                      : item.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    decoration: isCompleted && !isOverBudget ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Spent: ${AppFormatters.formatCurrency(context, itemSpent)} / ${AppFormatters.formatCurrency(context, item.allocatedAmount)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isOverBudget ? Colors.cyan.shade700 : null,
                                  fontWeight: isOverBudget ? FontWeight.bold : null,
                                ),
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: item.allocatedAmount > 0 ? (itemSpent / item.allocatedAmount).clamp(0.0, 1.0) : 0,
                                backgroundColor: Colors.black12,
                                color: isOverBudget ? Colors.cyan.shade700 : theme.colorScheme.primary,
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(2),
                              )
                            ],
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('Error')),
          body: const ShimmerTile(),
        );
      },
    );
  }

  Widget _buildRow(String title, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade700)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color ?? (isBold ? Colors.black87 : Colors.grey.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
