import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/account.dart';
import '../repositories/account_repository.dart';

class WatchAccountsUseCase {
  final AccountRepository repository;

  WatchAccountsUseCase(this.repository);

  Stream<Either<Failure, List<AccountEntity>>> call(String userId) {
    return repository.watchAccounts(userId);
  }
}
