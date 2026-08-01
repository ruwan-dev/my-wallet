import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/formatters.dart';
import '../bloc/custom_budget_cubit.dart';
import '../bloc/custom_budget_state.dart';
import 'create_custom_budget_page.dart';

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
              appBar: AppBar(title: const Text('Budget Not Found')),
              body: const Center(child: Text('This budget no longer exists.')),
            );
          }

          final budget = state.budgets[budgetIndex];
          final progress = budget.totalBudgetLimit > 0 
              ? (budget.totalAllocated / budget.totalBudgetLimit).clamp(0.0, 1.0) 
              : 0.0;
          final spentProgress = budget.totalAllocated > 0 
              ? (budget.totalSpent / budget.totalAllocated).clamp(0.0, 1.0) 
              : 0.0;

          return Scaffold(
            backgroundColor: theme.colorScheme.surface,
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
                    icon: const Icon(Icons.edit_outlined),
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
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
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
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                        Text('Budget Allocation', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Allocated: ${AppFormatters.formatCurrency(budget.totalAllocated)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              'Limit: ${AppFormatters.formatCurrency(budget.totalBudgetLimit)}',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        
                        const SizedBox(height: 24),
                        Text('Checklist Completion', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Spent: ${AppFormatters.formatCurrency(budget.totalSpent)}',
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
                                  child: Text(item.categoryIcon!, style: const TextStyle(fontSize: 18)),
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
                          subtitle: Text(AppFormatters.formatCurrency(item.allocatedAmount)),
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
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
