import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/utils/formatters.dart';
import '../../../expenses/presentation/bloc/transaction_cubit.dart';
import '../../../expenses/presentation/bloc/transaction_state.dart';
import '../../../expenses/presentation/bloc/category_cubit.dart';
import '../../../expenses/presentation/bloc/category_state.dart';
import '../../../expenses/domain/entities/transaction.dart';
import '../../../expenses/domain/entities/category.dart';
import '../../../expenses/presentation/widgets/transaction_card.dart';
import '../../../expenses/presentation/widgets/recurring_timeline_widget.dart';

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
      body: BlocBuilder<CategoryCubit, CategoryState>(
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

                final currentMonthTxs = _getCurrentMonthTransactions(transactions);
                final categoryTotals = _getCategoryTotals(currentMonthTxs);
                final topExpenses = _getTopExpenses(currentMonthTxs);
                
                final sixMonthSummaries = _getLast6MonthsSummary(transactions);
                final momDifference = _getMoMDifference(sixMonthSummaries);
                final savingsRate = _getSavingsRate(sixMonthSummaries.last);
                
                final totalIncome = currentMonthTxs.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
                final totalExpense = currentMonthTxs.where((t) => !t.isIncome).fold(0.0, (sum, t) => sum + t.amount);

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
                            Text('Income vs Expense', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 16),
                            _buildIncomeExpenseDonutChart(context, totalIncome, totalExpense),
                            const SizedBox(height: 32),
                            
                            Text('Expenses by Category', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 16),
                            _buildCategoryPieChart(context, categoryTotals),
                            const SizedBox(height: 32),
                            
                            Text('Recurring Bills Timeline', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 16),
                            _buildRecurringTimeline(context, categories, currentMonthTxs),
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
          );
        },
      ),
    );
  }

  // --- Logic Helpers ---

  List<TransactionEntity> _getCurrentMonthTransactions(List<TransactionEntity> all) {
    final now = DateTime.now();
    return all.where((t) => t.date.year == now.year && t.date.month == now.month).toList();
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
    final lastMonth = summaries[summaries.length - 2].expense;
    final thisMonth = summaries.last.expense;
    
    if (lastMonth == 0) return 0.0;
    return ((thisMonth - lastMonth) / lastMonth) * 100;
  }

  double _getSavingsRate(MonthlySummary currentMonth) {
    if (currentMonth.income <= 0) return 0.0;
    final savings = currentMonth.income - currentMonth.expense;
    if (savings <= 0) return 0.0;
    return (savings / currentMonth.income) * 100;
  }

  // --- UI Builders ---

  Widget _buildIncomeExpenseDonutChart(BuildContext context, double totalIncome, double totalExpense) {
    if (totalIncome == 0 && totalExpense == 0) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Text('No data for this month.', style: TextStyle(color: Color(0xFF94A3B8))),
      );
    }

    final total = totalIncome + totalExpense;
    final incomePercentage = (totalIncome / total) * 100;
    final expensePercentage = (totalExpense / total) * 100;

    return Container(
      height: 250,
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 3D Depth Layer
                Transform.translate(
                  offset: const Offset(0, 10),
                  child: Transform(
                    transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(1.0),
                    alignment: Alignment.center,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(color: const Color(0xFF047857), value: totalIncome, title: '', radius: 50),
                          PieChartSectionData(color: const Color(0xFFBE123C), value: totalExpense, title: '', radius: 50),
                        ],
                      ),
                    ),
                  ),
                ),
                // Top Layer
                Transform(
                  transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(1.0),
                  alignment: Alignment.center,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: const Color(0xFF10B981), // Emerald
                          value: totalIncome,
                          title: incomePercentage > 5 ? '${incomePercentage.toStringAsFixed(0)}%' : '',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: const Color(0xFFF43F5E), // Coral
                          value: totalExpense,
                          title: expensePercentage > 5 ? '${expensePercentage.toStringAsFixed(0)}%' : '',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem('Income', const Color(0xFF10B981), totalIncome),
                const SizedBox(height: 16),
                _buildLegendItem('Expense', const Color(0xFFF43F5E), totalExpense),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color, double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          AppFormatters.formatCurrency(amount),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Color _darken(Color color, [double amount = 0.2]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
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
    final topSections = <PieChartSectionData>[];
    final bottomSections = <PieChartSectionData>[];
    
    for (final e in categoryTotals.entries) {
      final percentage = (e.value / totalExpense) * 100;
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      
      topSections.add(PieChartSectionData(
        color: color,
        value: e.value,
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));
      
      bottomSections.add(PieChartSectionData(
        color: _darken(color),
        value: e.value,
        title: '',
        radius: 50,
      ));
    }

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
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 3D Depth Layer
                Transform.translate(
                  offset: const Offset(0, 10),
                  child: Transform(
                    transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(1.0),
                    alignment: Alignment.center,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: bottomSections,
                      ),
                    ),
                  ),
                ),
                // Top Layer
                Transform(
                  transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(1.0),
                  alignment: Alignment.center,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: topSections,
                    ),
                  ),
                ),
              ],
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

  DateTime _getNextDate(DateTime current, String? frequency) {
    if (frequency == 'Daily') return current.add(const Duration(days: 1));
    if (frequency == 'Weekly') return current.add(const Duration(days: 7));
    if (frequency == 'Monthly') return DateTime(current.year, current.month + 1, current.day);
    if (frequency == 'Yearly') return DateTime(current.year + 1, current.month, current.day);
    return DateTime(current.year, current.month + 1, current.day);
  }

  Widget _buildRecurringTimeline(BuildContext context, List<Category> categories, List<TransactionEntity> currentMonthTxs) {
    final scheduleCards = <Widget>[];

    for (final cat in categories) {
      if (cat.recurringConfigs.isNotEmpty) {
        cat.recurringConfigs.forEach((subCat, config) {
          final dueDateStr = config['dueDate'];
          final frequency = config['frequency'] as String?;
          final expectedAmount = (config['amount'] ?? 0.0) as double;
          
          if (dueDateStr != null) {
            DateTime currentExpected = DateTime.parse(dueDateStr);
            final actualTxs = currentMonthTxs.where((t) => t.categoryId == cat.id && t.subCategory == subCat).toList();
            actualTxs.sort((a, b) => a.date.compareTo(b.date));
            
            final occurrences = <Map<String, dynamic>>[];
            
            for (var tx in actualTxs) {
               occurrences.add({
                 'expectedDate': currentExpected,
                 'actualTx': tx,
               });
               currentExpected = _getNextDate(currentExpected, frequency);
            }
            
            // Always show the next unpaid expected date
            occurrences.add({
               'expectedDate': currentExpected,
               'actualTx': null,
            });
            
            scheduleCards.add(_buildScheduleCard(context, cat, subCat, frequency, expectedAmount, occurrences));
          }
        });
      }
    }

    if (scheduleCards.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withValues(alpha: 255 * 0.1)),
        ),
        child: const Text('No recurring schedules found. Add them in the Categories tab.', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: scheduleCards,
    );
  }

  Widget _buildScheduleCard(
      BuildContext context, 
      Category cat, 
      String subCat, 
      String? frequency, 
      double expectedAmount, 
      List<Map<String, dynamic>> occurrences) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: cat.color.withValues(alpha: 255 * 0.1),
            child: Text(cat.icon, style: const TextStyle(fontSize: 20)),
          ),
          title: Text('$subCat (${cat.name})', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${frequency ?? 'One-time'} • ${AppFormatters.formatCurrency(expectedAmount)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          children: [
            const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: RecurringTimelineWidget(
                events: occurrences.map((occ) {
                  final expectedDate = occ['expectedDate'] as DateTime;
                  final actualTx = occ['actualTx'] as TransactionEntity?;
                  final now = DateTime.now();
                  
                  bool isPaid = actualTx != null;
                  bool isLate = false;
                  bool isEarly = false;
                  int daysDiff = 0;
                  
                  if (isPaid) {
                    final expectedDateOnly = DateTime(expectedDate.year, expectedDate.month, expectedDate.day);
                    final actualDateOnly = DateTime(actualTx.date.year, actualTx.date.month, actualTx.date.day);
                    daysDiff = actualDateOnly.difference(expectedDateOnly).inDays;
                    if (daysDiff > 0) isLate = true;
                    if (daysDiff < 0) isEarly = true;
                  }
                  
                  final statusColor = isPaid
                      ? (isLate ? Colors.orange : Colors.green)
                      : (expectedDate.isBefore(now) ? Colors.red : Colors.grey);
                      
                  String statusText;
                  if (isPaid) {
                    if (isLate) statusText = '${daysDiff.abs()}d late';
                    else if (isEarly) statusText = '${daysDiff.abs()}d early';
                    else statusText = 'On time';
                  } else {
                    statusText = expectedDate.isBefore(now) ? 'Overdue' : 'Pending';
                  }

                  return RecurringBranchEvent(
                    expectedDate: expectedDate,
                    actualDate: actualTx?.date,
                    amount: expectedAmount,
                    isPaid: isPaid,
                    statusText: statusText,
                    statusColor: statusColor,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
