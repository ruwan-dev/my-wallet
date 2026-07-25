import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/transaction.dart';

/// Contract that the data layer must satisfy.
abstract class TransactionRepository {
  /// Stream transactions, optionally filtered by date, category, income/expense, and account.
  Stream<Either<Failure, List<TransactionEntity>>> watchTransactions({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    bool? isIncome,
    String? accountId,
  });

  /// Fetch a paginated list of transactions.
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    required String userId,
    int limit = 20,
    DateTime? lastDate,
    String? accountId,
  });

  /// Add a new transaction to the store.
  Future<Either<Failure, TransactionEntity>> addTransaction(TransactionEntity transaction);

  /// Update an existing transaction.
  Future<Either<Failure, TransactionEntity>> updateTransaction(TransactionEntity transaction);

  /// Delete a transaction by [userId] and [id].
  Future<Either<Failure, void>> deleteTransaction(String userId, String id);

  /// Get the total for a given [month] and [year].
  Future<Either<Failure, double>> getMonthlyTotal({
    required String userId,
    required int month,
    required int year,
    required bool isIncome,
    String? accountId,
  });
}
