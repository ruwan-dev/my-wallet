import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../expenses/presentation/bloc/transaction_cubit.dart';
import '../../../expenses/presentation/bloc/transaction_state.dart';
import '../../../expenses/domain/entities/transaction.dart';
import '../../../expenses/presentation/widgets/transaction_card.dart';

class MonthlySummary {
  final DateTime date;
  final double income;
  final double expense;
  MonthlySummary(this.date, this.income, this.expense);
}

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
            final topExpenses = _getTopExpenses(currentMonthTxs);
            
            final sixMonthSummaries = _getLast6MonthsSummary(transactions);
            final momDifference = _getMoMDifference(sixMonthSummaries);
            final savingsRate = _getSavingsRate(sixMonthSummaries.last);

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  pinned: true,
                  backgroundColor: theme.colorScheme.surface,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    title: Text(
                      'Financial Insights',
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
                        _buildFinancialHealthRow(context, momDifference, savingsRate),
                        const SizedBox(height: 32),
                        
                        Text('6-Month Trend', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 16),
                        _buildTrendLineChart(context, sixMonthSummaries),
                        const SizedBox(height: 32),
                        
                        Text('Expenses by Category', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 16),
                        _buildCategoryPieChart(context, categoryTotals),
                        const SizedBox(height: 32),
                        
                        if (topExpenses.isNotEmpty) ...[
                          Text('Top Spendings (This Month)', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 16),
                          ...topExpenses.map((tx) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: TransactionCard(
                              transaction: tx,
                              accountName: tx.categoryName, 
                              onDelete: null, 
                            ),
                          )),
                          const SizedBox(height: 100), 
                        ],
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

  // --- Logic Helpers ---

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

  List<TransactionEntity> _getTopExpenses(List<TransactionEntity> currentMonthTxs) {
    final expenses = currentMonthTxs.where((t) => !t.isIncome).toList();
    expenses.sort((a, b) => b.amount.compareTo(a.amount));
    return expenses.take(3).toList();
  }

  List<MonthlySummary> _getLast6MonthsSummary(List<TransactionEntity> all) {
    final now = DateTime.now();
    final List<MonthlySummary> summaries = [];

    for (int i = 5; i >= 0; i--) {
      int month = now.month - i;
      int year = now.year;
      if (month <= 0) {
        month += 12;
        year -= 1;
      }
      
      final txsForMonth = all.where((t) => t.date.year == year && t.date.month == month);
      final income = txsForMonth.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
      final expense = txsForMonth.where((t) => !t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
      
      summaries.add(MonthlySummary(DateTime(year, month), income, expense));
    }
    return summaries;
  }

  double _getMoMDifference(List<MonthlySummary> summaries) {
    if (summaries.length < 2) return 0.0;
    final currentMonth = summaries.last;
    final lastMonth = summaries[summaries.length - 2];
    
    if (lastMonth.expense == 0) {
        if (currentMonth.expense == 0) return 0.0;
        return 100.0; 
    }
    return ((currentMonth.expense - lastMonth.expense) / lastMonth.expense) * 100;
  }

  double _getSavingsRate(MonthlySummary currentMonth) {
    if (currentMonth.income == 0) return 0.0;
    final savings = currentMonth.income - currentMonth.expense;
    if (savings <= 0) return 0.0;
    return (savings / currentMonth.income) * 100;
  }

  // --- UI Builders ---

  Widget _buildFinancialHealthRow(BuildContext context, double momDiff, double savingsRate) {
    final isMoMIncrease = momDiff > 0;
    
    return Row(
      children: [
        Expanded(
          child: _buildInsightCard(
            title: 'Vs Last Month',
            content: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  isMoMIncrease ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  color: isMoMIncrease ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${momDiff.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isMoMIncrease ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInsightCard(
            title: 'Savings Rate',
            content: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: savingsRate / 100,
                    strokeWidth: 4,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0891B2)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${savingsRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard({required String title, required Widget content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // 4% opacity black
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildTrendLineChart(BuildContext context, List<MonthlySummary> summaries) {
    if (summaries.isEmpty) return const SizedBox();

    double maxY = 0;
    for (var s in summaries) {
      if (s.income > maxY) maxY = s.income;
      if (s.expense > maxY) maxY = s.expense;
    }
    maxY = maxY == 0 ? 100.0 : maxY * 1.2;

    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    for (int i = 0; i < summaries.length; i++) {
      incomeSpots.add(FlSpot(i.toDouble(), summaries[i].income));
      expenseSpots.add(FlSpot(i.toDouble(), summaries[i].expense));
    }

    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), 
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < summaries.length) {
                    final date = summaries[value.toInt()].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        monthNames[date.month - 1],
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (summaries.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: incomeSpots,
              isCurved: true,
              color: const Color(0xFF10B981), // Soft Emerald
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0x1A10B981), // 10% Opacity Emerald
              ),
            ),
            LineChartBarData(
              spots: expenseSpots,
              isCurved: true,
              color: const Color(0xFFF43F5E), // Soft Coral
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0x1AF43F5E), // 10% Opacity Coral
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart(BuildContext context, Map<String, double> categoryTotals) {
    if (categoryTotals.isEmpty) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Text('No expenses this month.', style: TextStyle(color: Color(0xFF94A3B8))),
      );
    }

    final totalExpense = categoryTotals.values.fold(0.0, (a, b) => a + b);
    
    // Premium soft colors
    final colors = [
      const Color(0xFF38BDF8),
      const Color(0xFFFB7185),
      const Color(0xFFFBBF24),
      const Color(0xFFA78BFA),
      const Color(0xFF34D399),
      const Color(0xFF818CF8),
    ];
    
    int colorIndex = 0;
    final sections = categoryTotals.entries.map((e) {
      final percentage = (e.value / totalExpense) * 100;
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      
      return PieChartSectionData(
        color: color,
        value: e.value,
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 15,
            offset: Offset(0, 5),
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
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categoryTotals.length,
              itemBuilder: (context, index) {
                final entry = categoryTotals.entries.elementAt(index);
                final color = colors[index % colors.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
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
