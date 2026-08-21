import 'dart:ui';
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
import 'budget_details_page.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/shimmer_tile.dart';
import 'package:expense_tracker/core/widgets/glass_list_tile.dart';
import '../../../../features/expenses/domain/entities/category.dart';

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
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF26C6DA), size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateCustomBudgetPage(),
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.label,
            indicatorColor: const Color(0xFF6D28D9), // Deep Purple
            labelColor: const Color(0xFF6D28D9), // Deep Purple
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
              return const ShimmerTile();
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateCustomBudgetPage(),
              ),
            );
          },
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add),
          label: const Text('Create Budget'),
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

        return GlassListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BudgetDetailsPage(budgetId: budget.id),
              ),
            );
          },
          tileColor: Colors.white.withOpacity(isHistory ? 0.05 : 0.15),
          contentPadding: const EdgeInsets.all(20),
          title: Opacity(
            opacity: isHistory ? 0.6 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: color.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(icon, color: Colors.black, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      bucketName,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              budget.title,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                decoration: null,
                              ).copyWith(
                                decoration: isHistory ? TextDecoration.lineThrough : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppFormatters.formatCurrency(context, budget.totalBudgetLimit),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final txState = context.watch<TransactionCubit>().state;
                    final transactions = txState is TransactionLoaded ? txState.transactions : <TransactionEntity>[];
                    
                    int completedCount = 0;
                    for (final item in budget.items) {
                      final spent = budget.calculateItemSpent(item, transactions);
                      if ((item.allocatedAmount > 0 && spent >= item.allocatedAmount) || item.isCompleted) {
                        completedCount++;
                      }
                    }
                    
                    return Text(
                      '$completedCount / ${budget.items.length} completed',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
            ElevatedButton.icon(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                elevation: 2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
