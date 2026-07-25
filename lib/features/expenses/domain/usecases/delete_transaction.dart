import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/account_repository.dart';

class DeleteTransactionUseCase implements UseCase<void, TransactionEntity> {
  final TransactionRepository transactionRepository;
  final AccountRepository accountRepository;

  DeleteTransactionUseCase(this.transactionRepository, this.accountRepository);

  @override
  Future<Either<Failure, void>> call(TransactionEntity params) async {
    // 1. Revert account balance
    final accountResult = await accountRepository.getAccount(params.userId, params.accountId);
    
    return accountResult.fold(
      (failure) => Left(failure), // Handle missing account appropriately in real app
      (account) async {
        final double amountDelta = params.isIncome ? -params.amount : params.amount;
        final updatedAccount = account.copyWith(balance: account.balance + amountDelta);
        
        final updateResult = await accountRepository.updateAccount(updatedAccount);
        return updateResult.fold(
          (failure) => Left(failure),
          (_) async {
            // 2. Delete transaction
            return transactionRepository.deleteTransaction(params.userId, params.id);
          }
        );
      }
    );
  }
}
