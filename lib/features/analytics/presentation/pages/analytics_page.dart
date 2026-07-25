import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../expenses/presentation/bloc/transaction_cubit.dart';
import '../../../expenses/presentation/bloc/transaction_state.dart';
import '../../../expenses/domain/entities/transaction.dart';
import '../../../../core/utils/formatters.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TransactionError) {
            return Center(child: Text(state.message));
          }
          if (state is TransactionLoaded) {
            final transactions = state.transactions;
            if (transactions.isEmpty) {
              return Center(
                child: Text(
                  'No data available for analytics yet.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              );
            }

            final currentMonthTxs = _getCurrentMonthTransactions(transactions);
            final categoryTotals = _getCategoryTotals(currentMonthTxs);
            final totalIncome = _getTotalIncome(currentMonthTxs);
            final totalExpense = _getTotalExpense(currentMonthTxs);

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  pinned: true,
                  backgroundColor: theme.colorScheme.surface,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    title: Text(
                      'Analytics',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Month Overview', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 16),
                        _buildIncomeExpenseBarChart(context, totalIncome, totalExpense),
                        const SizedBox(height: 32),
                        Text('Expenses by Category', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 16),
                        _buildCategoryPieChart(context, categoryTotals, totalExpense),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  List<TransactionEntity> _getCurrentMonthTransactions(List<TransactionEntity> all) {
    final now = DateTime.now();
    return all.where((t) => t.date.year == now.year && t.date.month == now.month).toList();
  }

  Map<String, double> _getCategoryTotals(List<TransactionEntity> txs) {
    final totals = <String, double>{};
    for (final tx in txs.where((t) => !t.isIncome)) {
      totals[tx.categoryName] = (totals[tx.categoryName] ?? 0) + tx.amount;
    }
    return totals;
  }

  double _getTotalIncome(List<TransactionEntity> txs) {
    return txs.where((t) => t.isIncome).fold(0, (sum, t) => sum + t.amount);
  }

  double _getTotalExpense(List<TransactionEntity> txs) {
    return txs.where((t) => !t.isIncome).fold(0, (sum, t) => sum + t.amount);
  }

  Widget _buildIncomeExpenseBarChart(BuildContext context, double income, double expense) {
    final theme = Theme.of(context);
    final maxVal = income > expense ? income : expense;
    final maxY = maxVal == 0 ? 100.0 : maxVal * 1.2; // Add 20% headroom

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final text = value == 0 ? 'Income' : 'Expense';
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(text, style: theme.textTheme.bodySmall),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: income,
                  color: const Color(0xFF4CAF50), // Teal/Green for income
                  width: 30,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: expense,
                  color: const Color(0xFFFF6584), // Red/Pink for expense
                  width: 30,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart(BuildContext context, Map<String, double> categoryTotals, double totalExpense) {
    final theme = Theme.of(context);
    
    if (categoryTotals.isEmpty) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text('No expenses this month.', style: theme.textTheme.bodyMedium),
      );
    }

    // Prepare colors
    final colors = [
      const Color(0xFF42A5F5),
      const Color(0xFFFF6584),
      const Color(0xFFFFBE0B),
      const Color(0xFF9C27B0),
      const Color(0xFF03DAC6),
      const Color(0xFF6C63FF),
    ];
    
    int colorIndex = 0;
    final sections = categoryTotals.entries.map((e) {
      final percentage = (e.value / totalExpense) * 100;
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      
      return PieChartSectionData(
        color: color,
        value: e.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: sections,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categoryTotals.length,
              itemBuilder: (context, index) {
                final entry = categoryTotals.entries.elementAt(index);
                final color = colors[index % colors.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
