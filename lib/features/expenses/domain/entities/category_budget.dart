import 'package:equatable/equatable.dart';

class CategoryBudgetEntity extends Equatable {
  final String id;
  final String userId;
  final String categoryId;
  final String categoryName;
  final double limitAmount;
  final String monthYear; // Format: 'YYYY-MM'

  const CategoryBudgetEntity({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.limitAmount,
    required this.monthYear,
  });

  CategoryBudgetEntity copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? categoryName,
    double? limitAmount,
    String? monthYear,
  }) {
    return CategoryBudgetEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      limitAmount: limitAmount ?? this.limitAmount,
      monthYear: monthYear ?? this.monthYear,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        categoryName,
        limitAmount,
        monthYear,
      ];
}
