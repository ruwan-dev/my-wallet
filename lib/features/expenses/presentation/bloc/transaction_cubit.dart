import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/update_transaction.dart';
import '../../domain/usecases/watch_transactions.dart';
import 'transaction_state.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/category.dart';

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

  Future<void> addTransaction(
    TransactionEntity transaction, {
    Map<String, String>? bucketLinks,
    String? healRedirection, // string value of the enum name
  }) async {
    final transactionWithUser = transaction.copyWith(userId: _currentUserId);
    await _addTransaction(transactionWithUser);

    if (bucketLinks != null && transaction.isIncome) {
      final Map<BucketType, double> bucketPercentages = {
        BucketType.dailyExpenses: 0.60,
        BucketType.enjoy: 0.10,
        BucketType.smile: 0.10,
      };
      
      // Handle Heal Redirection
      if (healRedirection == 'mojo') {
        bucketPercentages[BucketType.mojo] = 0.20;
      } else if (healRedirection == 'grow') {
        bucketPercentages[BucketType.grow] = 0.20;
      } else {
        bucketPercentages[BucketType.heal] = 0.20;
      }

      for (final entry in bucketPercentages.entries) {
        final bucketType = entry.key;
        final pct = entry.value;
        
        String linkKey;
        if (bucketType == BucketType.dailyExpenses) linkKey = 'blow';
        else if (bucketType == BucketType.heal) linkKey = 'fire';
        else linkKey = bucketType.name;

        if (bucketLinks.containsKey(linkKey)) {
          final targetAccountId = bucketLinks[linkKey]!;
          if (targetAccountId != transaction.accountId) {
            final transferAmount = transaction.amount * pct;
            
            final transferTx = TransactionEntity(
              id: const Uuid().v4(),
              userId: _currentUserId,
              title: 'Auto-Allocation: ${linkKey.toUpperCase()}',
              amount: transferAmount,
              categoryId: transaction.categoryId,
              categoryName: 'Transfer',
              date: transaction.date,
              isIncome: false, 
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              accountId: transaction.accountId,
              transferAccountId: targetAccountId,
              bucketType: bucketType,
              note: 'Auto-allocated from Income',
              isFixedExpense: false,
            );
            
            await _addTransaction(transferTx);
          }
        }
      }
    }
  }

  Future<void> updateTransaction(TransactionEntity oldTx, TransactionEntity newTx) async {
    final newTxWithUser = newTx.copyWith(userId: _currentUserId);
    await _updateTransaction(UpdateTransactionParams(oldTransaction: oldTx, newTransaction: newTxWithUser));
  }

  Future<void> deleteTransaction(TransactionEntity transaction) async {
    if (state is TransactionLoaded) {
      final loadedState = state as TransactionLoaded;
      
      // Find related auto-allocated transfers (if this was an income that triggered them)
      final relatedTransfers = loadedState.transactions.where((t) => 
          transaction.isIncome && 
          !t.isIncome && 
          t.note == 'Auto-allocated from Income' &&
          t.accountId == transaction.accountId &&
          t.date.year == transaction.date.year &&
          t.date.month == transaction.date.month &&
          t.date.day == transaction.date.day &&
          t.categoryId == transaction.categoryId
      ).toList();

      final allToDelete = [transaction, ...relatedTransfers];
      final toDeleteIds = allToDelete.map((e) => e.id).toSet();

      final updatedList = loadedState.transactions.where((t) => !toDeleteIds.contains(t.id)).toList();
      emit(loadedState.copyWith(transactions: updatedList, deletedTransaction: transaction));
      
      bool hasError = false;
      for (final tx in allToDelete) {
        final result = await _deleteTransaction(tx);
        if (result.isLeft()) hasError = true;
      }

      if (hasError) {
        // Simple recovery: just reload from DB if something failed
        // Since we already deleted some, restoring state perfectly is tricky.
        emit(TransactionError('Failed to fully delete all related transactions. Please refresh.'));
      }
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
