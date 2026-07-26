import 'package:equatable/equatable.dart';
import '../../domain/entities/category_budget.dart';

class BudgetProgressSummary extends Equatable {
  final CategoryBudgetEntity budget;
  final double totalSpent;
  
  const BudgetProgressSummary({
    required this.budget,
    required this.totalSpent,
  });

  double get remainingAmount => budget.limitAmount - totalSpent;
  double get progressPercentage => (totalSpent / budget.limitAmount).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [budget, totalSpent];
}

abstract class BudgetState extends Equatable {
  const BudgetState();

  @override
  List<Object?> get props => [];
}

class BudgetInitial extends BudgetState {}

class BudgetLoading extends BudgetState {}

class BudgetLoaded extends BudgetState {
  final List<BudgetProgressSummary> summaries;
  final String monthYear;

  const BudgetLoaded({
    required this.summaries,
    required this.monthYear,
  });

  @override
  List<Object?> get props => [summaries, monthYear];
}

class BudgetError extends BudgetState {
  final String message;

  const BudgetError(this.message);

  @override
  List<Object?> get props => [message];
}
