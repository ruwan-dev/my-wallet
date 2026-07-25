import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_datasource.dart';
import '../models/account_model.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remoteDataSource;

  AccountRepositoryImpl(this.remoteDataSource);

  @override
  Stream<Either<Failure, List<AccountEntity>>> watchAccounts(String userId) {
    return remoteDataSource.watchAllAccounts(userId).map((models) {
      try {
        final entities = models.map((m) => m.toEntity()).toList();
        return Right<Failure, List<AccountEntity>>(entities);
      } catch (e) {
        return Left<Failure, List<AccountEntity>>(CacheFailure(message: e.toString()));
      }
    });
  }

  @override
  Future<Either<Failure, List<AccountEntity>>> getAccounts(String userId) async {
    try {
      final models = await remoteDataSource.getAllAccounts(userId);
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AccountEntity>> getAccount(String userId, String id) async {
    try {
      final model = await remoteDataSource.getAccount(userId, id);
      return Right(model.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AccountEntity>> addAccount(AccountEntity account) async {
    try {
      final model = AccountModel.fromEntity(account);
      await remoteDataSource.saveAccount(account.userId, model);
      return Right(account);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AccountEntity>> updateAccount(AccountEntity account) async {
    try {
      final model = AccountModel.fromEntity(account);
      await remoteDataSource.updateAccount(account.userId, model);
      return Right(account);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount(String userId, String id) async {
    try {
      await remoteDataSource.deleteAccount(userId, id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
