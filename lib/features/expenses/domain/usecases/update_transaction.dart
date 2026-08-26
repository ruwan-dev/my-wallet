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

    // 1. Revert old transaction from old account
    if (oldTx.accountId != 'planned') {
      final oldAccountResult = await accountRepository.getAccount(oldTx.userId, oldTx.accountId);
      if (oldAccountResult.isRight()) {
        final oldAccount = oldAccountResult.getOrElse(() => throw Exception());
        double oldRevertDelta;
        if (oldAccount.type == AccountType.liability) {
          oldRevertDelta = oldTx.isIncome ? oldTx.amount : -oldTx.amount;
        } else {
          oldRevertDelta = oldTx.isIncome ? -oldTx.amount : oldTx.amount;
        }
        await accountRepository.updateAccount(oldAccount.copyWith(balance: oldAccount.balance + oldRevertDelta));
      }

      // Revert transfer target if old transaction had one
      if (oldTx.transferAccountId != null && oldTx.transferAccountId!.isNotEmpty) {
        final oldTargetResult = await accountRepository.getAccount(oldTx.userId, oldTx.transferAccountId!);
        if (oldTargetResult.isRight()) {
          final oldTarget = oldTargetResult.getOrElse(() => throw Exception());
          double oldTargetDelta = oldTarget.type == AccountType.liability ? oldTx.amount : -oldTx.amount;
          await accountRepository.updateAccount(oldTarget.copyWith(balance: oldTarget.balance + oldTargetDelta));
        }
      }
    }

    // 2. Apply new transaction to new account
    if (newTx.accountId != 'planned') {
      final newAccountResult = await accountRepository.getAccount(newTx.userId, newTx.accountId);
      if (newAccountResult.isRight()) {
        final newAccount = newAccountResult.getOrElse(() => throw Exception());
        double newApplyDelta;
        if (newAccount.type == AccountType.liability) {
          newApplyDelta = newTx.isIncome ? -newTx.amount : newTx.amount;
        } else {
          newApplyDelta = newTx.isIncome ? newTx.amount : -newTx.amount;
        }
        await accountRepository.updateAccount(newAccount.copyWith(balance: newAccount.balance + newApplyDelta));
      }

      // Apply transfer target if new transaction has one
      if (newTx.transferAccountId != null && newTx.transferAccountId!.isNotEmpty) {
        final newTargetResult = await accountRepository.getAccount(newTx.userId, newTx.transferAccountId!);
        if (newTargetResult.isRight()) {
          final newTarget = newTargetResult.getOrElse(() => throw Exception());
          double newTargetDelta = newTarget.type == AccountType.liability ? -newTx.amount : newTx.amount;
          await accountRepository.updateAccount(newTarget.copyWith(balance: newTarget.balance + newTargetDelta));
        }
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
