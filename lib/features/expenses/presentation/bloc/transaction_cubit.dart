import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/update_transaction.dart';
import '../../domain/usecases/watch_transactions.dart';
import 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  final WatchTransactionsUseCase _watchTransactions;
  final AddTransactionUseCase    _addTransaction;
  final UpdateTransactionUseCase _updateTransaction;
  final DeleteTransactionUseCase _deleteTransaction;
  final AuthRepository           _authRepository;

  StreamSubscription? _subscription;

  String get _currentUserId {
    final uid = _authRepository.getCurrentUserId();
    if (uid == null || uid.isEmpty) {
      throw Exception('Unauthenticated: Cannot access transactions.');
    }
    return uid;
  }

  TransactionCubit({
    required WatchTransactionsUseCase watchTransactions,
    required AddTransactionUseCase    addTransaction,
    required UpdateTransactionUseCase updateTransaction,
    required DeleteTransactionUseCase deleteTransaction,
    required AuthRepository           authRepository,
  })  : _watchTransactions = watchTransactions,
        _addTransaction    = addTransaction,
        _updateTransaction = updateTransaction,
        _deleteTransaction = deleteTransaction,
        _authRepository    = authRepository,
        super(TransactionInitial());

  void loadTransactions() {
    emit(TransactionLoading());
    
    _subscription?.cancel();
    _subscription = _watchTransactions(
      WatchTransactionsParams(userId: _currentUserId),
    ).listen(
      (failureOrTransactions) {
        failureOrTransactions.fold(
          (failure) => emit(TransactionError(failure.message)),
          (transactions) => emit(TransactionLoaded(transactions: transactions)),
        );
      },
      onError: (error) {
        emit(TransactionError('Stream error: $error'));
      },
    );
  }

  Future<void> addTransaction(TransactionEntity transaction) async {
    final transactionWithUser = transaction.copyWith(userId: _currentUserId);
    await _addTransaction(transactionWithUser);
  }

  Future<void> updateTransaction(TransactionEntity oldTx, TransactionEntity newTx) async {
    final newTxWithUser = newTx.copyWith(userId: _currentUserId);
    await _updateTransaction(UpdateTransactionParams(oldTransaction: oldTx, newTransaction: newTxWithUser));
  }

  Future<void> deleteTransaction(TransactionEntity transaction) async {
    if (state is TransactionLoaded) {
      final loadedState = state as TransactionLoaded;
      final updatedList = loadedState.transactions.where((t) => t.id != transaction.id).toList();
      emit(loadedState.copyWith(transactions: updatedList, deletedTransaction: transaction));
      
      final result = await _deleteTransaction(transaction);
      result.fold(
        (failure) {
          emit((state as TransactionLoaded).copyWith(clearDeleted: true));
        },
        (_) {},
      );
    }
  }



  double get currentMonthFixedExpenses {
    if (state is! TransactionLoaded) return 0.0;
    
    final transactions = (state as TransactionLoaded).transactions;
    final now = DateTime.now();
    double total = 0.0;
    
    for (final tx in transactions) {
      if (!tx.isIncome && 
          tx.isFixedExpense && 
          tx.date.year == now.year && 
          tx.date.month == now.month) {
        total += tx.amount;
      }
    }
    
    return total;
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
