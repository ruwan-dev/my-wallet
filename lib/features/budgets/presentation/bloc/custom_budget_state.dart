import 'package:equatable/equatable.dart';
import '../../domain/entities/custom_budget.dart';

abstract class CustomBudgetState extends Equatable {
  const CustomBudgetState();

  @override
  List<Object?> get props => [];
}

class CustomBudgetInitial extends CustomBudgetState {}

class CustomBudgetLoading extends CustomBudgetState {}

class CustomBudgetLoaded extends CustomBudgetState {
  final List<CustomBudgetEntity> budgets;

  const CustomBudgetLoaded(this.budgets);

  @override
  List<Object?> get props => [budgets];
}

class CustomBudgetError extends CustomBudgetState {
  final String message;

  const CustomBudgetError(this.message);

  @override
  List<Object?> get props => [message];
}
