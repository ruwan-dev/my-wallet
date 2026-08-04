import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/custom_budget.dart';
import '../bloc/custom_budget_cubit.dart';
import '../bloc/custom_budget_state.dart';
import 'create_custom_budget_page.dart';
import 'budget_details_page.dart';

class BudgetsMainPage extends StatelessWidget {
  const BudgetsMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('My Budgets'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.label,
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: BlocBuilder<CustomBudgetCubit, CustomBudgetState>(
          builder: (context, state) {
            if (state is CustomBudgetLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is CustomBudgetLoaded) {
              final activeBudgets = state.budgets.where((b) => !b.isCompleted).toList();
              final historyBudgets = state.budgets.where((b) => b.isCompleted).toList();

              return TabBarView(
                children: [
                  _buildBudgetList(activeBudgets, theme, context),
                  _buildBudgetList(historyBudgets, theme, context, isHistory: true),
                ],
              );
            }
            
            if (state is CustomBudgetError) {
              return Center(child: Text(state.message));
            }
            
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateCustomBudgetPage(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBudgetList(List<CustomBudgetEntity> budgets, ThemeData theme, BuildContext context, {bool isHistory = false}) {
    if (budgets.isEmpty) {
      return _buildEmptyState(theme, context, isHistory);
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: budgets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final budget = budgets[index];
        final progress = budget.totalBudgetLimit > 0 
          ? (budget.totalAllocated / budget.totalBudgetLimit).clamp(0.0, 1.0) 
          : 0.0;
        final isWarning = progress > 0.9;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BudgetDetailsPage(budgetId: budget.id),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isHistory 
                  ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.1)
                  : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isHistory 
                    ? theme.colorScheme.outlineVariant.withOpacity(0.2)
                    : theme.colorScheme.outlineVariant.withOpacity(0.5)
              ),
            ),
            child: Opacity(
              opacity: isHistory ? 0.6 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        budget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          decoration: isHistory ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      Text(
                        AppFormatters.formatCurrency(context, budget.totalBudgetLimit),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700, 
                          color: isHistory ? theme.colorScheme.onSurface : theme.colorScheme.primary
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${budget.items.where((i) => i.isCompleted).length} / ${budget.items.length} completed',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: isHistory 
                        ? Colors.grey
                        : (isWarning ? theme.colorScheme.error : theme.colorScheme.primary),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, BuildContext context, bool isHistory) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isHistory ? Icons.history : Icons.checklist_rtl_rounded, 
            size: 80, 
            color: theme.colorScheme.outline.withOpacity(0.5)
          ),
          const SizedBox(height: 24),
          Text(
            isHistory ? 'No Completed Budgets' : 'No Active Budgets',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            isHistory 
                ? 'Budgets marked as completed will appear here.'
                : 'Create a budget checklist for an upcoming\nevent, trip, or specific month.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (!isHistory) ...[
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateCustomBudgetPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Budget'),
            ),
          ],
        ],
      ),
    );
  }
}
