import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/category_budget.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/budget_repository.dart';
import 'budget_state.dart';
import 'transaction_cubit.dart';
import 'transaction_state.dart';
import 'package:intl/intl.dart';

class BudgetCubit extends Cubit<BudgetState> {
  final BudgetRepository _budgetRepository;
  final TransactionCubit _transactionCubit;
  final AuthRepository _authRepository;

  StreamSubscription? _budgetSubscription;
  StreamSubscription? _transactionSubscription;

  List<CategoryBudgetEntity> _currentBudgets = [];
  List<TransactionEntity> _currentTransactions = [];
  String _currentMonthYear = '';

  BudgetCubit({
    required BudgetRepository budgetRepository,
    required TransactionCubit transactionCubit,
    required AuthRepository authRepository,
  })  : _budgetRepository = budgetRepository,
        _transactionCubit = transactionCubit,
        _authRepository = authRepository,
        super(BudgetInitial()) {
    
    // Listen to transaction updates
    _transactionSubscription = _transactionCubit.stream.listen((txState) {
      if (txState is TransactionLoaded) {
        _currentTransactions = txState.transactions;
        _calculateSummaries();
      }
    });

    // Grab initial transactions if already loaded
    if (_transactionCubit.state is TransactionLoaded) {
      _currentTransactions = (_transactionCubit.state as TransactionLoaded).transactions;
    }
  }

  String get _currentUserId {
    final uid = _authRepository.getCurrentUserId();
    if (uid == null || uid.isEmpty) {
      throw Exception('Unauthenticated: Cannot access budgets.');
    }
    return uid;
  }

  void loadBudgetsForMonth(DateTime date) {
    emit(BudgetLoading());
    _currentMonthYear = DateFormat('yyyy-MM').format(date);
    
    _budgetSubscription?.cancel();
    _budgetSubscription = _budgetRepository
        .watchBudgetsForMonth(_currentUserId, _currentMonthYear)
        .listen(
      (failureOrBudgets) {
        failureOrBudgets.fold(
          (failure) => emit(BudgetError(failure.message)),
          (budgets) {
            _currentBudgets = budgets;
            _calculateSummaries();
          },
        );
      },
    );
  }

  void _calculateSummaries() {
    if (_currentMonthYear.isEmpty) return;
    
    final summaries = _currentBudgets.map((budget) {
      // Find all expenses in this category for the current month
      final spent = _currentTransactions
          .where((tx) => !tx.isIncome && 
                         tx.categoryId == budget.categoryId && 
                         DateFormat('yyyy-MM').format(tx.date) == budget.monthYear)
          .fold(0.0, (sum, tx) => sum + tx.amount);
          
      return BudgetProgressSummary(budget: budget, totalSpent: spent);
    }).toList();

    emit(BudgetLoaded(summaries: summaries, monthYear: _currentMonthYear));
  }

  Future<void> saveBudget(CategoryBudgetEntity budget) async {
    final result = await _budgetRepository.saveBudget(_currentUserId, budget);
    result.fold(
      (failure) => emit(BudgetError(failure.message)),
      (_) {}, // Stream will auto-update the state
    );
  }

  Future<void> deleteBudget(String budgetId) async {
    final result = await _budgetRepository.deleteBudget(_currentUserId, budgetId);
    result.fold(
      (failure) => emit(BudgetError(failure.message)),
      (_) {}, // Stream will auto-update the state
    );
  }

  @override
  Future<void> close() {
    _budgetSubscription?.cancel();
    _transactionSubscription?.cancel();
    return super.close();
  }
}
