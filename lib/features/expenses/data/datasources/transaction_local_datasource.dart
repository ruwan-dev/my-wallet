import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/transaction_model.dart';

abstract class TransactionLocalDatasource {
  Future<List<TransactionModel>> getAllTransactions(String userId);
  Stream<List<TransactionModel>> watchAllTransactions(String userId);
  Future<void> saveTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
}

class HiveTransactionLocalDatasource implements TransactionLocalDatasource {
  final Box<TransactionModel> box;

  HiveTransactionLocalDatasource(this.box);

  @override
  Future<List<TransactionModel>> getAllTransactions(String userId) async {
    try {
      final transactions = box.values.where((e) => e.userId == userId).toList();
      transactions.sort((a, b) => b.date.compareTo(a.date)); // descending by date
      return transactions;
    } catch (e) {
      throw CacheException(message: 'Failed to fetch transactions: $e');
    }
  }

  @override
  Stream<List<TransactionModel>> watchAllTransactions(String userId) async* {
    // Emit current transactions immediately, then stream future changes.
    final initial = box.values.where((e) => e.userId == userId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    yield initial;
    yield* box.watch().map((_) {
      final list = box.values.where((e) => e.userId == userId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  @override
  Future<void> saveTransaction(TransactionModel transaction) async {
    try {
      await box.put(transaction.id, transaction);
    } catch (e) {
      throw CacheException(message: 'Failed to save transaction: $e');
    }
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      if (!box.containsKey(transaction.id)) {
        throw CacheException(message: 'Transaction not found for update');
      }
      await box.put(transaction.id, transaction);
    } catch (e) {
      throw CacheException(message: 'Failed to update transaction: $e');
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await box.delete(id);
    } catch (e) {
      throw CacheException(message: 'Failed to delete transaction: $e');
    }
  }
}
