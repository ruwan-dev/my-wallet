import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/account_repository.dart';

class AddTransactionUseCase implements UseCase<TransactionEntity, TransactionEntity> {
  final TransactionRepository transactionRepository;
  final AccountRepository accountRepository;
  final _uuid = const Uuid();

  AddTransactionUseCase(this.transactionRepository, this.accountRepository);

  @override
  Future<Either<Failure, TransactionEntity>> call(TransactionEntity params) async {
    if (params.title.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Title cannot be empty'));
    }
    if (params.amount <= 0) {
      return const Left(ValidationFailure(message: 'Amount must be greater than zero'));
    }
    if (params.accountId.isEmpty) {
      return const Left(ValidationFailure(message: 'Account ID must be provided'));
    }

    final now = DateTime.now();
    final transaction = params.copyWith(
      id: _uuid.v4(),
      createdAt: now,
      updatedAt: now,
    );

    // 1. Fetch account
    final accountResult = await accountRepository.getAccount(transaction.userId, transaction.accountId);
    return accountResult.fold(
      (failure) => Left(failure),
      (account) async {
        // 2. Update account balance
        final double amountDelta = transaction.isIncome ? transaction.amount : -transaction.amount;
        final updatedAccount = account.copyWith(balance: account.balance + amountDelta);
        
        final updateResult = await accountRepository.updateAccount(updatedAccount);
        return updateResult.fold(
          (failure) => Left(failure),
          (_) async {
            // 3. Save transaction
            return transactionRepository.addTransaction(transaction);
          },
        );
      }
    );
  }
}
