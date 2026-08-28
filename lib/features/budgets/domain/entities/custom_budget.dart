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

  Map<String, double> calculateAllItemSpents(List<TransactionEntity> transactions) {
    final monthTxs = transactions.where((tx) {
      return tx.date.year == createdAt.year && tx.date.month == createdAt.month;
    }).toList();

    final Map<String, double> spents = {};
    final Set<String> allocatedTxIds = {};

    for (final item in items) {
      spents[item.id] = 0.0;
    }

    void allocate(TransactionEntity tx, BudgetChecklistItem item) {
      spents[item.id] = spents[item.id]! + tx.amount;
      allocatedTxIds.add(tx.id);
    }

    // Pass 1: Explicit Links
    for (final item in items) {
      for (final tx in monthTxs) {
        if (allocatedTxIds.contains(tx.id)) continue;
        if (tx.isIncome) continue;
        if (tx.linkedChecklistItemId == item.id) {
          allocate(tx, item);
        }
      }
    }

    // Pass 2: Exact Category + Subcategory Match
    for (final item in items) {
      if (item.categoryId == null || item.subcategory == null || item.subcategory!.isEmpty) continue;
      for (final tx in monthTxs) {
        if (allocatedTxIds.contains(tx.id)) continue;
        if (tx.isIncome) continue;
        if (tx.categoryId == item.categoryId && tx.subCategory == item.subcategory) {
          if (tx.bucketType != null && tx.bucketType != this.bucketType) continue;
          allocate(tx, item);
        }
      }
    }

    // Pass 3: Fuzzy Title match (User forgot to select subcategory but typed a similar name in title)
    for (final item in items) {
      if (item.categoryId == null || (item.subcategory != null && item.subcategory!.isNotEmpty)) continue;
      for (final tx in monthTxs) {
        if (allocatedTxIds.contains(tx.id)) continue;
        if (tx.isIncome) continue;
        if (tx.categoryId == item.categoryId && tx.subCategory != null && tx.subCategory!.isNotEmpty) {
          final txSub = tx.subCategory!.toLowerCase();
          final itemTitle = item.title.toLowerCase();
          if (txSub == itemTitle || txSub.contains(itemTitle) || itemTitle.contains(txSub)) {
            if (tx.bucketType != null && tx.bucketType != this.bucketType) continue;
            allocate(tx, item);
          }
        }
      }
    }

    // Pass 4: Generic Category match (Budget item has no subcategory, transaction ALSO has no subcategory)
    for (final item in items) {
      if (item.categoryId == null || (item.subcategory != null && item.subcategory!.isNotEmpty)) continue;
      for (final tx in monthTxs) {
        if (allocatedTxIds.contains(tx.id)) continue;
        if (tx.isIncome) continue;
        if (tx.categoryId == item.categoryId && (tx.subCategory == null || tx.subCategory!.isEmpty)) {
          if (tx.bucketType != null && tx.bucketType != this.bucketType) continue;
          allocate(tx, item);
        }
      }
    }

    // Notice: Pass 5 (Catch-all Fallback) has been intentionally removed.
    // If a transaction has a subcategory (e.g. Dialog TV) and the user didn't create a budget item for it,
    // it should NOT be randomly swallowed by another unrelated generic item (like "Gas").

    // Apply completion fallback and finalize
    for (final item in items) {
      if (item.categoryId == null || (spents[item.id]! == 0.0 && item.isCompleted)) {
        spents[item.id] = item.isCompleted ? item.allocatedAmount : 0.0;
      }
    }
    
    return spents;
  }

  double calculateItemSpent(BudgetChecklistItem item, List<TransactionEntity> transactions) {
    return calculateAllItemSpents(transactions)[item.id] ?? 0.0;
  }

  double calculateDynamicTotalSpent(List<TransactionEntity> transactions) {
    final spents = calculateAllItemSpents(transactions);
    return spents.values.fold(0.0, (sum, spent) => sum + spent);
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
