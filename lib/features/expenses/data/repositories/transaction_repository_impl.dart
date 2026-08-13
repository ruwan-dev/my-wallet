import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_datasource.dart';
import '../datasources/transaction_local_datasource.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;
  final TransactionLocalDatasource localDataSource;
  final AuthRepository authRepository;

  TransactionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.authRepository,
  });

  Future<bool> _isPremium() async {
    final user = await authRepository.getCurrentUser();
    return user?.isPremium ?? false;
  }

  @override
  Stream<Either<Failure, List<TransactionEntity>>> watchTransactions({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    bool? isIncome,
    String? accountId,
  }) async* {
    final isPremium = await _isPremium();
    final stream = isPremium 
        ? remoteDataSource.watchAllTransactions(userId) 
        : localDataSource.watchAllTransactions(userId);

    yield* stream.map((models) {
      try {
        var filtered = models.where((model) {
          bool matches = true;
          if (startDate != null && model.date.isBefore(startDate)) matches = false;
          if (endDate != null && model.date.isAfter(endDate)) matches = false;
          if (categoryId != null && model.categoryId != categoryId) matches = false;
          if (isIncome != null && model.isIncome != isIncome) matches = false;
          if (accountId != null && model.accountId != accountId) matches = false;
          return matches;
        }).toList();

        final entities = filtered.map((m) => m.toEntity()).toList();
        return Right<Failure, List<TransactionEntity>>(entities);
      } catch (e) {
        return Left<Failure, List<TransactionEntity>>(CacheFailure(message: e.toString()));
      }
    });
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    required String userId,
    int limit = 20,
    DateTime? lastDate,
    String? accountId,
  }) async {
    try {
      final isPremium = await _isPremium();
      var models = isPremium 
          ? await remoteDataSource.getAllTransactions(userId)
          : await localDataSource.getAllTransactions(userId);
      
      var filtered = models;
      if (lastDate != null) {
        filtered = filtered.where((m) => m.date.isBefore(lastDate)).toList();
      }
      if (accountId != null) {
        filtered = filtered.where((m) => m.accountId == accountId).toList();
      }
      
      filtered = filtered.take(limit).toList();
      final entities = filtered.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> addTransaction(TransactionEntity transaction) async {
    try {
      final isPremium = await _isPremium();
      final model = TransactionModel.fromEntity(transaction);
      if (isPremium) {
        await remoteDataSource.saveTransaction(transaction.userId, model);
      } else {
        await localDataSource.saveTransaction(model);
      }
      return Right(transaction);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> updateTransaction(TransactionEntity transaction) async {
    try {
      final isPremium = await _isPremium();
      final model = TransactionModel.fromEntity(transaction);
      if (isPremium) {
        await remoteDataSource.updateTransaction(transaction.userId, model);
      } else {
        await localDataSource.updateTransaction(model);
      }
      return Right(transaction);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String userId, String id) async {
    try {
      final isPremium = await _isPremium();
      if (isPremium) {
        await remoteDataSource.deleteTransaction(userId, id);
      } else {
        await localDataSource.deleteTransaction(id);
      }
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getMonthlyTotal({
    required String userId,
    required int month,
    required int year,
    required bool isIncome,
    String? accountId,
  }) async {
    try {
      final isPremium = await _isPremium();
      var models = isPremium 
          ? await remoteDataSource.getAllTransactions(userId)
          : await localDataSource.getAllTransactions(userId);
          
      final sum = models
          .where((m) => 
              m.date.month == month && 
              m.date.year == year && 
              m.isIncome == isIncome &&
              (accountId == null || m.accountId == accountId))
          .fold(0.0, (double prev, curr) => prev + curr.amount);
      return Right(sum);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
