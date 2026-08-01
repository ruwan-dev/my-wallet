import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/monthly_budget.dart';
import '../../domain/repositories/monthly_budget_repository.dart';
import 'monthly_budget_state.dart';

class MonthlyBudgetCubit extends Cubit<MonthlyBudgetState> {
  final MonthlyBudgetRepository repository;
  String _currentUserId = '';

  MonthlyBudgetCubit({required this.repository}) : super(MonthlyBudgetInitial());

  void init(String userId) {
    _currentUserId = userId;
    final now = DateTime.now();
    loadBudget(now.month, now.year);
  }

  Future<void> loadBudget(int month, int year) async {
    if (_currentUserId.isEmpty) return;
    
    emit(MonthlyBudgetLoading());
    final result = await repository.getMonthlyBudget(_currentUserId, month, year);
    
    result.fold(
      (failure) => emit(MonthlyBudgetError(failure.message)),
      (budget) => emit(MonthlyBudgetLoaded(budget: budget, month: month, year: year)),
    );
  }

  Future<void> saveBudget(MonthlyBudgetEntity budget) async {
    final result = await repository.saveMonthlyBudget(budget);
    
    result.fold(
      (failure) => emit(MonthlyBudgetError(failure.message)),
      (savedBudget) => emit(MonthlyBudgetLoaded(
        budget: savedBudget,
        month: savedBudget.month,
        year: savedBudget.year,
      )),
    );
  }
}
