import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class GetTransactionsUseCase implements UseCase<List<TransactionEntity>, GetTransactionsParams> {
  final TransactionRepository repository;

  GetTransactionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TransactionEntity>>> call(GetTransactionsParams params) async {
    return repository.getTransactions(
      userId: params.userId,
      limit: params.limit,
      lastDate: params.lastDate,
      accountId: params.accountId,
    );
  }
}

class GetTransactionsParams extends Equatable {
  final String userId;
  final int limit;
  final DateTime? lastDate;
  final String? accountId;

  const GetTransactionsParams({
    required this.userId,
    this.limit = 20,
    this.lastDate,
    this.accountId,
  });

  @override
  List<Object?> get props => [userId, limit, lastDate, accountId];
}
