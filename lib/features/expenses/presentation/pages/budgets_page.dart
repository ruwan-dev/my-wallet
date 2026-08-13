import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/budget_cubit.dart';
import '../bloc/budget_state.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/set_budget_bottom_sheet.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/shimmer_tile.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const SetBudgetBottomSheet(),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<BudgetCubit, BudgetState>(
        builder: (context, state) {
          if (state is BudgetLoading) {
            return const ShimmerTile();
          }
          if (state is BudgetLoaded) {
            if (state.summaries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 64, color: theme.colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      'No Budgets Set',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to set a budget for this month.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            // Sort budgets by progress percentage (highest first)
            final sortedSummaries = List.of(state.summaries)
              ..sort((a, b) => b.progressPercentage.compareTo(a.progressPercentage));

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: sortedSummaries.length,
              itemBuilder: (context, index) {
                return BudgetProgressCard(
                  summary: sortedSummaries[index],
                );
              },
            );
          }
          if (state is BudgetError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
