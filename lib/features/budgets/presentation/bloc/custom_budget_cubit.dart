import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/custom_budget.dart';
import '../../domain/repositories/custom_budget_repository.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'custom_budget_state.dart';

class CustomBudgetCubit extends Cubit<CustomBudgetState> {
  final CustomBudgetRepository repository;
  final AuthCubit authCubit;
  
  StreamSubscription? _budgetSubscription;
  StreamSubscription? _authSubscription;
  String _currentUserId = '';

  CustomBudgetCubit({
    required this.repository,
    required this.authCubit,
  }) : super(CustomBudgetInitial()) {
    _authSubscription = authCubit.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        _currentUserId = authState.userId;
        _startWatchingBudgets();
      } else if (authState is AuthUnauthenticated) {
        _currentUserId = '';
        _budgetSubscription?.cancel();
        emit(CustomBudgetInitial());
      }
    });

    // Check initial auth state
    if (authCubit.state is AuthAuthenticated) {
      _currentUserId = (authCubit.state as AuthAuthenticated).userId;
      _startWatchingBudgets();
    }
  }

  void _startWatchingBudgets() {
    _budgetSubscription?.cancel();
    emit(CustomBudgetLoading());
    
    _budgetSubscription = repository.watchCustomBudgets(_currentUserId).listen((result) {
      result.fold(
        (failure) => emit(CustomBudgetError(failure.message)),
        (budgets) => emit(CustomBudgetLoaded(budgets)),
      );
    }, onError: (error) {
      emit(CustomBudgetError(error.toString()));
    });
  }

  Future<void> saveBudget(CustomBudgetEntity budget) async {
    final budgetWithUser = budget.copyWith(userId: _currentUserId);
    final result = await repository.saveCustomBudget(budgetWithUser);
    
    result.fold(
      (failure) => emit(CustomBudgetError(failure.message)), // Will be replaced by stream update on success
      (_) {},
    );
  }

  Future<void> deleteBudget(String budgetId) async {
    final result = await repository.deleteCustomBudget(_currentUserId, budgetId);
    result.fold(
      (failure) => emit(CustomBudgetError(failure.message)),
      (_) {},
    );
  }

  Future<void> markBudgetAsCompleted(String budgetId) async {
    if (state is! CustomBudgetLoaded) return;
    
    final budgets = (state as CustomBudgetLoaded).budgets;
    final budgetIndex = budgets.indexWhere((b) => b.id == budgetId);
    if (budgetIndex == -1) return;
    
    final budget = budgets[budgetIndex];
    final updatedBudget = budget.copyWith(isCompleted: true);
    await saveBudget(updatedBudget);
  }

  Future<void> toggleChecklistItem(String budgetId, String itemId, bool isCompleted) async {
    if (state is! CustomBudgetLoaded) return;
    
    final budgets = (state as CustomBudgetLoaded).budgets;
    final budgetIndex = budgets.indexWhere((b) => b.id == budgetId);
    if (budgetIndex == -1) return;
    
    final budget = budgets[budgetIndex];
    final updatedItems = budget.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isCompleted: isCompleted);
      }
      return item;
    }).toList();
    
    final updatedBudget = budget.copyWith(items: updatedItems);
    await saveBudget(updatedBudget);
  }

  @override
  Future<void> close() {
    _budgetSubscription?.cancel();
    _authSubscription?.cancel();
    return super.close();
  }
}
