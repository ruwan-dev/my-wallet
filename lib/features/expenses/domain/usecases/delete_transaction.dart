import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/transaction.dart';
import '../entities/account.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/account_repository.dart';

class DeleteTransactionUseCase implements UseCase<void, TransactionEntity> {
  final TransactionRepository transactionRepository;
  final AccountRepository accountRepository;

  DeleteTransactionUseCase(this.transactionRepository, this.accountRepository);

  @override
  Future<Either<Failure, void>> call(TransactionEntity params) async {
    // 1. Revert account balance (if not planned)
    if (params.accountId == 'planned') {
      return transactionRepository.deleteTransaction(params.userId, params.id);
    }

    final accountResult = await accountRepository.getAccount(params.userId, params.accountId);
    
    return accountResult.fold(
      (failure) async {
        // Account not found or error, just delete the orphaned transaction
        return transactionRepository.deleteTransaction(params.userId, params.id);
      },
      (account) async {
        double amountDelta;
        if (account.type == AccountType.liability) {
          amountDelta = params.isIncome ? params.amount : -params.amount;
        } else {
          amountDelta = params.isIncome ? -params.amount : params.amount;
        }
        final updatedAccount = account.copyWith(balance: account.balance + amountDelta);
        
        final updateResult = await accountRepository.updateAccount(updatedAccount);
        return updateResult.fold(
          (failure) => Left(failure),
          (_) async {
            // Revert transfer target if present
            if (params.transferAccountId != null && params.transferAccountId!.isNotEmpty) {
              final targetAccountResult = await accountRepository.getAccount(params.userId, params.transferAccountId!);
              final targetFailure = await targetAccountResult.fold(
                (failure) async => failure,
                (targetAccount) async {
                  double targetDelta;
                  if (targetAccount.type == AccountType.liability) {
                    targetDelta = params.amount; // Revert payment to liability
                  } else {
                    targetDelta = -params.amount; // Revert transfer to asset
                  }
                  final updatedTarget = targetAccount.copyWith(balance: targetAccount.balance + targetDelta);
                  final targetUpdateResult = await accountRepository.updateAccount(updatedTarget);
                  return targetUpdateResult.fold((f) => f, (_) => null);
                }
              );
              if (targetFailure != null) {
                return Left(targetFailure);
              }
            }

            // 2. Delete transaction
            return transactionRepository.deleteTransaction(params.userId, params.id);
          }
        );
      }
    );
  }
}
