import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/formatters.dart';
import '../bloc/custom_budget_cubit.dart';
import '../bloc/custom_budget_state.dart';
import 'create_custom_budget_page.dart';
import 'create_custom_budget_page.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/shimmer_tile.dart';
import '../../../../features/expenses/domain/entities/category.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/category_icon.dart';

class BudgetDetailsPage extends StatelessWidget {
  final String budgetId;

  const BudgetDetailsPage({super.key, required this.budgetId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<CustomBudgetCubit, CustomBudgetState>(
      builder: (context, state) {
        if (state is CustomBudgetLoaded) {
          final budgetIndex = state.budgets.indexWhere((b) => b.id == budgetId);
          if (budgetIndex == -1) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(title: const Text('Budget Not Found')),
              body: const Center(child: Text('This budget no longer exists.')),
            );
          }

          final budget = state.budgets[budgetIndex];

          final spentProgress = budget.totalAllocated > 0 
              ? (budget.totalSpent / budget.totalAllocated).clamp(0.0, 1.0) 
              : 0.0;

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
                          context.read<CustomBudgetCubit>().markBudgetAsCompleted(budgetId);
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
                        context.read<CustomBudgetCubit>().deleteBudget(budgetId);
                        Navigator.pop(context);
                      }
                    }
                  },
                )
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bucket Tag
                  Builder(
                    builder: (context) {
                      IconData icon = Icons.circle;
                      Color color = Colors.white;
                      String bucketName = 'Blow';
                      switch (budget.bucketType) {
                        case BucketType.dailyExpenses: bucketName = 'Blow'; icon = Icons.work_outline; color = Colors.white; break;
                        case BucketType.smile: bucketName = 'Smile'; icon = Icons.flight_takeoff; color = const Color(0xFF34D399); break;
                        case BucketType.fire: bucketName = 'Fire'; icon = Icons.local_fire_department; color = const Color(0xFFF87171); break;
                        case BucketType.mojo: bucketName = 'Mojo'; icon = Icons.security; color = const Color(0xFFEAB308); break;
                        case BucketType.grow: bucketName = 'Grow'; icon = Icons.eco; color = const Color(0xFF60A5FA); break;
                        default: break;
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: color, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              bucketName,
                              style: TextStyle(
                                color: color,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                  
                  // Overview Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text('Checklist Completion', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Spent: ${AppFormatters.formatCurrency(context, budget.totalSpent)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: spentProgress,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          color: Colors.green,
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
                      return Container(
                        decoration: BoxDecoration(
                          color: item.isCompleted 
                              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item.isCompleted 
                                ? theme.colorScheme.primary.withOpacity(0.5) 
                                : Colors.transparent,
                          )
                        ),
                        child: CheckboxListTile(
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
                                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(AppFormatters.formatCurrency(context, item.allocatedAmount)),
                          value: item.isCompleted,
                          onChanged: (val) {
                            if (val != null) {
                              context.read<CustomBudgetCubit>().toggleChecklistItem(budgetId, item.id, val);
                            }
                          },
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                    },
                  ),
                ],
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
}
