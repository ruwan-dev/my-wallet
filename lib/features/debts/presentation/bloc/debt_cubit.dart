import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/debt.dart';
import '../../domain/repositories/debt_repository.dart';
import '../../../expenses/domain/entities/transaction.dart';
import '../../../expenses/domain/entities/category.dart';
import '../../../expenses/domain/repositories/transaction_repository.dart';
import 'debt_state.dart';

class DebtCubit extends Cubit<DebtState> {
  final DebtRepository _debtRepository;
  final TransactionRepository _transactionRepository;
  StreamSubscription? _debtsSubscription;
  String _currentUserId = '';

  DebtCubit({
    required DebtRepository debtRepository,
    required TransactionRepository transactionRepository,
  })  : _debtRepository = debtRepository,
        _transactionRepository = transactionRepository,
        super(DebtInitial());

  void loadDebts(String userId) {
    _currentUserId = userId;
    emit(DebtLoading());
    _debtsSubscription?.cancel();

    _debtsSubscription = _debtRepository.watchDebts(userId).listen(
      (debts) {
        // Debt Snowball Strategy: Sort by current balance ascending
        final sortedDebts = List<Debt>.from(debts)
          ..sort((a, b) => a.currentBalance.compareTo(b.currentBalance));
        emit(DebtLoaded(sortedDebts));
      },
      onError: (e) {
        emit(DebtError(e.toString()));
      },
    );
  }

  Future<void> addDebt({
    required String name,
    required double totalAmount,
    required double currentBalance,
    DateTime? dueDate,
  }) async {
    if (_currentUserId.isEmpty) return;

    final newDebt = Debt(
      id: const Uuid().v4(),
      userId: _currentUserId,
      name: name,
      totalAmount: totalAmount,
      currentBalance: currentBalance,
      createdAt: DateTime.now(),
      dueDate: dueDate,
    );

    await _debtRepository.addDebt(newDebt);
  }

  Future<void> editDebt({
    required String debtId,
    required String name,
    required double totalAmount,
    required double currentBalance,
    DateTime? dueDate,
  }) async {
    if (state is! DebtLoaded || _currentUserId.isEmpty) return;
    final debts = (state as DebtLoaded).debts;
    
    final debtIndex = debts.indexWhere((d) => d.id == debtId);
    if (debtIndex == -1) return;
    
    final debt = debts[debtIndex];
    final updatedDebt = Debt(
      id: debt.id,
      userId: debt.userId,
      name: name,
      totalAmount: totalAmount,
      currentBalance: currentBalance,
      createdAt: debt.createdAt,
      dueDate: dueDate ?? debt.dueDate,
    );

    try {
      await _debtRepository.updateDebt(updatedDebt);
    } catch (e) {
      emit(DebtError(e.toString()));
      loadDebts(_currentUserId);
    }
  }

  Future<void> payOffDebt(String debtId, double paymentAmount, String defaultAccountId) async {
    if (state is! DebtLoaded || _currentUserId.isEmpty) return;
    final debts = (state as DebtLoaded).debts;
    
    final debtIndex = debts.indexWhere((d) => d.id == debtId);
    if (debtIndex == -1) return;
    
    final debt = debts[debtIndex];
    final newBalance = (debt.currentBalance - paymentAmount).clamp(0.0, double.infinity);
    
    final updatedDebt = Debt(
      id: debt.id,
      userId: debt.userId,
      name: debt.name,
      totalAmount: debt.totalAmount,
      currentBalance: newBalance,
      createdAt: debt.createdAt,
    );

    try {
      // 1. Update the Debt entity
      await _debtRepository.updateDebt(updatedDebt);

      // 2. Create an expense transaction categorized as Fire bucket
      // This will automatically deduct from the Heal Bucket balance visually
      final paymentTransaction = TransactionEntity(
        id: const Uuid().v4(),
        userId: _currentUserId,
        title: 'Debt Repayment: ${debt.name}',
        amount: paymentAmount,
        categoryId: 'debt_repayment', // We will assume there's a category or we use a fallback
        categoryName: 'Debt Repayment',
        date: DateTime.now(),
        isIncome: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        accountId: defaultAccountId, // The account to deduct the money from
        bucketType: BucketType.heal, // This is crucial for the Heal tab math
      );

      await _transactionRepository.addTransaction(paymentTransaction);
      
    } catch (e) {
      // Handle error gracefully if either fails.
      // In a robust system, we would queue this.
      emit(DebtError(e.toString()));
      loadDebts(_currentUserId); // Reload to reset state
    }
  }

  Future<void> deleteDebt(String debtId) async {
    if (_currentUserId.isEmpty) return;
    try {
      await _debtRepository.deleteDebt(debtId);
    } catch (e) {
      emit(DebtError(e.toString()));
      loadDebts(_currentUserId);
    }
  }

  @override
  Future<void> close() {
    _debtsSubscription?.cancel();
    return super.close();
  }
}
