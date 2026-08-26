import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/formatters.dart';
import '../bloc/transaction_cubit.dart';
import '../bloc/transaction_state.dart';
import '../bloc/category_cubit.dart';
import '../bloc/category_state.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/category.dart';
import '../widgets/recurring_timeline_widget.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/shimmer_tile.dart';

class RecurringBillsPage extends StatelessWidget {
  const RecurringBillsPage({super.key});

  DateTime _getNextDate(DateTime current, String? frequency) {
    if (frequency == 'Daily') return current.add(const Duration(days: 1));
    if (frequency == 'Weekly') return current.add(const Duration(days: 7));
    if (frequency == 'Monthly') return DateTime(current.year, current.month + 1, current.day);
    if (frequency == 'Yearly') return DateTime(current.year + 1, current.month, current.day);
    return DateTime(current.year, current.month + 1, current.day);
  }

  Widget _buildRecurringTimeline(BuildContext context, List<Category> categories, List<TransactionEntity> allTransactions) {
    final scheduleCards = <Widget>[];

    for (final cat in categories) {
      if (cat.recurringConfigs.isNotEmpty) {
        cat.recurringConfigs.forEach((subCat, config) {
          final dueDateStr = config['dueDate'];
          final frequency = config['frequency'] as String?;
          final expectedAmount = (config['amount'] ?? 0.0) as double;
          
            if (dueDateStr != null) {
              DateTime currentExpected = DateTime.parse(dueDateStr);
              final actualTxs = allTransactions.where((t) => t.categoryId == cat.id && t.subCategory == subCat).toList();
              actualTxs.sort((a, b) => a.date.compareTo(b.date));
            
            final occurrences = <Map<String, dynamic>>[];
            
            for (var tx in actualTxs) {
               occurrences.add({
                 'expectedDate': currentExpected,
                 'actualTx': tx,
               });
               currentExpected = _getNextDate(tx.date, frequency);
            }
            
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
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
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
          iconColor: const Color(0xFF38B2AC),
          collapsedIconColor: const Color(0xFF38B2AC),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF38B2AC).withOpacity(0.12),
            child: Builder(builder: (context) {
              final codePoint = int.tryParse(cat.icon);
              if (codePoint != null) {
                return Icon(
                    IconData(codePoint, fontFamily: 'MaterialIcons'),
                    size: 24,
                    color: const Color(0xFF38B2AC));
              }
              return Text(cat.icon, style: const TextStyle(fontSize: 20, color: Color(0xFF38B2AC)));
            }),
          ),
          title: Text('$subCat (${cat.name})', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          subtitle: Text('${frequency ?? 'One-time'} • ${AppFormatters.formatCurrency(context, expectedAmount)}', style: TextStyle(color: const Color(0xFF38B2AC).withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600)),
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
                      ? (isLate ? Colors.orange : const Color(0xFF38B2AC))
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Bills'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.transparent,
      body: BlocBuilder<CategoryCubit, CategoryState>(
        builder: (context, catState) {
          if (catState is! CategoryLoaded) return const ShimmerTile();
          final categories = catState.categories;

          return BlocBuilder<TransactionCubit, TransactionState>(
            builder: (context, txState) {
              if (txState is! TransactionLoaded) return const ShimmerTile();
              final transactions = txState.transactions;
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildRecurringTimeline(context, categories, transactions),
              );
            }
          );
        }
      ),
    );
  }
}
