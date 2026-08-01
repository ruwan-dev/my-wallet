import 'package:equatable/equatable.dart';

class MonthlyBudgetEntity extends Equatable {
  final String id;
  final String userId;
  final int month;
  final int year;
  final double totalBudgetLimit;
  final Map<String, double> categoryLimits;

  const MonthlyBudgetEntity({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.totalBudgetLimit,
    required this.categoryLimits,
  });

  MonthlyBudgetEntity copyWith({
    String? id,
    String? userId,
    int? month,
    int? year,
    double? totalBudgetLimit,
    Map<String, double>? categoryLimits,
  }) {
    return MonthlyBudgetEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      month: month ?? this.month,
      year: year ?? this.year,
      totalBudgetLimit: totalBudgetLimit ?? this.totalBudgetLimit,
      categoryLimits: categoryLimits ?? this.categoryLimits,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        month,
        year,
        totalBudgetLimit,
        categoryLimits,
      ];
}
