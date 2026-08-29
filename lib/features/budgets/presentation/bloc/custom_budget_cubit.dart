import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/custom_budget.dart';
import '../../domain/repositories/custom_budget_repository.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'custom_budget_state.dart';
import '../../../expenses/domain/usecases/get_transactions.dart';
import '../../../expenses/domain/usecases/add_transaction.dart';
import '../../../expenses/domain/entities/transaction.dart';
import '../../../expenses/domain/entities/category.dart';

class CustomBudgetCubit extends Cubit<CustomBudgetState> {
  final CustomBudgetRepository repository;
  final AuthCubit authCubit;
  final GetTransactionsUseCase getTransactions;
  final AddTransactionUseCase addTransaction;
  
  StreamSubscription? _budgetSubscription;
  StreamSubscription? _authSubscription;
  String _currentUserId = '';
  final _uuid = const Uuid();

  CustomBudgetCubit({
    required this.repository,
    required this.authCubit,
    required this.getTransactions,
    required this.addTransaction,
  }) : super(CustomBudgetInitial()) {
    _authSubscription = authCubit.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        _currentUserId = authState.user.id;
        _startWatchingBudgets();
      } else if (authState is AuthUnauthenticated) {
        _currentUserId = '';
        _budgetSubscription?.cancel();
        emit(CustomBudgetInitial());
      }
    });

    if (authCubit.state is AuthAuthenticated) {
      _currentUserId = (authCubit.state as AuthAuthenticated).user.id;
      _startWatchingBudgets();
    }
  }

  void _startWatchingBudgets() {
    _budgetSubscription?.cancel();
    emit(CustomBudgetLoading());
    
    _budgetSubscription = repository.watchCustomBudgets(_currentUserId).listen((result) {
      result.fold(
        (failure) => emit(CustomBudgetError(failure.message)),
        (budgets) {
          _handleRecurringBudgets(budgets);
          emit(CustomBudgetLoaded(budgets));
        },
      );
    }, onError: (error) {
      emit(CustomBudgetError(error.toString()));
    });
  }

  Future<void> _handleRecurringBudgets(List<CustomBudgetEntity> budgets) async {
    final now = DateTime.now();
    for (final budget in budgets) {
      if (budget.isRecurring && !budget.isCompleted) {
        if (budget.createdAt.year < now.year || (budget.createdAt.year == now.year && budget.createdAt.month < now.month)) {
          
          // 1. Calculate remaining amount and sweep to Fire bucket
          final txResult = await getTransactions(GetTransactionsParams(userId: _currentUserId, limit: 1000));
          await txResult.fold(
            (failure) async => null,
            (transactions) async {
              final spent = budget.calculateDynamicTotalSpent(transactions);
              final leftover = budget.totalBudgetLimit - spent;
              
              if (leftover > 0) {
                // Auto-Sweep leftover to Fire bucket
                final sweepTx = TransactionEntity(
                  id: '',
                  accountId: 'planned', // Bypass hard account balance checks for internal tracking
                  userId: _currentUserId,
                  title: 'Sweep from ${budget.title}',
                  amount: leftover,
                  categoryId: 'system_sweep',
                  categoryName: 'Auto Sweep',
                  date: DateTime(now.year, now.month, 1).subtract(const Duration(days: 1)), // Last day of old month
                  isIncome: true, // Acts as income toward Heal goals
                  createdAt: now,
                  updatedAt: now,
                  bucketType: BucketType.heal,
                );
                await addTransaction(sweepTx);
              }
            }
          );

          // 2. Mark old budget as completed
          final completedOldBudget = budget.copyWith(isCompleted: true);
          await saveBudget(completedOldBudget);

          // 3. Create a fresh budget for the new month
          final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
          
          final freshItems = budget.items.map((item) {
            return item.copyWith(
              id: _uuid.v4(),
              isCompleted: false,
            );
          }).toList();

          final newBudget = budget.copyWith(
            id: '',
            createdAt: firstDayOfCurrentMonth,
            isCompleted: false,
            items: freshItems,
          );
          
          await saveBudget(newBudget);
        }
      }
    }
  }

  Future<void> saveBudget(CustomBudgetEntity budget) async {
    final budgetWithUser = budget.copyWith(userId: _currentUserId);
    final result = await repository.saveCustomBudget(budgetWithUser);
    
    result.fold(
      (failure) => emit(CustomBudgetError(failure.message)),
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
