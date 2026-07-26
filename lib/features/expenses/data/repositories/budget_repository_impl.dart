import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/category_budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_remote_datasource.dart';
import '../models/category_budget_model.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetRemoteDataSource remoteDataSource;

  BudgetRepositoryImpl(this.remoteDataSource);

  @override
  Stream<Either<Failure, List<CategoryBudgetEntity>>> watchBudgetsForMonth(String userId, String monthYear) {
    return remoteDataSource.watchBudgetsForMonth(userId, monthYear).map((models) {
      try {
        final entities = models.map((m) => m.toEntity()).toList();
        return Right<Failure, List<CategoryBudgetEntity>>(entities);
      } catch (e) {
        return Left<Failure, List<CategoryBudgetEntity>>(CacheFailure(message: e.toString()));
      }
    });
  }

  @override
  Future<Either<Failure, void>> saveBudget(String userId, CategoryBudgetEntity budget) async {
    try {
      final model = CategoryBudgetModel.fromEntity(budget);
      await remoteDataSource.saveBudget(userId, model);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBudget(String userId, String budgetId) async {
    try {
      await remoteDataSource.deleteBudget(userId, budgetId);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
