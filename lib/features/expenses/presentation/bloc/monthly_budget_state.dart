import 'package:equatable/equatable.dart';
import '../../domain/entities/monthly_budget.dart';

abstract class MonthlyBudgetState extends Equatable {
  const MonthlyBudgetState();

  @override
  List<Object?> get props => [];
}

class MonthlyBudgetInitial extends MonthlyBudgetState {}

class MonthlyBudgetLoading extends MonthlyBudgetState {}

class MonthlyBudgetLoaded extends MonthlyBudgetState {
  final MonthlyBudgetEntity? budget;
  final int month;
  final int year;

  const MonthlyBudgetLoaded({
    required this.budget,
    required this.month,
    required this.year,
  });

  @override
  List<Object?> get props => [budget, month, year];
}

class MonthlyBudgetError extends MonthlyBudgetState {
  final String message;

  const MonthlyBudgetError(this.message);

  @override
  List<Object?> get props => [message];
}
