import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class WatchTransactionsUseCase {
  final TransactionRepository repository;

  WatchTransactionsUseCase(this.repository);

  Stream<Either<Failure, List<TransactionEntity>>> call(WatchTransactionsParams params) {
    return repository.watchTransactions(
      userId: params.userId,
      startDate: params.startDate,
      endDate: params.endDate,
      categoryId: params.categoryId,
      isIncome: params.isIncome,
      accountId: params.accountId,
    );
  }
}

class WatchTransactionsParams extends Equatable {
  final String userId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryId;
  final bool? isIncome;
  final String? accountId;

  const WatchTransactionsParams({
    required this.userId,
    this.startDate,
    this.endDate,
    this.categoryId,
    this.isIncome,
    this.accountId,
  });

  @override
  List<Object?> get props => [userId, startDate, endDate, categoryId, isIncome, accountId];
}
