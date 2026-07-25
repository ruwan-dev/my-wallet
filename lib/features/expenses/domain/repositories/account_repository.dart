import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/account.dart';

abstract class AccountRepository {
  Stream<Either<Failure, List<AccountEntity>>> watchAccounts(String userId);
  Future<Either<Failure, List<AccountEntity>>> getAccounts(String userId);
  Future<Either<Failure, AccountEntity>> getAccount(String userId, String id);
  Future<Either<Failure, AccountEntity>> addAccount(AccountEntity account);
  Future<Either<Failure, AccountEntity>> updateAccount(AccountEntity account);
  Future<Either<Failure, void>> deleteAccount(String userId, String id);
}
