import 'package:equatable/equatable.dart';
import '../../../../features/expenses/domain/entities/category.dart';

class BudgetChecklistItem extends Equatable {
  final String id;
  final String title;
  final double allocatedAmount;
  final bool isCompleted;
  final String? categoryId;
  final String? categoryIcon;
  final String? subcategory;

  const BudgetChecklistItem({
    required this.id,
    required this.title,
    required this.allocatedAmount,
    this.isCompleted = false,
    this.categoryId,
    this.categoryIcon,
    this.subcategory,
  });

  BudgetChecklistItem copyWith({
    String? id,
    String? title,
    double? allocatedAmount,
    bool? isCompleted,
    String? categoryId,
    String? categoryIcon,
    String? subcategory,
  }) {
    return BudgetChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      isCompleted: isCompleted ?? this.isCompleted,
      categoryId: categoryId ?? this.categoryId,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      subcategory: subcategory ?? this.subcategory,
    );
  }

  @override
  List<Object?> get props => [id, title, allocatedAmount, isCompleted, categoryId, categoryIcon, subcategory];
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

  const CustomBudgetEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.totalBudgetLimit,
    required this.items,
    required this.createdAt,
    this.isCompleted = false,
    this.bucketType = BucketType.dailyExpenses,
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
    );
  }

  double get totalAllocated {
    return items.fold(0.0, (sum, item) => sum + item.allocatedAmount);
  }

  double get totalSpent {
    return items.where((i) => i.isCompleted).fold(0.0, (sum, item) => sum + item.allocatedAmount);
  }

  @override
  List<Object?> get props => [id, userId, title, totalBudgetLimit, items, createdAt, isCompleted, bucketType];
}
