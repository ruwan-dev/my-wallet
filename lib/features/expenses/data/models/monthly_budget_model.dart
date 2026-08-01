import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/monthly_budget.dart';

class MonthlyBudgetModel extends MonthlyBudgetEntity {
  const MonthlyBudgetModel({
    required super.id,
    required super.userId,
    required super.month,
    required super.year,
    required super.totalBudgetLimit,
    required super.categoryLimits,
  });

  factory MonthlyBudgetModel.fromEntity(MonthlyBudgetEntity entity) {
    return MonthlyBudgetModel(
      id: entity.id,
      userId: entity.userId,
      month: entity.month,
      year: entity.year,
      totalBudgetLimit: entity.totalBudgetLimit,
      categoryLimits: entity.categoryLimits,
    );
  }

  factory MonthlyBudgetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Convert dynamic map to Map<String, double>
    final rawLimits = data['categoryLimits'] as Map<String, dynamic>? ?? {};
    final categoryLimits = rawLimits.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    return MonthlyBudgetModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      month: data['month'] ?? 1,
      year: data['year'] ?? 2026,
      totalBudgetLimit: (data['totalBudgetLimit'] as num?)?.toDouble() ?? 0.0,
      categoryLimits: categoryLimits,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'month': month,
      'year': year,
      'totalBudgetLimit': totalBudgetLimit,
      'categoryLimits': categoryLimits,
    };
  }
}
