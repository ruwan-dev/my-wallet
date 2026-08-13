import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_datasource.dart';
import '../datasources/account_local_datasource.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../models/account_model.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remoteDataSource;
  final AccountLocalDatasource localDataSource;
  final AuthRepository authRepository;

  AccountRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.authRepository,
  });

  Future<bool> _isPremium() async {
    final user = await authRepository.getCurrentUser();
    return user?.isPremium ?? false;
  }

  @override
  Stream<Either<Failure, List<AccountEntity>>> watchAccounts(String userId) async* {
    final isPremium = await _isPremium();
    final stream = isPremium 
        ? remoteDataSource.watchAllAccounts(userId) 
        : localDataSource.watchAllAccounts(userId);

    yield* stream.map((models) {
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
      final isPremium = await _isPremium();
      final models = isPremium 
          ? await remoteDataSource.getAllAccounts(userId)
          : await localDataSource.getAllAccounts(userId);
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
      final isPremium = await _isPremium();
      final model = isPremium 
          ? await remoteDataSource.getAccount(userId, id)
          : await localDataSource.getAccount(id);
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
      final isPremium = await _isPremium();
      final model = AccountModel.fromEntity(account);
      if (isPremium) {
        await remoteDataSource.saveAccount(account.userId, model);
      } else {
        await localDataSource.saveAccount(model);
      }
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
      final isPremium = await _isPremium();
      final model = AccountModel.fromEntity(account);
      if (isPremium) {
        await remoteDataSource.updateAccount(account.userId, model);
      } else {
        await localDataSource.updateAccount(model);
      }
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
      final isPremium = await _isPremium();
      if (isPremium) {
        await remoteDataSource.deleteAccount(userId, id);
      } else {
        await localDataSource.deleteAccount(id);
      }
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
