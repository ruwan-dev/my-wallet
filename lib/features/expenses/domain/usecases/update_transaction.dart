import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/account_repository.dart';

class UpdateTransactionUseCase implements UseCase<TransactionEntity, UpdateTransactionParams> {
  final TransactionRepository transactionRepository;
  final AccountRepository accountRepository;

  UpdateTransactionUseCase(this.transactionRepository, this.accountRepository);

  @override
  Future<Either<Failure, TransactionEntity>> call(UpdateTransactionParams params) async {
    final oldTx = params.oldTransaction;
    final newTx = params.newTransaction;

    if (newTx.title.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Title cannot be empty'));
    }
    if (newTx.amount <= 0) {
      return const Left(ValidationFailure(message: 'Amount must be greater than zero'));
    }

    final transactionToSave = newTx.copyWith(updatedAt: DateTime.now());

    // Strategy: Revert old transaction effect, then apply new transaction effect.
    // This is safer especially if the accountId changed.

    // 1. Revert old transaction from old account (if not planned)
    if (oldTx.accountId != 'planned') {
      final oldAccountResult = await accountRepository.getAccount(oldTx.userId, oldTx.accountId);
      if (oldAccountResult.isRight()) {
        final oldAccount = oldAccountResult.getOrElse(() => throw Exception());
        final double oldRevertDelta = oldTx.isIncome ? -oldTx.amount : oldTx.amount;
        await accountRepository.updateAccount(oldAccount.copyWith(balance: oldAccount.balance + oldRevertDelta));
      }
    }

    // 2. Apply new transaction to new account (if not planned)
    if (newTx.accountId != 'planned') {
      final newAccountResult = await accountRepository.getAccount(newTx.userId, newTx.accountId);
      if (newAccountResult.isRight()) {
        final newAccount = newAccountResult.getOrElse(() => throw Exception());
        final double newApplyDelta = newTx.isIncome ? newTx.amount : -newTx.amount;
        await accountRepository.updateAccount(newAccount.copyWith(balance: newAccount.balance + newApplyDelta));
      }
    }

    // 3. Save updated transaction
    return transactionRepository.updateTransaction(transactionToSave);
  }
}

class UpdateTransactionParams {
  final TransactionEntity oldTransaction;
  final TransactionEntity newTransaction;

  UpdateTransactionParams({required this.oldTransaction, required this.newTransaction});
}
