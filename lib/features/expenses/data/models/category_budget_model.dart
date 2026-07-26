import '../../domain/entities/category_budget.dart';

class CategoryBudgetModel {
  final String id;
  final String userId;
  final String categoryId;
  final String categoryName;
  final double limitAmount;
  final String monthYear;

  CategoryBudgetModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.limitAmount,
    required this.monthYear,
  });

  factory CategoryBudgetModel.fromEntity(CategoryBudgetEntity entity) {
    return CategoryBudgetModel(
      id: entity.id,
      userId: entity.userId,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      limitAmount: entity.limitAmount,
      monthYear: entity.monthYear,
    );
  }

  CategoryBudgetEntity toEntity() {
    return CategoryBudgetEntity(
      id: id,
      userId: userId,
      categoryId: categoryId,
      categoryName: categoryName,
      limitAmount: limitAmount,
      monthYear: monthYear,
    );
  }

  factory CategoryBudgetModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return CategoryBudgetModel(
      id: documentId,
      userId: data['userId'] ?? '',
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      limitAmount: (data['limitAmount'] as num?)?.toDouble() ?? 0.0,
      monthYear: data['monthYear'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'limitAmount': limitAmount,
      'monthYear': monthYear,
    };
  }
}
