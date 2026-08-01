import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/account.dart';
import '../repositories/account_repository.dart';

class UpdateAccountUseCase {
  final AccountRepository repository;

  UpdateAccountUseCase(this.repository);

  Future<Either<Failure, AccountEntity>> call(AccountEntity account) async {
    return await repository.updateAccount(account);
  }
}
