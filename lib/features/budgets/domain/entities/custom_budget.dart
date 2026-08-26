import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/expenses/domain/entities/transaction.dart';
import '../../../../features/expenses/domain/entities/category.dart';

class BudgetChecklistItem extends Equatable {
  final String id;
  final String title;
  final double allocatedAmount;
  final bool isCompleted;
  final String? categoryId;
  final String? categoryIcon;
  final String? subcategory;
  final bool isMonthlyFixed;

  const BudgetChecklistItem({
    required this.id,
    required this.title,
    required this.allocatedAmount,
    this.isCompleted = false,
    this.categoryId,
    this.categoryIcon,
    this.subcategory,
    this.isMonthlyFixed = false,
  });

  BudgetChecklistItem copyWith({
    String? id,
    String? title,
    double? allocatedAmount,
    bool? isCompleted,
    String? categoryId,
    String? categoryIcon,
    String? subcategory,
    bool? isMonthlyFixed,
  }) {
    return BudgetChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      isCompleted: isCompleted ?? this.isCompleted,
      categoryId: categoryId ?? this.categoryId,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      subcategory: subcategory ?? this.subcategory,
      isMonthlyFixed: isMonthlyFixed ?? this.isMonthlyFixed,
    );
  }

  @override
  List<Object?> get props => [id, title, allocatedAmount, isCompleted, categoryId, categoryIcon, subcategory, isMonthlyFixed];
}

class CustomBudgetEntity extends Equatable {
  final String id;
  final String userId;
  final String title;
  final double totalBudgetLimit;
  final List<BudgetChecklistItem> items;
  final DateTime createdAt;
  final bool isCompleted;
  final BucketType bucketType;
  final bool isRecurring;

  const CustomBudgetEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.totalBudgetLimit,
    required this.items,
    required this.createdAt,
    this.isCompleted = false,
    this.bucketType = BucketType.dailyExpenses,
    this.isRecurring = false,
  });

  CustomBudgetEntity copyWith({
    String? id,
    String? userId,
    String? title,
    double? totalBudgetLimit,
    List<BudgetChecklistItem>? items,
    DateTime? createdAt,
    bool? isCompleted,
    BucketType? bucketType,
    bool? isRecurring,
  }) {
    return CustomBudgetEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      totalBudgetLimit: totalBudgetLimit ?? this.totalBudgetLimit,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      bucketType: bucketType ?? this.bucketType,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }

  double calculateItemSpent(BudgetChecklistItem item, List<TransactionEntity> transactions) {
    if (item.categoryId == null) return item.isCompleted ? item.allocatedAmount : 0.0;
    
    // Filter transactions to the same month as this budget
    final monthTxs = transactions.where((tx) {
      return tx.date.year == createdAt.year && tx.date.month == createdAt.month;
    });

    // Sum transactions that match the item's category (and aren't income)
    final spent = monthTxs
        .where((tx) {
          if (tx.isIncome) return false;
          if (tx.categoryId != item.categoryId) return false;
          
          // If the transaction was explicitly logged under a different bucket, don't count it!
          if (tx.bucketType != null && tx.bucketType != this.bucketType) return false;
          
          return true;
        })
        .fold(0.0, (sum, tx) => sum + tx.amount);
        
    return spent > 0 ? spent : (item.isCompleted ? item.allocatedAmount : 0.0);
  }

  double calculateDynamicTotalSpent(List<TransactionEntity> transactions) {
    return items.fold(0.0, (sum, item) => sum + calculateItemSpent(item, transactions));
  }

  double get totalAllocated {
    return items.fold(0.0, (sum, item) => sum + item.allocatedAmount);
  }

  double get totalSpent {
    return items.where((i) => i.isCompleted).fold(0.0, (sum, item) => sum + item.allocatedAmount);
  }

  @override
  List<Object?> get props => [id, userId, title, totalBudgetLimit, items, createdAt, isCompleted, bucketType, isRecurring];
}
