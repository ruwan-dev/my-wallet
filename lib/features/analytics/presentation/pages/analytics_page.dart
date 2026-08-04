import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/formatters.dart';
import '../../../expenses/presentation/bloc/transaction_cubit.dart';
import '../../../expenses/presentation/bloc/transaction_state.dart';
import '../../../expenses/presentation/bloc/category_cubit.dart';
import '../../../expenses/presentation/bloc/category_state.dart';
import '../../../expenses/domain/entities/transaction.dart';
import '../../../expenses/domain/entities/category.dart';
import '../../../expenses/presentation/widgets/transaction_card.dart';

class MonthlySummary {
  final DateTime date;
  final double income;
  final double expense;
  MonthlySummary(this.date, this.income, this.expense);
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  DateTime _selectedDate = DateTime.now();
  final Set<String> _hiddenCategoryIds = {};

  void _changeMonth(int offset) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + offset);
    });
  }

  void _toggleCategory(String categoryName) {
    setState(() {
      if (_hiddenCategoryIds.contains(categoryName)) {
        _hiddenCategoryIds.remove(categoryName);
      } else {
        _hiddenCategoryIds.add(categoryName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: BlocBuilder<CategoryCubit, CategoryState>(
        builder: (context, catState) {
          if (catState is! CategoryLoaded) return const Center(child: CircularProgressIndicator());
          final categories = catState.categories;

          return BlocBuilder<TransactionCubit, TransactionState>(
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

                final currentMonthTxs = _getSelectedMonthTransactions(transactions);
                final categoryTotals = _getCategoryTotals(currentMonthTxs);
                
                final visibleTxs = currentMonthTxs.where((t) => !_hiddenCategoryIds.contains(t.categoryName)).toList();
                final topExpenses = _getTopExpenses(visibleTxs);
                
                final sixMonthSummaries = _getLast6MonthsSummary(transactions, _selectedDate);
                final historicalSixMonths = _getLast6MonthsSummary(transactions, DateTime.now());
                
                final double currentMonthExpense = sixMonthSummaries.isNotEmpty ? sixMonthSummaries.last.expense : 0.0;
                final double previousMonthExpense = sixMonthSummaries.length > 1 ? sixMonthSummaries[sixMonthSummaries.length - 2].expense : 0.0;
                
                final totalIncome = visibleTxs.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
                final totalExpense = visibleTxs.where((t) => !t.isIncome).fold(0.0, (sum, t) => sum + t.amount);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 24, top: 24, right: 24, bottom: 8),
                      child: Text(
                        'Financial Insights',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CashFlowMacroCard(summaries: historicalSixMonths),
                              const SizedBox(height: 32),
                              MonthlyCategoryView(
                                selectedDate: _selectedDate,
                                onChangeMonth: _changeMonth,
                                categoryTotals: categoryTotals,
                                hiddenCategoryIds: _hiddenCategoryIds,
                                onToggleCategory: _toggleCategory,
                              ),
                              const SizedBox(height: 32),
                              SpendingHeatmapCard(
                                selectedMonth: _selectedDate,
                                transactions: visibleTxs,
                              ),
                              const SizedBox(height: 32),

                              SmartInsightCard(
                                currentMonthExpense: currentMonthExpense,
                                previousMonthExpense: previousMonthExpense,
                              ),
                              const SizedBox(height: 32),
                              if (topExpenses.isNotEmpty)
                                TopExpensesView(transactions: topExpenses),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
      ),
    );
  }

  // --- Logic Helpers ---

  List<TransactionEntity> _getSelectedMonthTransactions(List<TransactionEntity> all) {
    return all.where((t) => t.date.year == _selectedDate.year && t.date.month == _selectedDate.month).toList();
  }

  Map<String, double> _getCategoryTotals(List<TransactionEntity> currentMonthTxs) {
    final totals = <String, double>{};
    for (var tx in currentMonthTxs) {
      if (!tx.isIncome) {
        totals[tx.categoryName] = (totals[tx.categoryName] ?? 0) + tx.amount;
      }
    }
    return totals;
  }

  List<TransactionEntity> _getTopExpenses(List<TransactionEntity> currentMonthTxs) {
    final expenses = currentMonthTxs.where((t) => !t.isIncome).toList();
    expenses.sort((a, b) => b.amount.compareTo(a.amount));
    return expenses.take(3).toList();
  }


  List<MonthlySummary> _getLast6MonthsSummary(List<TransactionEntity> all, [DateTime? baseDate]) {
    final base = baseDate ?? DateTime.now();
    final List<MonthlySummary> summaries = [];

    for (int i = 5; i >= 0; i--) {
      int month = base.month - i;
      int year = base.year;
      while (month <= 0) {
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



  // --- UI Builders ---

}

class MonthlyCategoryView extends StatelessWidget {
  final DateTime selectedDate;
  final Function(int) onChangeMonth;
  final Map<String, double> categoryTotals;
  final Set<String> hiddenCategoryIds;
  final Function(String) onToggleCategory;

  const MonthlyCategoryView({
    super.key,
    required this.selectedDate,
    required this.onChangeMonth,
    required this.categoryTotals,
    required this.hiddenCategoryIds,
    required this.onToggleCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthName = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ][selectedDate.month];

    final filteredTotals = Map.fromEntries(
      categoryTotals.entries.where((e) => !hiddenCategoryIds.contains(e.key))
    );
    final totalExpense = filteredTotals.values.fold(0.0, (a, b) => a + b);
    
    final colors = [
      const Color(0xFF38BDF8),
      const Color(0xFFFB7185),
      const Color(0xFFFBBF24),
      const Color(0xFFA78BFA),
      const Color(0xFF34D399),
      const Color(0xFF818CF8),
    ];
    
    final sections = <PieChartSectionData>[];
    
    for (final e in filteredTotals.entries) {
      final percentage = (e.value / totalExpense) * 100;
      final color = colors[categoryTotals.keys.toList().indexOf(e.key) % colors.length];
      
      sections.add(PieChartSectionData(
        color: color,
        value: e.value,
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 40,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left_rounded, color: theme.colorScheme.onSurfaceVariant),
                onPressed: () => onChangeMonth(-1),
              ),
              Text(
                '$monthName ${selectedDate.year}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                onPressed: () => onChangeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (categoryTotals.isEmpty)
            Container(
              height: 220,
              alignment: Alignment.center,
              child: const Text('No expenses this month.', style: TextStyle(color: Color(0xFF94A3B8))),
            )
          else ...[
            if (filteredTotals.isNotEmpty)
              SizedBox(
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 60,
                        sections: sections,
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 500),
                      swapAnimationCurve: Curves.easeInOut,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Total', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        Text(
                          AppFormatters.formatCurrency(context, totalExpense),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              const SizedBox(
                height: 220,
                child: Center(child: Text('All categories hidden', style: TextStyle(color: Color(0xFF94A3B8)))),
              ),
            const SizedBox(height: 32),
            // Interactive Legend
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: categoryTotals.entries.map((e) {
                final isHidden = hiddenCategoryIds.contains(e.key);
                final color = colors[categoryTotals.keys.toList().indexOf(e.key) % colors.length];
                
                return InkWell(
                  onTap: () => onToggleCategory(e.key),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isHidden ? Colors.grey.shade50 : color.withOpacity(0.1),
                      border: Border.all(color: isHidden ? Colors.grey.shade300 : color.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 16,
                          color: isHidden ? Colors.grey : color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          e.key,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isHidden ? Colors.grey : const Color(0xFF1E293B),
                            decoration: isHidden ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppFormatters.formatCurrency(context, e.value),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isHidden ? Colors.grey : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ]
        ],
      ),
    );
  }
}

class CashFlowMacroCard extends StatelessWidget {
  final List<MonthlySummary> summaries;

  const CashFlowMacroCard({super.key, required this.summaries});

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    // Calculate average savings
    final totalSavings = summaries.fold(0.0, (sum, s) => sum + (s.income - s.expense));
    final avgSavings = totalSavings / summaries.length;
    
    double maxVal = 0;
    for (var s in summaries) {
      if (s.income > maxVal) maxVal = s.income;
      if (s.expense > maxVal) maxVal = s.expense;
    }
    maxVal = (maxVal * 1.2).ceilToDouble();
    if (maxVal == 0) maxVal = 1000;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cash Flow (Last 6 Months)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Text(
            'Avg. Monthly Savings: ${AppFormatters.formatCurrency(context, avgSavings)}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => const Color(0xFF1E293B),
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final isIncome = rodIndex == 0;
                      return BarTooltipItem(
                        '${isIncome ? 'Income' : 'Expense'}\n',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        children: [
                          TextSpan(
                            text: AppFormatters.formatCurrency(context, rod.toY),
                            style: TextStyle(
                              color: isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= summaries.length) return const SizedBox.shrink();
                        final month = monthNames[summaries[index].date.month - 1];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            month,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: summaries.asMap().entries.map((e) {
                  final index = e.key;
                  final summary = e.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: summary.income,
                        color: const Color(0xFF10B981).withOpacity(0.8), // Soft Green
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: summary.expense,
                        color: const Color(0xFFF43F5E).withOpacity(0.8), // Soft Red/Orange
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                    barsSpace: 4,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Income', const Color(0xFF10B981).withOpacity(0.8)),
              const SizedBox(width: 16),
              _buildLegendItem('Expense', const Color(0xFFF43F5E).withOpacity(0.8)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class SmartInsightCard extends StatelessWidget {
  final double currentMonthExpense;
  final double previousMonthExpense;

  const SmartInsightCard({
    super.key,
    required this.currentMonthExpense,
    required this.previousMonthExpense,
  });

  @override
  Widget build(BuildContext context) {
    if (previousMonthExpense == 0) {
       return _buildCard(context, 'Not enough data for insights yet 📊', Colors.grey.shade100, Colors.grey.shade600, Icons.insights);
    }
    
    final diff = currentMonthExpense - previousMonthExpense;
    final percent = (diff / previousMonthExpense) * 100;
    
    if (diff < 0) {
       return _buildCard(context, '💡 You spent ${percent.abs().toStringAsFixed(0)}% less this month compared to last month!', Colors.deepPurple.withOpacity(0.15), Colors.deepPurple.shade900, Icons.lightbulb_outline);
    } else if (diff > 0) {
       return _buildCard(context, '⚠️ Your expenses are ${percent.toStringAsFixed(0)}% higher than last month.', Colors.deepPurple.withOpacity(0.15), Colors.deepPurple.shade900, Icons.warning_amber_rounded);
    } else {
       return _buildCard(context, '👍 Your expenses are exactly the same as last month.', Colors.deepPurple.withOpacity(0.15), Colors.deepPurple.shade900, Icons.thumb_up_alt_outlined);
    }
  }
  
  Widget _buildCard(BuildContext context, String text, Color bgColor, Color textColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class TopExpensesView extends StatelessWidget {
  final List<TransactionEntity> transactions;

  const TopExpensesView({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Expenses', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFF43F5E), size: 20),
                ),
                title: Text(
                  tx.categoryName,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                subtitle: Text(
                  AppFormatters.formatDate(tx.date),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                trailing: Text(
                  AppFormatters.formatCurrency(context, tx.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFFF43F5E),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class SpendingHeatmapCard extends StatelessWidget {
  final DateTime selectedMonth;
  final List<TransactionEntity> transactions;

  const SpendingHeatmapCard({super.key, required this.selectedMonth, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(selectedMonth.year, selectedMonth.month, 1).weekday;
    
    final dailyExpenses = <int, double>{};
    double maxExpense = 0.0;
    
    for (final tx in transactions) {
      if (!tx.isIncome) {
        dailyExpenses[tx.date.day] = (dailyExpenses[tx.date.day] ?? 0) + tx.amount;
        if (dailyExpenses[tx.date.day]! > maxExpense) {
          maxExpense = dailyExpenses[tx.date.day]!;
        }
      }
    }

    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Heatmap',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 244,
              child: Column(
                children: [
                  // Days of week header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: weekDays.map((d) => SizedBox(
                      width: 28, 
                      child: Center(child: Text(d, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold)))
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: daysInMonth + firstWeekday - 1,
                    itemBuilder: (context, index) {
                      if (index < firstWeekday - 1) {
                        return const SizedBox.shrink();
                      }
                      final day = index - (firstWeekday - 1) + 1;
                      final expense = dailyExpenses[day] ?? 0.0;
                      final intensity = maxExpense > 0 ? (expense / maxExpense) : 0.0;
                      
                      Color cellColor;
                      if (expense == 0) {
                        cellColor = Colors.white.withOpacity(0.5);
                      } else {
                        cellColor = Color.lerp(Colors.deepPurple.shade100, Colors.deepPurple.shade900, intensity)!;
                      }

                      return Tooltip(
                        message: '$day ${AppFormatters.formatDate(DateTime(selectedMonth.year, selectedMonth.month, day)).split(' ').last}\nSpent: ${AppFormatters.formatCurrency(context, expense)}',
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                        triggerMode: TooltipTriggerMode.tap,
                        child: Container(
                          decoration: BoxDecoration(
                            color: cellColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: expense > 0 ? Colors.transparent : Colors.grey.shade200,
                            )
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Less', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              const SizedBox(width: 8),
              _buildLegendBox(Colors.white.withOpacity(0.5), true),
              const SizedBox(width: 4),
              _buildLegendBox(Colors.deepPurple.shade100, false),
              const SizedBox(width: 4),
              _buildLegendBox(Colors.deepPurple.shade300, false),
              const SizedBox(width: 4),
              _buildLegendBox(Colors.deepPurple.shade600, false),
              const SizedBox(width: 4),
              _buildLegendBox(Colors.deepPurple.shade900, false),
              const SizedBox(width: 8),
              const Text('More', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegendBox(Color color, bool hasBorder) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: hasBorder ? Border.all(color: Colors.grey.shade300) : null,
      ),
    );
  }
}
